/// Live camera address scan with on-device ML Kit text recognition (English
/// and Hindi / Devanagari). Frames are read straight from the camera stream:
/// the PIN and office names on the address show their line as soon as they
/// are read. Capture takes one full-resolution photo for hard addresses
/// (handwriting, small print); it is deleted right after reading.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/app_scope.dart';
import '../../core/feedback.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/sort_engine.dart';
import '../lookup/sort_result_view.dart';
import 'address_parser.dart';
import 'kannada_ocr.dart';
import 'live_scan.dart';

class ScanOutcome {
  const ScanOutcome(this.pin, this.place);

  final String pin;
  final String? place;
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  /// Minimum time between two recognised frames.
  static const _frameGap = Duration(milliseconds: 450);

  /// Tesseract (Kannada) is slower: one frame at a time, at most this often.
  static const _kannadaGap = Duration(milliseconds: 1500);

  CameraController? _camera;
  CameraDescription? _desc;
  String? _cameraError;
  bool _capturing = false;
  bool _torch = false;
  bool _paused = false;
  bool _started = false;

  // English (Latin) and Hindi (Devanagari) models are bundled; live frames
  // alternate between them, a captured photo is read with both.
  final _latin = TextRecognizer(script: TextRecognitionScript.latin);
  final _deva = TextRecognizer(script: TextRecognitionScript.devanagiri);
  int _frameNo = 0;
  bool _reading = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  bool _readingKannada = false;
  DateTime _lastKannada = DateTime.fromMillisecondsSinceEpoch(0);

  final _stabilizer = PinStabilizer();
  // Kannada frames come less often, so they confirm PINs among themselves.
  final _kannadaStabilizer = PinStabilizer();
  String? _pin;
  SortResult? _result;
  List<ScanOfficeHit> _offices = [];
  List<String> _places = [];
  List<String> _postNames = [];
  String _placesKey = '';
  bool _sawText = false;

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
      final c = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      _desc = back;
      if (!_paused) await _startStream(c);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _camera = c);
    } on Object catch (e) {
      if (mounted) setState(() => _cameraError = '$e');
    }
  }

  Future<void> _startStream(CameraController c) async {
    if (c.value.isStreamingImages) return;
    final o = _desc?.sensorOrientation ?? 90;
    await c.startImageStream((img) => _onFrame(img, o));
  }

  Future<void> _setPaused(bool paused) async {
    setState(() => _paused = paused);
    final c = _camera;
    if (!paused && c != null) {
      try {
        await _startStream(c);
      } on Object catch (e) {
        if (mounted) toast(context, AppLocalizations.of(context).error('$e'));
      }
    }
  }

  /// One careful read of a full-resolution photo: for handwriting and small
  /// print. The photo is deleted straight after.
  Future<void> _capture() async {
    final c = _camera;
    if (c == null || _capturing) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _capturing = true;
      _paused = true;
    });
    XFile? shot;
    var text = '';
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      shot = await c.takePicture();
      final input = InputImage.fromFilePath(shot.path);
      final a = await _latin.processImage(input);
      final b = await _deva.processImage(input);
      var kn = '';
      try {
        kn = await KannadaOcr.readFile(shot.path);
      } on Object {
        // Kannada model unavailable: English / Hindi text is still used.
      }
      text = '${a.text}\n${b.text}\n$kn';
    } on Object catch (e) {
      if (mounted) toast(context, l.error('$e'));
    } finally {
      if (shot != null) {
        try {
          await File(shot.path).delete();
        } on Object {
          // Already gone.
        }
      }
    }
    if (!mounted) return;
    setState(() => _capturing = false);
    await _handleText(text, captured: true);
    if (mounted && _pin == null && _offices.isEmpty) {
      AppFeedback.warning(context.settings);
      toast(context, l.noPinDetected);
    }
  }

  Future<void> _stopCamera() async {
    final c = _camera;
    _camera = null;
    _torch = false;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } on Object {
      // Already stopped.
    }
    await c.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_camera == null) return;
      _stopCamera();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _camera == null && _cameraError == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _latin.close();
    _deva.close();
    super.dispose();
  }

  InputImage? _toInputImage(CameraImage img, int sensorOrientation) {
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
    final InputImageFormat format;
    final Uint8List bytes;
    if (Platform.isAndroid) {
      // CameraX gives one NV21 plane when NV21 is requested.
      if (img.planes.length != 1) return null;
      format = InputImageFormat.nv21;
      bytes = img.planes.first.bytes;
    } else {
      final f = InputImageFormatValue.fromRawValue(img.format.raw);
      if (f == null || img.planes.length != 1) return null;
      format = f;
      bytes = img.planes.first.bytes;
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: img.planes.first.bytesPerRow,
      ),
    );
  }

  /// Kannada: Tesseract on a copy of the frame, alongside ML Kit.
  Future<void> _readKannada(CameraImage img, int sensorOrientation) async {
    if (!KannadaOcr.available || _readingKannada || img.planes.length != 1) return;
    final now = DateTime.now();
    if (now.difference(_lastKannada) < _kannadaGap) return;
    _lastKannada = now;
    _readingKannada = true;
    try {
      final plane = img.planes.first;
      final text = await KannadaOcr.readNv21(
        Uint8List.fromList(plane.bytes),
        width: img.width,
        height: img.height,
        stride: plane.bytesPerRow,
        rotation: sensorOrientation,
      );
      if (!mounted || _paused) return;
      await _handleText(text, stabilizer: _kannadaStabilizer);
    } on Object {
      // Model not ready or a bad frame; tried again shortly.
    } finally {
      _readingKannada = false;
    }
  }

  Future<void> _onFrame(CameraImage img, int sensorOrientation) async {
    if (_paused || !mounted) return;
    _readKannada(img, sensorOrientation);
    if (_reading) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < _frameGap) return;
    _lastFrame = now;
    _reading = true;
    try {
      final input = _toInputImage(img, sensorOrientation);
      if (input == null) return;
      final recognizer = _frameNo.isEven ? _latin : _deva;
      _frameNo++;
      final r = await recognizer.processImage(input);
      if (!mounted || _paused) return;
      await _handleText(r.text);
    } on Object {
      // A bad frame; the next one is read shortly.
    } finally {
      _reading = false;
    }
  }

  Future<void> _handleText(String text, {bool captured = false, PinStabilizer? stabilizer}) async {
    if (text.trim().isNotEmpty && !_sawText) setState(() => _sawText = true);
    final cand = parseAddress(text);
    final first = cand.pins.firstOrNull;
    final stab = stabilizer ?? _stabilizer;
    if (captured && first != null ? stab.force(first) : stab.add(first)) {
      await _resolvePin(stab.stable!);
    }
    final key = cand.places.take(8).join('|');
    if (cand.places.isNotEmpty && (captured || key != _placesKey)) {
      _placesKey = key;
      _places = cand.places;
      _postNames = cand.postNames;
      await _findOffices(cand.places);
    }
  }

  Future<void> _resolvePin(String pin) async {
    final services = context.services;
    final settings = context.settings;
    final place = _offices.where((h) => h.office.pin == pin).firstOrNull?.office.officeName;
    final r = await services.engine.resolvePin(pin, category: settings.category, officeName: place);
    if (!mounted) return;
    // OCR can read a street number as a PIN: keep only real PINs.
    if (!r.valid || (r.offices.isEmpty && r.bag == null)) return;
    final isNew = pin != _pin;
    setState(() {
      _pin = pin;
      _result = r;
      _offices = [for (final h in _offices) h.withPin(pin)]..sort(compareScanHits);
    });
    if (isNew) AppFeedback.success(settings);
  }

  Future<void> _findOffices(List<String> places) async {
    final services = context.services;
    final hits = await officesOnAddress(
      services.directory,
      services.engine,
      places,
      category: context.settings.category,
      pin: _pin,
    );
    if (!mounted || hits.isEmpty) return;
    setState(() => _offices = hits);
  }

  Future<void> _reResolve() async {
    final p = _pin;
    if (p == null) return;
    _pin = null;
    await _resolvePin(p);
    if (_places.isNotEmpty) await _findOffices(_places);
  }

  void _next() {
    AppFeedback.tap(context.settings);
    _stabilizer.reset();
    _kannadaStabilizer.reset();
    setState(() {
      _pin = null;
      _result = null;
      _offices = [];
      _places = [];
      _postNames = [];
      _placesKey = '';
      _sawText = false;
    });
    _setPaused(false);
  }

  void _use(String pin, String? place) => Navigator.pop(context, ScanOutcome(pin, place));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _camera;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanAddress),
        actions: [
          if (c != null)
            IconButton(
              tooltip: l.torch,
              icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
              onPressed: () async {
                _torch = !_torch;
                try {
                  await c.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
                } on Object {
                  _torch = false;
                }
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 4, child: _preview(l)),
          Expanded(flex: 5, child: _results(l)),
        ],
      ),
    );
  }

  Widget _preview(AppLocalizations l) {
    final c = _camera;
    if (_cameraError != null) {
      return EmptyState(icon: Icons.no_photography_outlined, text: l.cameraUnavailable(_cameraError!));
    }
    if (c == null || !c.value.isInitialized) return const ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator()));
    final found = _pin != null;
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: c.value.previewSize?.height ?? 1, height: c.value.previewSize?.width ?? 1, child: CameraPreview(c)),
            ),
          ),
        ),
        // Aim box.
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 56),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: found ? kTeal : Colors.white70, width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            child: Text(l.scanLiveHint, style: const TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Row(
            children: [
              Expanded(child: Align(alignment: Alignment.centerLeft, child: _statusPill(l))),
              const SizedBox(width: 8),
              FloatingActionButton(
                key: const ValueKey('scan_capture'),
                heroTag: null,
                tooltip: l.capture,
                onPressed: _capturing ? null : _capture,
                child: _capturing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)) : const Icon(Icons.camera_alt, size: 30),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                key: const ValueKey('scan_pause'),
                onPressed: _capturing ? null : () => _setPaused(!_paused),
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                label: Text(_paused ? l.scanResume : l.scanPause),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusPill(AppLocalizations l) {
    final pin = _pin;
    final (Color bg, IconData icon, String text) = _paused
        ? (Colors.black87, Icons.pause_circle, l.scanPaused)
        : pin != null
        ? (kTeal, Icons.check_circle, pin)
        : (Colors.black87, Icons.center_focus_weak, l.scanLooking);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: pin != null && !_paused ? 20 : 15, letterSpacing: pin != null && !_paused ? 2 : 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(AppLocalizations l) {
    final t = Theme.of(context).textTheme;
    final r = _result;
    final pin = _pin;
    final nothing = r == null && _offices.isEmpty;
    final check = checkAddress(pin, r?.offices ?? const [], _offices, postNames: _postNames);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        if (check != null) ...[
          _AddressCheckCard(check: check, onUse: _use),
          const SizedBox(height: 10),
        ],
        if (pin != null && r != null) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.scanPinOnAddress, style: t.labelLarge),
                    Text(pin, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 3)),
                  ],
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('scan_use'),
                onPressed: () => _use(pin, _offices.where((h) => h.samePin).firstOrNull?.office.officeName),
                icon: const Icon(Icons.dialpad),
                label: Text(l.useThisPin),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SortResultView(result: r, showBreakdown: false, onEdited: _reResolve),
          const SizedBox(height: 12),
        ],
        if (_offices.isNotEmpty) ...[
          Text(l.scanOfficesBest, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          for (final h in _offices) _ScanOfficeCard(hit: h, onTap: () => _use(h.office.pin, h.office.officeName)),
          const SizedBox(height: 8),
        ],
        if (nothing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                if (!_paused) const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 12),
                Expanded(child: Text(_sawText ? l.scanLooking : l.scanNothingYet, style: t.titleMedium)),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(key: const ValueKey('scan_next'), onPressed: _next, icon: const Icon(Icons.refresh), label: Text(l.scanNext)),
          ),
        const SizedBox(height: 12),
        Text(l.scanPrivacy, style: t.bodySmall),
      ],
    );
  }
}

/// An office read on the address: name, PIN, district, distance, and its
/// line with position on the right.
class _ScanOfficeCard extends StatelessWidget {
  const _ScanOfficeCard({required this.hit, required this.onTap});

  final ScanOfficeHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final o = hit.office;
    final r = hit.result;
    final bag = r.bag;
    final colour = bag == null ? c.outlineVariant : bagColour(context, bag);
    final section = r.bagRule?.section ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: colour),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (hit.samePin) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check_circle, color: kTeal, size: 20)),
                          Flexible(child: Text('${o.officeName} ${o.officeType}', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                        ],
                      ),
                      Text(
                        [o.pin, if (o.district.isNotEmpty) o.district].join(' · '),
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: c.onSurfaceVariant),
                      ),
                      if (bag == null && r.otherBag != null)
                        Text(
                          l.otherModeHint(categoryLabel(l, r.otherCategory!), r.otherBag!.label),
                          style: t.bodyMedium?.copyWith(color: warningColor(context), fontWeight: FontWeight.w700),
                        )
                      else if (bag == null)
                        Text(l.noLineInScheme, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              if (bag != null)
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Color.alphaBlend(colour.withValues(alpha: 0.14), c.surfaceContainerLowest),
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bag.code,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: c.onSurface),
                      ),
                      if (section.isNotEmpty) Text('${l.section} $section', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PIN ↔ post office check: ✅ match, or ⚠️ / ❌ with the best option and
/// its line.
class _AddressCheckCard extends StatelessWidget {
  const _AddressCheckCard({required this.check, required this.onUse});

  final AddressCheck check;
  final void Function(String pin, String? place) onUse;

  String _lineOf(AppLocalizations l, SortResult r) {
    final bag = r.bag;
    if (bag == null) return l.noLineInScheme;
    final pos = r.bagRule?.section ?? '';
    return [bag.label, if (pos.isNotEmpty) '${l.section} $pos'].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = check;
    final n = c.named.office;
    final (IconData icon, Color colour, String title) = switch (c.level) {
      AddressCheckLevel.match => (Icons.check_circle, okColor(context), l.chkMatch),
      AddressCheckLevel.sameArea => (Icons.warning_amber_rounded, warningColor(context), l.chkSameArea),
      AddressCheckLevel.mismatch => (Icons.cancel, Theme.of(context).colorScheme.error, l.chkMismatch),
    };
    final po = c.pinOffice;
    return Semantics(
      liveRegion: true,
      child: Card(
        key: ValueKey('scan_check_${c.level.name}'),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colour, width: 3)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colour, size: 32),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colour))),
                ],
              ),
              if (c.level == AddressCheckLevel.match)
                Text('${n.officeName} ${n.officeType} · ${n.pin}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))
              else ...[
                const SizedBox(height: 4),
                if (po != null) Text(l.mmPinIs(c.pin, '${po.officeName} ${po.officeType}, ${po.district}'), style: t.bodyLarge),
                Text(l.chkAddressNames('${n.officeName} ${n.officeType}, ${n.district}', n.pin), style: t.bodyLarge),
                const SizedBox(height: 8),
                Text(l.chkBest, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                Text('${n.pin} · ${n.officeName} ${n.officeType}', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                Text(_lineOf(l, c.named.result), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('check_use_best'),
                      onPressed: () => onUse(n.pin, n.officeName),
                      icon: const Icon(Icons.check),
                      label: Text(l.chkUse(n.pin)),
                    ),
                    OutlinedButton(
                      key: const ValueKey('check_keep_pin'),
                      onPressed: () => onUse(c.pin, null),
                      child: Text(l.chkKeep(c.pin)),
                    ),
                  ],
                ),
                if (c.others.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(l.chkAlso, style: t.labelLarge),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final h in c.others)
                        ActionChip(
                          label: Text('${h.office.pin} · ${h.office.officeName} (${h.office.district})'),
                          onPressed: () => onUse(h.office.pin, h.office.officeName),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(l.chkBestWhy, style: t.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
