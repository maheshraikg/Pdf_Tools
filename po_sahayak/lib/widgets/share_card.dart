import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../app/format.dart';
import '../app/scope.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../domain/models/result.dart';

/// Plain-text version of the result, sent along with the image.
String resultText(S s, CalcResult r) {
  final p = r.scheme.payout;
  return [
    '${s.schemeName(r.scheme)} (${r.scheme.code})',
    '${s.amountLabel(r.scheme.amountKind)}: ${rupee(r.input.amount)}',
    '${s.openingDate}: ${dmy(r.input.opening)}',
    s.rateUsed(pct(r.input.rate), null),
    if (p != null && r.periodicPayout != null)
      '${s.payout(p)}: ${rupee(r.periodicPayout!)}',
    '${s.totalInterest}: ${rupee(r.totalInterest)}',
    '${s.maturityValue}: ${rupee(r.maturityValue)}',
    '${s.maturityDate}: ${dmy(r.maturityDate)}',
    s.estimateOnly,
    '— ${s.appTitle}',
  ].join('\n');
}

/// Shows the share card and shares it as a PNG (with the text).
Future<void> showShareCard(BuildContext context, CalcResult result) {
  final key = GlobalKey();
  final s = context.s;
  final messenger = ScaffoldMessenger.maybeOf(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      contentPadding: const EdgeInsets.all(12),
      content: SingleChildScrollView(
        child: RepaintBoundary(
          key: key,
          child: ShareCard(result: result),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(s.cancel),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.share),
          label: Text(s.share),
          onPressed: () async {
            // Picture first (needs the card on screen), then close the
            // dialog and open the share sheet.
            final file = await _cardImage(key, result);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            final ok = await shareResult(s, result, file);
            if (!ok) {
              messenger?.showSnackBar(SnackBar(content: Text(s.shareFailed)));
            }
          },
        ),
      ],
    ),
  );
}

/// The card as a PNG file in the app's temporary folder, or null.
Future<XFile?> _cardImage(GlobalKey key, CalcResult result) async {
  try {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return null;
    final name = 'po_sahayak_${result.scheme.code.toLowerCase()}.png';
    final dir = await Directory.systemTemp.createTemp('share');
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return XFile(file.path, mimeType: 'image/png', name: name);
  } catch (e) {
    debugPrint('Share image failed: $e');
    return null;
  }
}

/// Shares the result as image + text; falls back to text alone when the
/// image cannot be shared. Returns false if nothing could be shared.
Future<bool> shareResult(S s, CalcResult result, XFile? image) async {
  final text = resultText(s, result);
  if (image != null) {
    try {
      await SharePlus.instance.share(ShareParams(text: text, files: [image]));
      return true;
    } catch (e) {
      debugPrint('Share with image failed: $e');
    }
  }
  try {
    await SharePlus.instance.share(ShareParams(text: text));
    return true;
  } catch (e) {
    debugPrint('Share failed: $e');
    return false;
  }
}

/// A clean result card in the selected language. No India Post name or logo.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.result});
  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result;
    final t = Theme.of(context).textTheme;
    final p = r.scheme.payout;
    const fg = Color(0xFF1B1B1F), muted = Color(0xFF5E5E66);
    Widget line(String a, String b, {bool big = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(a, style: t.bodyMedium?.copyWith(color: muted)),
          ),
          Text(
            b,
            style: (big ? t.titleLarge : t.titleSmall)?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return Container(
      width: 320,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(gradient: r.scheme.gradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(r.scheme.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.schemeName(r.scheme),
                        style: t.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  s.maturityValue,
                  style: t.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  rupee(r.maturityValue),
                  style: t.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(s.amountLabel(r.scheme.amountKind), rupee(r.input.amount)),
                line(s.openingDate, dmy(r.input.opening)),
                line(s.rate, '${pct(r.input.rate)}%'),
                if (p != null && r.periodicPayout != null)
                  line(s.payout(p), rupee(r.periodicPayout!)),
                line(s.totalInterest, rupee(r.totalInterest)),
                line(s.maturityDate, dmy(r.maturityDate)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Brand.yellowSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s.estimateOnly,
                    style: t.bodySmall?.copyWith(color: Brand.ink),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${s.appTitle} · ${s.tagline}',
                  style: t.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
