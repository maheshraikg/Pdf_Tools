import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../lipi/tulu_lipi.dart';
import '../models/word.dart';
import '../widgets/common.dart';

/// Something the learner can trace: a letter or a dictionary word.
class TraceTarget {
  const TraceTarget({
    required this.tulu,
    required this.kannada,
    required this.roman,
    required this.starKey,
  });

  factory TraceTarget.letter(LipiLetter l) => TraceTarget(
    tulu: l.tulu,
    kannada: l.label,
    roman: l.roman,
    starKey: l.starKey,
  );

  factory TraceTarget.word(Word w) => TraceTarget(
    tulu: w.lipi,
    kannada: w.tulu,
    roman: w.roman,
    starKey: w.starKey,
  );

  final String tulu;
  final String kannada;
  final String roman;
  final String starKey;
}

/// Finger-tracing practice with automatic scoring.
class TraceScreen extends StatefulWidget {
  /// Practise the alphabet starting at [startIndex] of [kLipiLetters].
  TraceScreen.letters({super.key, int startIndex = 0})
    : targets = [for (final l in kLipiLetters) TraceTarget.letter(l)],
      initialIndex = startIndex;

  /// Practise a single dictionary word.
  TraceScreen.word({super.key, required Word word})
    : targets = [TraceTarget.word(word)],
      initialIndex = 0;

  final List<TraceTarget> targets;
  final int initialIndex;

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

enum _Mode { trace, free }

class _TraceScreenState extends State<TraceScreen> {
  late int _index = widget.initialIndex;
  _Mode _mode = _Mode.trace;
  final List<List<Offset>> _strokes = [];
  int? _pointer;
  bool _drawing = false;
  TraceResult? _result;
  bool _checking = false;

  TraceTarget get _target => widget.targets[_index];

  void _reset() {
    _strokes.clear();
    _result = null;
  }

  void _go(int delta) => setState(() {
    _index = (_index + delta).clamp(0, widget.targets.length - 1);
    _reset();
  });

  Future<void> _check(double size) async {
    if (_strokes.isEmpty || _checking) return;
    setState(() => _checking = true);
    final result = await GlyphScorer.score(_target.tulu, size, _strokes);
    if (!mounted) return;
    AppState.instance.recordStars(_target.starKey, result.stars);
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _target;
    final many = widget.targets.length > 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          many
              ? 'ಬರೆಯಿರಿ · Trace (${_index + 1}/${widget.targets.length})'
              : 'ಬರೆಯಿರಿ · Trace',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final size = math.min(box.maxWidth - 32, 440.0);
          return SingleChildScrollView(
            physics: _drawing
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: size,
                child: Column(
                  children: [
                    _header(t),
                    const SizedBox(height: 8),
                    _canvas(size),
                    const SizedBox(height: 12),
                    _resultRow(),
                    const SizedBox(height: 8),
                    _controls(size),
                    if (many) ...[const SizedBox(height: 8), _navRow()],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(TraceTarget t) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(t.kannada, style: Theme.of(context).textTheme.headlineSmall),
            Text(t.roman, style: const TextStyle(fontStyle: FontStyle.italic)),
            ListenableBuilder(
              listenable: AppState.instance,
              builder: (_, _) =>
                  StarRow(AppState.instance.starsFor(t.starKey), size: 18),
            ),
          ],
        ),
        if (_mode == _Mode.free) TuluText(t.tulu, size: 40, color: cs.primary),
        const SizedBox(height: 8),
        SegmentedButton<_Mode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Mode.trace, label: Text('ಅನುಸರಿಸಿ\nTrace')),
            ButtonSegment(
              value: _Mode.free,
              label: Text('ಸ್ವತಂತ್ರ\nFree write'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() {
            _mode = s.first;
            _reset();
          }),
        ),
      ],
    );
  }

  Widget _canvas(double size) {
    final cs = Theme.of(context).colorScheme;
    return Listener(
      onPointerDown: (e) {
        if (_pointer != null) return;
        setState(() {
          _pointer = e.pointer;
          _drawing = true;
          _result = null;
          _strokes.add([e.localPosition]);
        });
      },
      onPointerMove: (e) {
        if (e.pointer != _pointer) return;
        setState(() => _strokes.last.add(e.localPosition));
      },
      onPointerUp: (e) => _endStroke(e.pointer),
      onPointerCancel: (e) => _endStroke(e.pointer),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          size: Size.square(size),
          painter: TracePainter(
            text: _target.tulu,
            strokes: _strokes,
            showGuide: _mode == _Mode.trace,
            revealGuide: _result != null,
            background: cs.surfaceContainerLow,
            gridColor: cs.outlineVariant,
            guideColor: cs.primary,
            inkColor: cs.onSurface,
          ),
        ),
      ),
    );
  }

  void _endStroke(int pointer) {
    if (pointer != _pointer) return;
    setState(() {
      _pointer = null;
      _drawing = false;
    });
  }

  Widget _resultRow() {
    final r = _result;
    if (_checking) return const LinearProgressIndicator();
    if (r == null) {
      return Text(
        _mode == _Mode.trace
            ? 'ಮಸುಕಾದ ಅಕ್ಷರದ ಮೇಲೆ ಬರೆಯಿರಿ · Trace over the faint letter'
            : 'ಮೇಲಿನ ಅಕ್ಷರ ನೋಡಿ ಬರೆಯಿರಿ · Write the letter shown above',
        textAlign: TextAlign.center,
      );
    }
    final msg = switch (r.stars) {
      3 => 'ಅದ್ಭುತ! · Excellent!',
      2 => 'ಚೆನ್ನಾಗಿದೆ · Good',
      1 => 'ಪರವಾಗಿಲ್ಲ · Keep practising',
      _ => 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ · Try again',
    };
    return Column(
      children: [
        StarRow(r.stars, size: 32),
        Text(msg, style: Theme.of(context).textTheme.titleMedium),
        Text(
          'Coverage ${(r.coverage * 100).round()}% · '
          'Precision ${(r.precision * 100).round()}%',
        ),
      ],
    );
  }

  Widget _controls(double size) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: _strokes.isEmpty
            ? null
            : () => setState(() {
                _strokes.removeLast();
                _result = null;
              }),
        icon: const Icon(Icons.undo),
        label: const Text('ರದ್ದು · Undo'),
      ),
      OutlinedButton.icon(
        onPressed: _strokes.isEmpty ? null : () => setState(_reset),
        icon: const Icon(Icons.delete_outline),
        label: const Text('ಅಳಿಸಿ · Clear'),
      ),
      FilledButton.icon(
        onPressed: _strokes.isEmpty || _checking ? null : () => _check(size),
        icon: const Icon(Icons.check),
        label: const Text('ಪರಿಶೀಲಿಸಿ · Check'),
      ),
    ],
  );

  Widget _navRow() => Row(
    children: [
      Expanded(
        child: TextButton.icon(
          onPressed: _index > 0 ? () => _go(-1) : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('ಹಿಂದೆ · Prev', overflow: TextOverflow.ellipsis),
        ),
      ),
      Expanded(
        child: TextButton.icon(
          onPressed: _index < widget.targets.length - 1 ? () => _go(1) : null,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right),
          label: const Text('ಮುಂದೆ · Next', overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
  );
}

/// Lays out [text] in the Tulu font scaled to fit ~80% width / 70% height of
/// a square canvas of [size], centred. Returns the painter and its offset.
(TextPainter, Offset) layoutGlyph(String text, double size, Color color) {
  TextPainter make(double fontSize) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: kTuluFontFamily,
        fontSize: fontSize,
        color: color,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();

  const base = 100.0;
  final probe = make(base);
  final w = math.max(probe.width, 1.0), h = math.max(probe.height, 1.0);
  probe.dispose();
  final fontSize = base * math.min(size * 0.8 / w, size * 0.7 / h);
  final tp = make(fontSize);
  return (tp, Offset((size - tp.width) / 2, (size - tp.height) / 2));
}

/// Paints the guide grid, guide glyph and the learner's strokes.
class TracePainter extends CustomPainter {
  TracePainter({
    required this.text,
    required this.strokes,
    required this.showGuide,
    required this.revealGuide,
    required this.background,
    required this.gridColor,
    required this.guideColor,
    required this.inkColor,
  }) : _strokeCount = strokes.fold(0, (n, s) => n + s.length);

  final String text;
  final List<List<Offset>> strokes;
  final bool showGuide;
  final bool revealGuide;
  final Color background, gridColor, guideColor, inkColor;
  final int _strokeCount;

  /// Pen width as a fraction of the canvas side.
  static const double penFraction = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(1, 1, s - 2, s - 2), grid);
    for (final f in [0.25, 0.5, 0.75]) {
      grid.color = gridColor.withValues(alpha: f == 0.5 ? 0.8 : 0.35);
      canvas.drawLine(Offset(s * f, 0), Offset(s * f, s), grid);
      canvas.drawLine(Offset(0, s * f), Offset(s, s * f), grid);
    }

    if (showGuide && !revealGuide) {
      final (tp, o) = layoutGlyph(text, s, guideColor.withValues(alpha: 0.2));
      tp.paint(canvas, o);
      tp.dispose();
    }

    final ink = Paint()
      ..color = revealGuide ? inkColor.withValues(alpha: 0.45) : inkColor
      ..strokeWidth = s * penFraction
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          ink.strokeWidth / 2,
          Paint()..color = ink.color,
        );
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, ink);
    }

    if (revealGuide) {
      final (tp, o) = layoutGlyph(text, s, guideColor);
      tp.paint(canvas, o);
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(TracePainter old) =>
      old.text != text ||
      old._strokeCount != _strokeCount ||
      old.strokes.length != strokes.length ||
      old.showGuide != showGuide ||
      old.revealGuide != revealGuide ||
      old.background != background ||
      old.guideColor != guideColor ||
      old.inkColor != inkColor;
}

/// Result of scoring one attempt.
class TraceResult {
  const TraceResult(this.coverage, this.precision, this.score);

  final double coverage;
  final double precision;
  final double score;

  int get stars => score >= 0.8
      ? 3
      : score >= 0.6
      ? 2
      : score >= 0.4
      ? 1
      : 0;
}

/// Cell mask of a rendered glyph.
class _GlyphMask {
  _GlyphMask(this.cols, this.cell, this.on, this.dilated);

  final int cols;
  final double cell;
  final List<bool> on;
  final List<bool> dilated;
}

/// Scores strokes against the rendered glyph using a coarse cell grid.
class GlyphScorer {
  GlyphScorer._();

  static const double _cellPx = 6;
  static const double _sampleStep = 3;
  static const int _dilateCells = 3;
  static final Map<String, _GlyphMask> _cache = {};

  static Future<_GlyphMask> _mask(String text, double size) async {
    final key = '$text@${size.round()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final px = size.ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final (tp, o) = layoutGlyph(text, size, const Color(0xFF000000));
    tp.paint(canvas, o);
    tp.dispose();
    final picture = recorder.endRecording();
    final image = await picture.toImage(px, px);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    final Uint8List rgba = data!.buffer.asUint8List();

    final cols = (size / _cellPx).ceil();
    bool alphaAt(double x, double y) {
      final xi = x.floor().clamp(0, px - 1), yi = y.floor().clamp(0, px - 1);
      return rgba[(yi * px + xi) * 4 + 3] > 100;
    }

    final on = List<bool>.filled(cols * cols, false);
    for (var r = 0; r < cols; r++) {
      for (var c = 0; c < cols; c++) {
        final x0 = c * _cellPx, y0 = r * _cellPx;
        const q = _cellPx / 4;
        on[r * cols + c] =
            alphaAt(x0 + _cellPx / 2, y0 + _cellPx / 2) ||
            alphaAt(x0 + q, y0 + q) ||
            alphaAt(x0 + 3 * q, y0 + q) ||
            alphaAt(x0 + q, y0 + 3 * q) ||
            alphaAt(x0 + 3 * q, y0 + 3 * q);
      }
    }

    final dilated = List<bool>.filled(cols * cols, false);
    for (var r = 0; r < cols; r++) {
      for (var c = 0; c < cols; c++) {
        if (!on[r * cols + c]) continue;
        for (var dr = -_dilateCells; dr <= _dilateCells; dr++) {
          for (var dc = -_dilateCells; dc <= _dilateCells; dc++) {
            final rr = r + dr, cc = c + dc;
            if (rr >= 0 && rr < cols && cc >= 0 && cc < cols) {
              dilated[rr * cols + cc] = true;
            }
          }
        }
      }
    }
    return _cache[key] = _GlyphMask(cols, _cellPx, on, dilated);
  }

  /// Resamples strokes every [_sampleStep] px.
  static List<Offset> _samples(List<List<Offset>> strokes) {
    final out = <Offset>[];
    for (final s in strokes) {
      if (s.isEmpty) continue;
      out.add(s.first);
      for (var i = 1; i < s.length; i++) {
        final a = s[i - 1], b = s[i];
        final d = (b - a).distance;
        final n = (d / _sampleStep).floor();
        for (var k = 1; k <= n; k++) {
          out.add(Offset.lerp(a, b, k * _sampleStep / d)!);
        }
        if (d > 0) out.add(b);
      }
    }
    return out;
  }

  /// Scores [strokes] drawn on a [size]×[size] canvas against [text].
  static Future<TraceResult> score(
    String text,
    double size,
    List<List<Offset>> strokes,
  ) async {
    final mask = await _mask(text, size);
    final samples = _samples(strokes);
    final total = mask.on.where((b) => b).length;
    if (samples.isEmpty || total == 0) return const TraceResult(0, 0, 0);

    final cols = mask.cols, cell = mask.cell;
    final radius = size * TracePainter.penFraction / 2;
    final covered = List<bool>.filled(cols * cols, false);
    var inside = 0;
    final reach = (radius / cell).ceil();
    for (final p in samples) {
      final c0 = (p.dx / cell).floor(), r0 = (p.dy / cell).floor();
      if (r0 >= 0 &&
          r0 < cols &&
          c0 >= 0 &&
          c0 < cols &&
          mask.dilated[r0 * cols + c0]) {
        inside++;
      }
      for (var r = r0 - reach; r <= r0 + reach; r++) {
        if (r < 0 || r >= cols) continue;
        for (var c = c0 - reach; c <= c0 + reach; c++) {
          if (c < 0 || c >= cols) continue;
          final centre = Offset((c + 0.5) * cell, (r + 0.5) * cell);
          if ((centre - p).distance <= radius) covered[r * cols + c] = true;
        }
      }
    }
    var hit = 0;
    for (var i = 0; i < mask.on.length; i++) {
      if (mask.on[i] && covered[i]) hit++;
    }
    final coverage = hit / total;
    final precision = inside / samples.length;
    var score = 0.75 * coverage + 0.25 * precision;
    if (precision < 0.5) score *= 0.6;
    return TraceResult(coverage, precision, score);
  }
}
