import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/article_number.dart';
import '../common/widgets.dart';

/// Continuous barcode / QR scanner for article numbers. Returns the list of
/// scanned codes when the user taps "Done".
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.all],
  );
  final List<String> _codes = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    for (final b in cap.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      // QR labels may contain more text; prefer an embedded S10 number.
      final m = RegExp(r'[A-Z]{2}\d{9}[A-Z]{2}').firstMatch(raw.toUpperCase());
      final code = m?.group(0) ?? cleanArticleNumber(raw);
      if (code.length > 40 || _codes.contains(code)) continue;
      HapticFeedback.mediumImpact();
      setState(() => _codes.insert(0, code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanBarcode),
        actions: [
          IconButton(
            tooltip: l.torch,
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (c, e) => EmptyState(icon: Icons.no_photography, text: l.cameraError),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l.scannedCount(_codes.length), style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final c in _codes)
                        ListTile(
                          dense: true,
                          title: Text(c, style: const TextStyle(fontSize: 18, fontFamily: 'monospace')),
                          subtitle: _statusText(context, c),
                          trailing: IconButton(
                            tooltip: l.remove,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _codes.remove(c)),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _codes.reversed.toList()),
                    icon: const Icon(Icons.check),
                    label: Text(l.done),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget? _statusText(BuildContext context, String code) {
  final l = context.l;
  return switch (validateArticleNumber(code)) {
    ArticleNumberStatus.valid => null,
    ArticleNumberStatus.badCheckDigit => Text(l.articleBadCheck, style: const TextStyle(color: Colors.orange)),
    ArticleNumberStatus.otherFormat => Text(l.articleOtherFormat),
    ArticleNumberStatus.invalid => Text(l.articleInvalid, style: const TextStyle(color: Colors.red)),
  };
}

/// Takes a photo of the address and runs on-device OCR (ML Kit: Latin and
/// Devanagari). Returns the recognised text, or null.
///
/// ML Kit has no Kannada model, so Kannada addresses need manual search.
Future<String?> scanAddressText(BuildContext context) async {
  final l = context.l;
  final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 90);
  if (x == null) return null;
  final input = InputImage.fromFilePath(x.path);
  final latin = TextRecognizer(script: TextRecognitionScript.latin);
  final deva = TextRecognizer(script: TextRecognitionScript.devanagiri);
  try {
    final r1 = await latin.processImage(input);
    final r2 = await deva.processImage(input);
    // Use the result that recognised more text; the Devanagari model also
    // reads Latin, so it usually wins for Hindi addresses.
    final t1 = r1.text.trim();
    final t2 = r2.text.trim();
    final hasDeva = RegExp(r'[ऀ-ॿ]').hasMatch(t2);
    return hasDeva && t2.length >= t1.length * 0.6 ? t2 : (t1.isNotEmpty ? t1 : t2);
  } catch (_) {
    if (context.mounted) context.toast(l.ocrFailed);
    return null;
  } finally {
    await latin.close();
    await deva.close();
    try {
      File(x.path).deleteSync();
    } catch (_) {}
  }
}
