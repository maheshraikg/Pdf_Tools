import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../panchanga/engine.dart';
import '../panchanga/muhurta.dart';
import '../panchanga/names.dart';
import 'day_detail_screen.dart';

/// Shortlists daytime windows for an activity.
class MuhurtaScreen extends StatefulWidget {
  const MuhurtaScreen({super.key});

  @override
  State<MuhurtaScreen> createState() => _MuhurtaScreenState();
}

class _MuhurtaScreenState extends State<MuhurtaScreen> {
  MuhurtaPreset _preset = muhurtaPresets.first;
  DateTime? _from;
  int _days = 30;
  Future<List<MuhurtaWindow>>? _result;

  @override
  Widget build(BuildContext context) {
    final s = context.s, lang = context.lang, settings = context.settings;
    final repo = context.repo;
    final from = _from ?? todayAt(repo.engine);
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: LipiText(s.muhurta)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          DropdownButtonFormField<MuhurtaPreset>(
            initialValue: _preset,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.activity),
            items: [
              for (final p in muhurtaPresets)
                DropdownMenuItem(value: p, child: LipiText(p.name.of(lang))),
            ],
            onChanged: (p) => setState(() {
              _preset = p!;
              _result = null;
            }),
          ),
          if (_preset.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_preset.note, style: t.textTheme.bodySmall),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text('${s.startDate}: ${longDate(lang, from)}'),
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: DateTime(from.year, from.month, from.day),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2099),
                    );
                    if (p != null) {
                      setState(() {
                        _from = PanchangaEngine.dateOnly(p);
                        _result = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _days,
                items: [
                  for (final n in [15, 30, 60, 90])
                    DropdownMenuItem(value: n, child: Text('$n ${s.days}')),
                ],
                onChanged: (n) => setState(() {
                  _days = n!;
                  _result = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: settings.janmaNakshatra,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.janmaNakshatra),
                  items: [
                    DropdownMenuItem(value: null, child: Text(s.notSet)),
                    for (var i = 0; i < 27; i++)
                      DropdownMenuItem(
                        value: i,
                        child: LipiText(nakshatraNames[i].of(lang)),
                      ),
                  ],
                  onChanged: (v) {
                    settings.update((x) => x.janmaNakshatra = v);
                    setState(() => _result = null);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: settings.janmaRashi,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.janmaRashi),
                  items: [
                    DropdownMenuItem(value: null, child: Text(s.notSet)),
                    for (var i = 0; i < 12; i++)
                      DropdownMenuItem(
                        value: i,
                        child: LipiText(rashiNames[i].of(lang)),
                      ),
                  ],
                  onChanged: (v) {
                    settings.update((x) => x.janmaRashi = v);
                    setState(() => _result = null);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.search),
            label: LipiText(s.find),
            onPressed: () => setState(() {
              _result = repo.muhurtas(
                _preset,
                from,
                _days,
                Janma(
                  nakshatra: settings.janmaNakshatra,
                  rashi: settings.janmaRashi,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Card(
            color: t.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LipiText(
                s.muhurtaDisclaimer,
                style: t.textTheme.bodySmall,
              ),
            ),
          ),
          if (_result != null)
            FutureBuilder<List<MuhurtaWindow>>(
              future: _result,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final ws = snap.data!;
                if (ws.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: LipiText(s.noMuhurta)),
                  );
                }
                final e = repo.engine;
                return Column(
                  children: [
                    for (final w in ws)
                      Card(
                        child: ListTile(
                          title: Text(
                            '${longDate(lang, w.date)} · ${hm(e, w.start)}–${hm(e, w.end)}',
                          ),
                          subtitle: LipiText(
                            '${varaNames[w.date.weekday % 7].of(lang)} · '
                            '${tithiLabel(lang, w.tithi)} · '
                            '${nakshatraNames[w.nakshatra].of(lang)} · '
                            '${yogaNames[w.yoga].of(lang)}'
                            '${w.reasons.isEmpty ? '' : '\n${w.reasons.join(', ')}'}',
                          ),
                          trailing: CircleAvatar(
                            radius: 18,
                            backgroundColor: w.score >= 80
                                ? Colors.green.shade100
                                : Colors.amber.shade100,
                            child: Text(
                              '${w.score}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DayDetailScreen(date: w.date),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
