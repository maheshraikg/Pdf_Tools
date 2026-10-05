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
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../../widgets/share_card.dart';
import '../result/result_screen.dart';

/// Counter / agent tools: eligibility, document checklist, quick calc.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  Scheme _scheme = Scheme.td5;
  Holding _holding = Holding.single;
  final _amount = TextEditingController(text: '100000');
  final _age = TextEditingController();
  List<Issue>? _issues;

  @override
  void dispose() {
    _amount.dispose();
    _age.dispose();
    super.dispose();
  }

  Decimal? get _amt => Decimal.tryParse(_amount.text);

  void _check() {
    final a = _amt;
    if (a == null) return;
    setState(
      () => _issues = checkEligibility(
        EligibilityInput(
          scheme: _scheme,
          amount: a,
          age: int.tryParse(_age.text),
          holding: _holding,
          opening: DateUtils.dateOnly(DateTime.now()),
        ),
      ),
    );
  }

  CalcResult? _quick(BuildContext context) {
    final a = _amt;
    if (a == null || a < _scheme.min || _scheme == Scheme.mssc) return null;
    return calculate(
      CalcInput(
        scheme: _scheme,
        amount: a,
        opening: DateUtils.dateOnly(DateTime.now()),
        rate: context.rates.current(_scheme).rate,
        rateFrom: context.rates.current(_scheme).from,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, t = Theme.of(context).textTheme;
    final quick = _quick(context);
    final c = _scheme.color;
    final max = _scheme.maxAmount == null
        ? null
        : rupee(maxFor(_scheme, _holding));
    final docs = documentsFor(_scheme, h: _holding);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.staff,
                          style: t.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const LanguageToggle(onDark: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Scheme>(
                        value: _scheme,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: t.titleMedium?.copyWith(color: Brand.ink),
                        items: [
                          for (final sc in Scheme.values)
                            DropdownMenuItem(
                              value: sc,
                              child: Row(
                                children: [
                                  Icon(sc.icon, color: sc.color, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${sc.code} – ${s.schemeName(sc)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _scheme = v ?? _scheme;
                          _issues = null;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Appear(
                  child: SectionCard(
                    icon: Icons.fact_check_rounded,
                    title: s.eligibility,
                    color: c,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _amount,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: s.amountLabel(_scheme.amountKind),
                                ),
                                onChanged: (_) =>
                                    setState(() => _issues = null),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _age,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: _scheme == Scheme.ssy
                                      ? s.girlAge
                                      : s.age,
                                ),
                                onChanged: (_) =>
                                    setState(() => _issues = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<Holding>(
                          segments: [
                            for (final h in Holding.values)
                              ButtonSegment(
                                value: h,
                                label: Text(s.holding(h)),
                              ),
                          ],
                          selected: {_holding},
                          onSelectionChanged: (v) => setState(() {
                            _holding = v.first;
                            _issues = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: c,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _check,
                          icon: const Icon(Icons.fact_check_rounded),
                          label: Text(s.check),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _issues == null
                              ? const SizedBox(width: double.infinity)
                              : Column(
                                  key: ValueKey(_issues),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    if (_issues!.isEmpty)
                                      StatusBanner(s.eligible, ok: true)
                                    else
                                      for (final i in _issues!)
                                        StatusBanner(
                                          s.issue(i, _scheme, max: max),
                                          ok: false,
                                        ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Appear(
                  delay: Appear.step(1, ms: 80),
                  child: SectionCard(
                    icon: Icons.folder_copy_rounded,
                    title: s.documents,
                    color: c,
                    child: _DocChecklist(
                      key: ValueKey('${_scheme.code}-${_holding.name}'),
                      items: [for (final d in docs) s.doc(d)],
                      color: c,
                      note: s.documentsNote,
                    ),
                  ),
                ),
                Appear(
                  delay: Appear.step(2, ms: 80),
                  child: SectionCard(
                    icon: Icons.bolt_rounded,
                    title: s.quickCalc,
                    color: c,
                    child: quick == null
                        ? Text(s.enterAmount, style: t.bodyMedium)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (quick.scheme.payout != null &&
                                  quick.periodicPayout != null)
                                ValueTile(
                                  s.payout(quick.scheme.payout!),
                                  rupee(quick.periodicPayout!),
                                ),
                              ValueTile(
                                s.totalInterest,
                                rupee(quick.totalInterest),
                              ),
                              ValueTile(
                                s.maturityValue,
                                rupee(quick.maturityValue),
                                emphasis: true,
                              ),
                              ValueTile(
                                s.maturityDate,
                                dmy(quick.maturityDate),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  ResultScreen(result: quick),
                                            ),
                                          ),
                                      child: Text(
                                        s.details,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton.filled(
                                    tooltip: s.share,
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(52, 52),
                                      backgroundColor: Brand.yellow,
                                      foregroundColor: Brand.ink,
                                    ),
                                    onPressed: () =>
                                        showShareCard(context, quick),
                                    icon: const Icon(Icons.share_rounded),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Note(s.estimateOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tick-off list of documents for the counter (ticks are not saved).
class _DocChecklist extends StatefulWidget {
  const _DocChecklist({
    super.key,
    required this.items,
    required this.color,
    required this.note,
  });

  final List<String> items;
  final Color color;
  final String note;

  @override
  State<_DocChecklist> createState() => _DocChecklistState();
}

class _DocChecklistState extends State<_DocChecklist> {
  final _done = <int>{};

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, d) in widget.items.indexed)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: widget.color,
          value: _done.contains(i),
          title: Text(
            d,
            style: TextStyle(
              decoration: _done.contains(i) ? TextDecoration.lineThrough : null,
            ),
          ),
          onChanged: (v) =>
              setState(() => v == true ? _done.add(i) : _done.remove(i)),
        ),
      Note(widget.note),
    ],
  );
}
