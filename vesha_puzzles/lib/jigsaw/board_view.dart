/// Board canvas (drag, pinch-zoom, pan, tray drops) and the piece tray.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'controller.dart';

class JigsawBoardView extends StatefulWidget {
  const JigsawBoardView({
    super.key,
    required this.controller,
    required this.frameColor,
    required this.backgroundColor,
    this.highlightColor = const Color(0xFFFFC107),
  });

  final JigsawController controller;
  final Color frameColor;
  final Color backgroundColor;
  final Color highlightColor;

  @override
  State<JigsawBoardView> createState() => _JigsawBoardViewState();
}

enum _Mode { none, drag, view }

class _JigsawBoardViewState extends State<JigsawBoardView>
    with SingleTickerProviderStateMixin {
  _Mode _mode = _Mode.none;
  Offset _anchorWorld = Offset.zero;
  double _baseScale = 1, _scaleBaseline = 1;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Offset? _doubleTapAt;
  Timer? _pulseTimer;

  JigsawController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onController);
  }

  @override
  void didUpdateWidget(JigsawBoardView old) {
    super.didUpdateWidget(old);
    if (old.controller != c) {
      old.controller.removeListener(_onController);
      c.addListener(_onController);
    }
  }

  void _onController() {
    if (c.highlightPiece != null && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
      _pulseTimer?.cancel();
      _pulseTimer = Timer(const Duration(milliseconds: 2100), () {
        if (!mounted) return;
        _pulse.stop();
        c.clearHighlight();
      });
    }
  }

  @override
  void dispose() {
    c.removeListener(_onController);
    _pulseTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startView(Offset focal, double gestureScale) {
    _mode = _Mode.view;
    _anchorWorld = c.toWorld(focal);
    _baseScale = c.scale;
    _scaleBaseline = gestureScale;
  }

  @override
  Widget build(BuildContext context) {
    c.devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) c.resize(size);
        });
        return DragTarget<int>(
          onAcceptWithDetails: (d) {
            final rb = context.findRenderObject() as RenderBox;
            c.dropFromTray(d.data, rb.globalToLocal(d.offset));
          },
          builder: (context, candidates, _) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (d) {
              if (d.pointerCount == 1 && c.beginDrag(d.localFocalPoint)) {
                _mode = _Mode.drag;
              } else {
                _startView(d.localFocalPoint, 1);
              }
            },
            onScaleUpdate: (d) {
              if (_mode == _Mode.drag) {
                if (d.pointerCount > 1) {
                  c.endDrag();
                  _startView(d.localFocalPoint, d.scale);
                } else {
                  c.dragBy(d.focalPointDelta);
                  return;
                }
              }
              if (_mode == _Mode.view) {
                final s = _baseScale * d.scale / _scaleBaseline;
                c.setView(s, d.localFocalPoint - _anchorWorld * c.scale);
                // setView clamps scale; recompute pan with the clamped one.
                c.setView(c.scale, d.localFocalPoint - _anchorWorld * c.scale);
              }
            },
            onScaleEnd: (_) {
              if (_mode == _Mode.drag) c.endDrag();
              if (_mode == _Mode.view) c.zoomEnded();
              _mode = _Mode.none;
            },
            onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
            onDoubleTap: () {
              final p = _doubleTapAt;
              if (p != null && c.returnToTray(p)) return;
              c.fit(size);
            },
            child: CustomPaint(
              size: size,
              painter: _BoardPainter(
                c,
                _pulse,
                widget.frameColor,
                widget.backgroundColor,
                widget.highlightColor,
                dropping: candidates.isNotEmpty,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(
    this.c,
    this.pulse,
    this.frameColor,
    this.background,
    this.highlight, {
    required this.dropping,
  }) : super(repaint: Listenable.merge([c.boardTick, pulse]));

  final JigsawController c;
  final Animation<double> pulse;
  final Color frameColor, background, highlight;
  final bool dropping;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    canvas.save();
    canvas.translate(c.pan.dx, c.pan.dy);
    canvas.scale(c.scale);
    final b = c.board;
    final frame = b.frame;
    canvas.drawRect(frame, Paint()..color = frameColor);
    if (c.showGhost) {
      canvas.drawImageRect(
        c.image,
        Rect.fromLTWH(
          0,
          0,
          c.image.width.toDouble(),
          c.image.height.toDouble(),
        ),
        frame,
        Paint()
          ..color = const Color(0x4DFFFFFF)
          ..filterQuality = FilterQuality.low,
      );
    }
    canvas.drawRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (dropping ? 3 : 1.5) / c.scale
        ..color = dropping ? highlight : const Color(0x55000000),
    );

    if (c.cache.isReady) {
      final local = c.cache.localRect;
      final shadow = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color(0x55000000),
          BlendMode.srcIn,
        );
      final paint = Paint()..filterQuality = FilterQuality.medium;
      for (final g in b.groupsBottomToTop) {
        final lifting = g.id == c.draggingGroup;
        for (final id in g.pieces) {
          final img = c.cache[id]!;
          final src = Rect.fromLTWH(
            0,
            0,
            img.width.toDouble(),
            img.height.toDouble(),
          );
          final dst = local.shift(b.positionOf(id));
          if (lifting) {
            canvas.drawImageRect(
              img,
              src,
              dst.shift(Offset(4, 6) / c.scale),
              shadow,
            );
          }
          canvas.drawImageRect(img, src, dst, paint);
        }
      }
    }

    final h = c.highlightPiece;
    if (h != null && !b.inTray(h)) {
      final path = b.paths.pathOf(h).shift(b.positionOf(h));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2 + 4 * pulse.value) / c.scale
          ..color = highlight.withValues(alpha: 0.5 + 0.5 * pulse.value),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.c != c || old.dropping != dropping || old.frameColor != frameColor;
}

/// Horizontal strip of loose pieces. Drag a piece up onto the board, or
/// tap it to drop it near the frame.
class JigsawTray extends StatelessWidget {
  const JigsawTray({super.key, required this.controller, this.height = 96});

  final JigsawController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SizedBox(
      height: height,
      child: ValueListenableBuilder<int>(
        valueListenable: c.trayTick,
        builder: (context, _, _) {
          final ids = c.visibleTray;
          if (ids.isEmpty) return const SizedBox.shrink();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: ids.length,
            itemExtent: height * 0.9,
            itemBuilder: (context, i) => _TrayPiece(
              key: ValueKey(ids[i]),
              controller: c,
              id: ids[i],
              size: height * 0.84,
            ),
          );
        },
      ),
    );
  }
}

class _TrayPiece extends StatelessWidget {
  const _TrayPiece({
    super.key,
    required this.controller,
    required this.id,
    required this.size,
  });

  final JigsawController controller;
  final int id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final img = c.cache[id];
    if (img == null) return SizedBox(width: size);
    final thumb = Center(
      child: SizedBox.square(
        dimension: size,
        child: RawImage(
          image: img,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
    final r = c.cache.localRect;
    final fw = r.width * c.scale, fh = r.height * c.scale;
    // Never let the dragged feedback be tiny on zoomed-out boards.
    final k = math.max(1.0, size * 0.8 / math.max(fw, fh));
    return Semantics(
      label: 'Puzzle piece',
      button: true,
      child: Draggable<int>(
        data: id,
        affinity: Axis.vertical,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => c.onPick?.call(),
        feedback: Transform.translate(
          offset: Offset(-fw * k / 2, -fh * k / 2),
          child: SizedBox(
            width: fw * k,
            height: fh * k,
            child: RawImage(image: img, fit: BoxFit.fill),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: thumb),
        child: GestureDetector(
          onTap: () => c.dropFromTrayAuto(id),
          child: thumb,
        ),
      ),
    );
  }
}
