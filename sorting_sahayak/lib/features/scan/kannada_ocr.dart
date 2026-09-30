/// Kannada text recognition with Tesseract, done natively on Android
/// (MainActivity, bundled `kan` model). ML Kit has no Kannada model.
library;

import 'dart:io';

import 'package:flutter/services.dart';

class KannadaOcr {
  static const _channel = MethodChannel('po_sorting/kannada_ocr');

  static bool get available => Platform.isAndroid;

  /// Reads a photo file (the caller deletes it).
  static Future<String> readFile(String path) async {
    if (!available) return '';
    return await _channel.invokeMethod<String>('readFile', {'path': path}) ?? '';
  }

  /// Reads one NV21 camera frame, [rotation] degrees clockwise to upright.
  static Future<String> readNv21(Uint8List bytes, {required int width, required int height, required int stride, required int rotation}) async {
    if (!available) return '';
    return await _channel.invokeMethod<String>('readNv21', {
          'bytes': bytes,
          'width': width,
          'height': height,
          'stride': stride,
          'rotation': rotation,
        }) ??
        '';
  }
}
