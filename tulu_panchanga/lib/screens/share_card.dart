import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../app/scope.dart';
import '../app/summary.dart';
import '../panchanga/engine.dart';
import '../panchanga/names.dart';

/// Plain-text panchanga summary for sharing.
String dayText(BuildContext context, DayPanchanga d) =>
    '${daySummary(context.s, context.lang, context.repo.engine, d)}\n'
    '— ${context.s.appTitle}, ${context.settings.place.name.of(context.lang)}';

/// Shows the share card in a dialog and shares it as an image (with text).
Future<void> showShareCard(BuildContext context, DayPanchanga day) {
  final key = GlobalKey();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      contentPadding: const EdgeInsets.all(12),
      content: SingleChildScrollView(
        child: RepaintBoundary(
          key: key,
          child: ShareCard(day: day),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.s.cancel),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.share),
          label: Text(context.s.share),
          onPressed: () async {
            final text = dayText(context, day);
            final boundary =
                key.currentContext?.findRenderObject()
                    as RenderRepaintBoundary?;
            XFile? file;
            if (boundary != null) {
              final image = await boundary.toImage(pixelRatio: 3);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              if (bytes != null) {
                file = XFile.fromData(
                  bytes.buffer.asUint8List(),
                  mimeType: 'image/png',
                  name:
                      'panchanga_${day.date.toIso8601String().substring(0, 10)}.png',
                );
              }
            }
            await SharePlus.instance.share(
              ShareParams(
                text: text,
                files: file == null ? null : [file],
                fileNameOverrides: file == null ? null : [file.name],
              ),
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ],
    ),
  );
}

/// A compact, branded card for sharing a day's panchanga.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.day});
  final DayPanchanga day;

  @override
  Widget build(BuildContext context) {
    final s = context.s, lang = context.lang, e = context.repo.engine;
    final d = day;
    const red = Color(0xFFB3261E), gold = Color(0xFFF2C94C);
    final t = Theme.of(context).textTheme;
    Widget row(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: LipiText(
              a,
              style: t.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          Expanded(
            child: LipiText(
              b,
              style: t.bodyMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    String end(Span x) =>
        x.end >= d.nextSunrise ? '' : ' · ${hmDay(context, e, x.end, d.date)}';
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              color: red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                LipiText(
                  varaNames[d.weekday].of(lang),
                  style: t.titleMedium?.copyWith(color: gold),
                ),
                Text(
                  longDate(lang, d.date),
                  style: t.titleLarge?.copyWith(color: Colors.white),
                ),
                LipiText(
                  tuluDate(lang, d),
                  style: t.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                row(s.samvatsara, samvatsaraNames[d.samvatsara].of(lang)),
                row(
                  s.lunarMonth,
                  '${lunarMonthLabel(lang, d.lunarMonth)}, ${pakshaNames[d.paksha].of(lang)}',
                ),
                row(
                  s.tithi,
                  '${tithiLabel(lang, d.tithi)}${end(d.tithis.first)}',
                ),
                row(
                  s.nakshatra,
                  '${nakshatraNames[d.nakshatra].of(lang)}${end(d.nakshatras.first)}',
                ),
                row(s.yoga, yogaNames[d.yoga].of(lang)),
                row(
                  s.karana,
                  karanaNames[karanaIndex(d.karanas.first.index)].of(lang),
                ),
                row(
                  '${s.sunrise} / ${s.sunset}',
                  '${hm(e, d.sunrise)} / ${hm(e, d.sunset)}',
                ),
                row(
                  s.rahu,
                  '${hm(e, d.kaalas.rahu.start)} – ${hm(e, d.kaalas.rahu.end)}',
                ),
                const SizedBox(height: 6),
                LipiText(
                  '${s.appTitle} · ${context.settings.place.name.of(lang)}',
                  style: t.bodySmall?.copyWith(color: red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
