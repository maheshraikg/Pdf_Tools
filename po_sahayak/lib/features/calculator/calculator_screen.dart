import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/engine/eligibility.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../schemes/scheme_details_screen.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../result/result_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.scheme, this.amount});
  final Scheme scheme;
  final Decimal? amount;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _age = TextEditingController();
  late DateTime _opening;
  bool _joint = false;
  DateTime? _rateFrom;
  bool _rateEdited = false;
  bool _started = false;

  Scheme get scheme => widget.scheme;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _opening = scheme == Scheme.mssc ? Scheme.msscLastOpening : today;
    if (widget.amount != null) _amount.text = plain(widget.amount!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _fillRate();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _age.dispose();
    super.dispose();
  }

  void _fillRate() {
    if (_rateEdited) return;
    final e = context.rates.rateFor(scheme, _opening);
    _rateFrom = e?.from;
    _rate.text = e == null ? '' : pct(e.rate);
  }

  Decimal? _parse(String v) => Decimal.tryParse(v.trim().replaceAll(',', ''));

  Future<void> _pickOpening() async {
    final d = await pickDate(
      context,
      _opening,
      last: scheme == Scheme.mssc ? Scheme.msscLastOpening : null,
      first: scheme == Scheme.mssc ? DateTime(2023, 4, 1) : null,
    );
    if (d == null) return;
    setState(() {
      _opening = d;
      _fillRate();
    });
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final input = CalcInput(
      scheme: scheme,
      amount: _parse(_amount.text)!,
      opening: _opening,
      rate: _parse(_rate.text)!,
      rateFrom: _rateEdited ? null : _rateFrom,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          result: calculate(input),
          girlAge: scheme == Scheme.ssy ? int.tryParse(_age.text) : null,
        ),
      ),
    );
  }

  /// Suggested amounts that fit the scheme's limits.
  List<int> get _quick {
    final base = switch (scheme.amountKind) {
      AmountKind.monthly => [500, 1000, 2000, 5000, 10000],
      AmountKind.yearly => [12000, 50000, 100000, 150000],
      AmountKind.balance => [10000, 50000, 100000],
      AmountKind.lumpSum => [10000, 50000, 100000, 500000, 1000000],
    };
    final max = scheme.maxAmount;
    return base
        .where((a) => a >= scheme.minAmount && (max == null || a <= max))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final holding = _joint ? Holding.joint : Holding.single;
    final needsAge = scheme == Scheme.scss || scheme == Scheme.ssy;
    final tableRate = context.rates.rateFor(scheme, _opening);
    final typed = _parse(_amount.text);
    final c = scheme.color;
    return Scaffold(
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GradientHeader(
              gradient: scheme.gradient,
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const BackButton(color: Colors.white),
                        const Spacer(),
                        IconButton(
                          tooltip: s.fullDetails,
                          onPressed: () => openSchemeDetails(context, scheme),
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const LanguageToggle(onDark: true),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'scheme-${scheme.code}',
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(scheme.icon, color: c, size: 34),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.schemeName(scheme),
                                  style: t.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (tableRate != null)
                                      Pill(
                                        s.perYear(pct(tableRate.rate)),
                                        icon: Icons.percent_rounded,
                                        background: Brand.yellow,
                                        foreground: Brand.ink,
                                      ),
                                    Pill(
                                      s.tenureOf(scheme),
                                      icon: Icons.schedule_rounded,
                                      background: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      foreground: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Appear(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: s.amountLabel(scheme.amountKind),
                        prefixIcon: Icon(
                          Icons.currency_rupee_rounded,
                          color: c,
                        ),
                        helperText: typed == null ? null : rupee(typed),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final a = _parse(v ?? '');
                        if (a == null) return s.enterAmount;
                        final issues = amountIssues(scheme, a, h: holding);
                        if (issues.isEmpty) return null;
                        final max = scheme.maxAmount == null
                            ? null
                            : rupee(maxFor(scheme, holding));
                        return issues
                            .map((i) => s.issue(i, scheme, max: max))
                            .join('\n');
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Appear(
                    delay: Appear.step(1),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in _quick)
                          ChoiceChip(
                            label: Text(rupee(Decimal.fromInt(a))),
                            selected: typed == Decimal.fromInt(a),
                            selectedColor: c.withValues(alpha: 0.18),
                            onSelected: (_) =>
                                setState(() => _amount.text = a.toString()),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (scheme == Scheme.mis)
                    Card(
                      child: SwitchListTile(
                        secondary: Icon(Icons.group_rounded, color: c),
                        title: Text(s.jointAccount),
                        value: _joint,
                        activeThumbColor: c,
                        onChanged: (v) => setState(() => _joint = v),
                      ),
                    ),
                  if (scheme != Scheme.sb)
                    Appear(
                      delay: Appear.step(2),
                      child: Card(
                        child: ListTile(
                          leading: IconBadge(Icons.event_rounded, c, size: 40),
                          title: Text(s.openingDate),
                          subtitle: Text(
                            dmy(_opening),
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: Icon(Icons.edit_calendar_rounded, color: c),
                          onTap: _pickOpening,
                        ),
                      ),
                    ),
                  if (needsAge) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: scheme == Scheme.ssy
                            ? s.girlAge
                            : s.depositorAge,
                        prefixIcon: Icon(Icons.cake_rounded, color: c),
                      ),
                      validator: (v) {
                        final age = int.tryParse(v ?? '');
                        if (age == null) return null;
                        final issues =
                            checkEligibility(
                              EligibilityInput(
                                scheme: scheme,
                                amount: scheme.min,
                                age: age,
                              ),
                            ).where(
                              (i) =>
                                  i == Issue.scssAge || i == Issue.ssyGirlAge,
                            );
                        return issues.isEmpty
                            ? null
                            : s.issue(issues.first, scheme);
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  Appear(
                    delay: Appear.step(3),
                    child: TextFormField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: s.rate,
                        prefixIcon: Icon(Icons.percent_rounded, color: c),
                        suffixText: '%',
                        helperText: tableRate == null
                            ? s.rateMissing
                            : scheme.rateFloats
                            ? s.rateFloats
                            : s.rateFromTable,
                        helperMaxLines: 3,
                      ),
                      onChanged: (_) => _rateEdited = true,
                      validator: (v) {
                        final r = _parse(v ?? '');
                        if (r == null ||
                            r <= Decimal.zero ||
                            r > Decimal.fromInt(20)) {
                          return s.enterRate;
                        }
                        return null;
                      },
                    ),
                  ),
                  if (scheme == Scheme.mssc)
                    Note(s.issue(Issue.msscClosed, scheme)),
                  if (scheme == Scheme.ppf) Note(s.ppfNote),
                  if (scheme == Scheme.rd) Note(s.rdNote),
                  const SizedBox(height: 22),
                  Appear(
                    delay: Appear.step(4),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(64, 60),
                        elevation: 3,
                        shadowColor: c.withValues(alpha: 0.5),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.calculate_rounded),
                      label: Text(s.calculate),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Note(s.estimateOnly),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
