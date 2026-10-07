/// Builds the image shared after finishing a puzzle: the picture with a
/// caption band, rendered off-screen.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/theme.dart';

Future<Uint8List?> renderShareImage(
  ui.Image picture,
  String title,
  String caption,
) async {
  const w = 1080.0;
  final ph = w * picture.height / picture.width;
  const band = 190.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    Rect.fromLTWH(0, 0, w, ph + band),
    Paint()..color = VeshaColors.black,
  );
  c.drawImageRect(
    picture,
    Rect.fromLTWH(0, 0, picture.width.toDouble(), picture.height.toDouble()),
    Rect.fromLTWH(0, 0, w, ph),
    Paint()..filterQuality = FilterQuality.high,
  );
  // Gold rule like a costume border.
  c.drawRect(Rect.fromLTWH(0, ph, w, 10), Paint()..color = VeshaColors.gold);
  void text(String s, double y, double size, Color color, FontWeight wt) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, color: color, fontWeight: wt),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: w - 80);
    tp.paint(c, Offset(40, y));
  }

  text(title, ph + 36, 54, Colors.white, FontWeight.w700);
  text(caption, ph + 112, 36, VeshaColors.gold, FontWeight.w500);
  final img = await rec.endRecording().toImage(w.toInt(), (ph + band).toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return bytes?.buffer.asUint8List();
}

Future<void> shareImage(Uint8List? png, String name, String text) async {
  final file = png == null
      ? null
      : XFile.fromData(png, mimeType: 'image/png', name: name);
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      files: file == null ? null : [file],
      fileNameOverrides: file == null ? null : [name],
    ),
  );
}
