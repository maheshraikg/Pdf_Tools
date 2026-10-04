// Renders every festival illustration to docs/screenshots/art_gallery.png.
//   flutter test tool/screenshots/art_gallery_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/art/festival_art.dart';

void main() {
  testWidgets('art gallery', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 400));
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: Container(
            color: const Color(0xFFFFF8EC),
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in ArtKind.values)
                  FestivalArt(kind: k, size: 110, animate: false),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory('docs/screenshots').createSync(recursive: true);
      File('docs/screenshots/art_gallery.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
