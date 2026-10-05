import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/engine/eligibility.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final holding = _joint ? Holding.joint : Holding.single;
    final needsAge = scheme == Scheme.scss || scheme == Scheme.ssy;
    final tableRate = context.rates.rateFor(scheme, _opening);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.schemeName(scheme)),
        actions: const [LanguageToggle()],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.titleLarge,
              decoration: InputDecoration(
                labelText: s.amountLabel(scheme.amountKind),
                prefixText: '₹ ',
              ),
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
            const SizedBox(height: 16),
            if (scheme == Scheme.mis)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.jointAccount),
                value: _joint,
                onChanged: (v) => setState(() => _joint = v),
              ),
            if (scheme != Scheme.sb) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(s.openingDate),
                subtitle: Text(
                  dmy(_opening),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickOpening,
              ),
              const SizedBox(height: 8),
            ],
            if (needsAge) ...[
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: scheme == Scheme.ssy ? s.girlAge : s.depositorAge,
                ),
                validator: (v) {
                  final age = int.tryParse(v ?? '');
                  if (age == null) return null;
                  final issues = checkEligibility(
                    EligibilityInput(
                      scheme: scheme,
                      amount: scheme.min,
                      age: age,
                    ),
                  ).where((i) => i == Issue.scssAge || i == Issue.ssyGirlAge);
                  return issues.isEmpty ? null : s.issue(issues.first, scheme);
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: s.rate,
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
                if (r == null || r <= Decimal.zero || r > Decimal.fromInt(20)) {
                  return s.enterRate;
                }
                return null;
              },
            ),
            if (scheme == Scheme.mssc) Note(s.issue(Issue.msscClosed, scheme)),
            if (scheme == Scheme.ppf) Note(s.ppfNote),
            if (scheme == Scheme.rd) Note(s.rdNote),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.calculate),
              label: Text(s.calculate),
            ),
            const SizedBox(height: 12),
            Note(s.estimateOnly),
          ],
        ),
      ),
    );
  }
}
