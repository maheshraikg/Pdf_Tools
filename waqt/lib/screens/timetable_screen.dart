import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/scope.dart';
import '../core/prayer_calc.dart';
import '../core/timetable.dart';

const _example = '''# name: My Mosque, Kozhikode
# utc_offset: +05:30
# source: Printed yearly chart
date,fajr,sunrise,dhuhr,asr,maghrib,isha
01-01,05:28,06:51,12:36,15:51,18:17,19:32
01-02,05:28,06:51,12:37,15:52,18:18,19:33
…''';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  Future<void> _import(BuildContext context, String text, String name) async {
    final settings = context.settings, s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final t = Timetable.parse(text, fallbackName: name);
      await settings.update((x) {
        x.timetableCsv = t.toCsv();
        x.timetableEnabled = true;
      });
      messenger.showSnackBar(SnackBar(content: Text(s.imported)));
    } on TimetableFormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.importError('$e'))));
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    // FileType.any: some file managers do not map .csv to a MIME type and
    // would grey the file out.
    final f = await FilePicker.pickFile(type: FileType.any);
    if (f == null) return;
    final List<int> bytes;
    try {
      bytes = await f.readAsBytes();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.importError('$e'))));
      return;
    }
    if (!context.mounted) return;
    await _import(
      context,
      utf8.decode(bytes, allowMalformed: true),
      f.name.replaceAll(RegExp(r'\.(csv|txt)$'), ''),
    );
  }

  Future<void> _paste(BuildContext context) async {
    final s = context.s;
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _PasteDialog(s.pasteCsv, s.cancel, s.save),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await _import(context, text, s.timetable);
  }

  /// The calculated year as CSV, a starting point for a mosque's own table.
  Future<void> _copyCalculated(BuildContext context) async {
    final settings = context.settings, s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    final year = settings.today.year;
    final offset = settings.displayOffsetMinutes;
    final b = StringBuffer()
      ..writeln('# name: ${settings.place.name} (${settings.method.id})')
      ..writeln('# utc_offset: ${formatUtcOffset(offset)}')
      ..writeln('date,${timetableColumns.join(',')}');
    const cols = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];
    final days = settings.calculator.days(
      DateTime.utc(year),
      DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays,
    );
    for (final d in days) {
      final row = cols.map((p) {
        final w = d[p].add(Duration(minutes: offset));
        return formatClock24(w.hour * 60 + w.minute);
      });
      b.writeln(
        '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')},${row.join(',')}',
      );
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    messenger.showSnackBar(SnackBar(content: Text(s.copied)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final csv = settings.timetableCsv;
    Timetable? t;
    if (csv != null) {
      try {
        t = Timetable.parse(csv);
      } on TimetableFormatException {
        t = null;
      }
    }
    final mono = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: 'monospace');

    return Scaffold(
      appBar: AppBar(title: Text(s.timetable)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.timetableHelp),
          const SizedBox(height: 16),
          if (t == null)
            Text(s.noTimetable)
          else
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(t.name),
                    subtitle: Text(
                      [
                        s.timetableInfo(
                          t.daysOfYear,
                          formatUtcOffset(t.utcOffsetMinutes),
                        ),
                        if (t.source.isNotEmpty) t.source,
                      ].join('\n'),
                    ),
                    value: settings.timetableEnabled,
                    onChanged: (v) =>
                        settings.update((x) => x.timetableEnabled = v),
                  ),
                  TextButton.icon(
                    onPressed: () => settings.update((x) {
                      x.timetableCsv = null;
                      x.timetableEnabled = false;
                    }),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(s.removeTimetable),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _pickFile(context),
            icon: const Icon(Icons.file_open_outlined),
            label: Text(s.importCsv),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _paste(context),
            icon: const Icon(Icons.content_paste),
            label: Text(s.pasteCsv),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _copyCalculated(context),
            icon: const Icon(Icons.copy),
            label: Text(s.exportCalculated),
          ),
          const SizedBox(height: 24),
          Text(s.csvFormat, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(_example, style: mono),
          ),
        ],
      ),
    );
  }
}

/// Owns its controller so it lives until the closing animation is done.
class _PasteDialog extends StatefulWidget {
  const _PasteDialog(this.title, this.cancel, this.save);
  final String title, cancel, save;

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _ctl,
      maxLines: 12,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      decoration: const InputDecoration(
        hintText: _example,
        border: OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _ctl.text),
        child: Text(widget.save),
      ),
    ],
  );
}
