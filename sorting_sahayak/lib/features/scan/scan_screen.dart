/// Camera address scan with on-device ML Kit text recognition. The photo is
/// deleted right after recognition and never stored or uploaded.
library;

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/app_scope.dart';
import '../../core/feedback.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/pin_utils.dart';
import '../../core/widgets.dart';
import '../../data/sort_engine.dart';
import '../bulk/bulk_counter.dart';
import '../find_pin/mismatch_view.dart';
import '../lookup/sort_result_view.dart';
import 'address_parser.dart';

class ScanOutcome {
  const ScanOutcome(this.pin, this.place);

  final String pin;
  final String? place;
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.bulkSessionId});

  /// When set, "Add to bulk count" adds to this session and returns.
  final int? bulkSessionId;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _camera;
  String? _cameraError;
  bool _busy = false;
  bool _torch = false;

  final _pin = TextEditingController();
  final _place = TextEditingController();
  List<String> _pinCandidates = [];
  List<String> _placeCandidates = [];
  SortResult? _result;
  bool _scanned = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final c = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _camera = c);
    } on Object catch (e) {
      if (mounted) setState(() => _cameraError = '$e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _camera;
    if (c == null) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _camera = null;
      c.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && !_scanned) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _pin.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final c = _camera;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    final services = context.services;
    final settings = context.settings;
    XFile? shot;
    TextRecognizer? recognizer;
    String text = '';
    try {
      shot = await c.takePicture();
      // Only the Latin (English) model is bundled, to keep the APK small.
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final r = await recognizer.processImage(InputImage.fromFilePath(shot.path));
      text = r.text;
    } on Object catch (e) {
      if (mounted) toast(context, l.error('$e'));
    } finally {
      await recognizer?.close();
      // Privacy: delete the photo immediately.
      if (shot != null) {
        try {
          await File(shot.path).delete();
        } on Object {
          // Already gone.
        }
      }
    }
    final cand = parseAddress(text);
    text = '';
    _pinCandidates = cand.pins;
    _placeCandidates = cand.places;
    _pin.text = cand.pins.firstOrNull ?? '';
    final best = await bestPlace(services.directory, cand.places, pin: cand.pins.firstOrNull);
    _place.text = best?.place ?? '';
    _scanned = true;
    // Free the camera while reviewing the result.
    _camera = null;
    await c.dispose();
    if (!mounted) return;
    setState(() => _busy = false);
    if (_pin.text.isEmpty) {
      AppFeedback.warning(settings);
    } else {
      AppFeedback.success(settings);
    }
    await _resolve();
  }

  Future<void> _resolve() async {
    final p = PinUtils.digitsOnly(_pin.text);
    if (p.length != 6) {
      setState(() => _result = null);
      return;
    }
    final r = await context.services.engine.resolvePin(p, category: context.settings.category, officeName: _place.text);
    if (mounted) setState(() => _result = r);
  }

  void _again() {
    setState(() {
      _scanned = false;
      _result = null;
      _pin.clear();
      _place.clear();
      _pinCandidates = [];
      _placeCandidates = [];
    });
    _initCamera();
  }

  Future<void> _addToBulk() async {
    final l = AppLocalizations.of(context);
    final services = context.services;
    final settings = context.settings;
    final sessionId = widget.bulkSessionId ?? (await services.user.sessions()).where((s) => !s.ended).firstOrNull?.id;
    if (!mounted) return;
    if (sessionId == null) {
      toast(context, l.noOpenSession);
      return;
    }
    final session = await services.user.session(sessionId);
    final entry = await makeBulkEntry(services.engine, _pin.text, session?.category ?? settings.category);
    await services.user.addEntry(sessionId, entry);
    if (!mounted) return;
    toast(context, l.addedToBulk(entry.bagCode ?? l.unresolved));
    if (widget.bulkSessionId != null) {
      Navigator.pop(context);
    } else {
      _again();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanAddress),
      ),
      body: _scanned ? _review(l) : _preview(l),
    );
  }

  Widget _preview(AppLocalizations l) {
    final c = _camera;
    if (_cameraError != null) {
      return EmptyState(icon: Icons.no_photography_outlined, text: l.cameraUnavailable(_cameraError!));
    }
    if (c == null || !c.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        Positioned.fill(child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: c.value.previewSize?.height ?? 1, height: c.value.previewSize?.width ?? 1, child: CameraPreview(c)))),
        Positioned(
          left: 24,
          right: 24,
          top: 24,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black54,
            child: Text(l.scanHint, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filled(
                tooltip: l.torch,
                iconSize: 32,
                icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
                onPressed: () async {
                  _torch = !_torch;
                  await c.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
                  setState(() {});
                },
              ),
              SizedBox(
                width: 84,
                height: 84,
                child: FloatingActionButton.large(
                  tooltip: l.capture,
                  onPressed: _busy ? null : _capture,
                  child: _busy ? const CircularProgressIndicator() : const Icon(Icons.camera, size: 48),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _review(AppLocalizations l) {
    final r = _result;
    final p = PinUtils.digitsOnly(_pin.text);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_pinCandidates.isEmpty) WarningBanner(text: l.noPinDetected),
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4),
          decoration: InputDecoration(labelText: l.detectedPin, counterText: ''),
          onChanged: (_) => _resolve(),
        ),
        if (_pinCandidates.length > 1)
          Wrap(spacing: 6, children: [
            for (final c in _pinCandidates) ActionChip(label: Text(c), onPressed: () {
              _pin.text = c;
              _resolve();
            }),
          ]),
        const SizedBox(height: 8),
        TextField(
          controller: _place,
          decoration: InputDecoration(labelText: l.detectedPlace),
          onChanged: (_) => setState(() {}),
        ),
        if (_placeCandidates.isNotEmpty)
          Wrap(spacing: 6, children: [
            for (final c in _placeCandidates.take(6)) ActionChip(label: Text(c), onPressed: () => setState(() => _place.text = c)),
          ]),
        const SizedBox(height: 12),
        if (p.length == 6 && _place.text.trim().length >= 2) ...[
          MismatchView(pin: p, place: _place.text, onPickPin: (o) {
            _pin.text = o.pin;
            _resolve();
          }),
          const SizedBox(height: 10),
        ],
        if (r != null) SortResultView(result: r, showBreakdown: false),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: p.length == 6 ? () => Navigator.pop(context, ScanOutcome(p, _place.text.trim().isEmpty ? null : _place.text.trim())) : null,
              icon: const Icon(Icons.dialpad),
              label: Text(l.useThisPin),
            ),
            FilledButton.tonalIcon(onPressed: p.length == 6 ? _addToBulk : null, icon: const Icon(Icons.add_box_outlined), label: Text(l.addToBulk)),
            OutlinedButton.icon(onPressed: _again, icon: const Icon(Icons.refresh), label: Text(l.scanAgain)),
          ],
        ),
        const SizedBox(height: 16),
        Text(l.scanPrivacy, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
