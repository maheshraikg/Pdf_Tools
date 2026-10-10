import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';

/// The rate table in use, and a way to type in a new quarter's rates.
class RatesScreen extends StatelessWidget {
  const RatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s,
        rates = context.rates,
        local = context.scope.localRates;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.ratesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(
              rates.local
                  ? s.yourRates(dmy(rates.validFrom))
                  : s.builtInRates(dmy(rates.validFrom)),
              icon: rates.local
                  ? Icons.edit_calendar_rounded
                  : Icons.event_available_rounded,
              background: Brand.yellow,
              foreground: Brand.ink,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final sc in Scheme.values)
                  ListTile(
                    dense: true,
                    leading: IconBadge(sc.icon, sc.color, size: 32),
                    title: Text(s.schemeName(sc)),
                    subtitle: Text(sc.code),
                    trailing: Text(
                      '${pct(rates.current(sc).rate)}%',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: sc.textColor(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (local != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _EditRates()),
              ),
              icon: const Icon(Icons.edit_rounded),
              label: Text(s.enterNewRates),
            ),
            if (rates.local)
              TextButton.icon(
                onPressed: local.clear,
                icon: const Icon(Icons.restore_rounded),
                label: Text(s.removeMyRates),
              ),
            Note(s.newRatesNote),
          ],
        ],
      ),
    );
  }
}

class _EditRates extends StatefulWidget {
  const _EditRates();

  @override
  State<_EditRates> createState() => _EditRatesState();
}

class _EditRatesState extends State<_EditRates> {
  final _form = GlobalKey<FormState>();
  late final Map<Scheme, TextEditingController> _rates;
  late DateTime _from;
  late List<DateTime> _quarters;

  @override
  void initState() {
    super.initState();
    final rates = context.scope.localRates!.bundled;
    // The next four quarter starts after the built-in table.
    final v = rates.validFrom;
    _quarters = [
      for (var q = 1; q <= 4; q++) DateTime(v.year, v.month + 3 * q, 1),
    ];
    final current = context.rates;
    _from = current.local && _quarters.contains(current.validFrom)
        ? current.validFrom
        : _quarters.first;
    _rates = {
      for (final sc in Scheme.values)
        if (sc != Scheme.mssc)
          sc: TextEditingController(text: pct(current.current(sc).rate)),
    };
  }

  @override
  void dispose() {
    for (final c in _rates.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    await context.scope.localRates!.save(_from, {
      for (final e in _rates.entries) e.key: Decimal.parse(e.value.text),
    });
    messenger.showSnackBar(SnackBar(content: Text(s.ratesSaved)));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.enterNewRates)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DropdownButtonFormField<DateTime>(
              initialValue: _from,
              decoration: InputDecoration(labelText: s.validFromLabel),
              items: [
                for (final q in _quarters)
                  DropdownMenuItem(value: q, child: Text(dmy(q))),
              ],
              onChanged: (v) => setState(() => _from = v ?? _from),
            ),
            const SizedBox(height: 12),
            for (final e in _rates.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextFormField(
                  controller: e.value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: '${s.schemeName(e.key)} (${e.key.code})',
                    suffixText: '%',
                    prefixIcon: Icon(e.key.icon, color: e.key.color),
                  ),
                  validator: (v) {
                    final r = Decimal.tryParse(v ?? '');
                    return r == null ||
                            r <= Decimal.zero ||
                            r > Decimal.fromInt(20)
                        ? s.badRate
                        : null;
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(s.saveRates),
            ),
            Note(s.newRatesNote),
          ],
        ),
      ),
    );
  }
}
