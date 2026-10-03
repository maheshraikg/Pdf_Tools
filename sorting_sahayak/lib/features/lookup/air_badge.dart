import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../data/air_lookup.dart';

/// "✈ BLR / Bengaluru" for a PIN or PIN series, shown on line / bag cards.
class AirBadge extends StatefulWidget {
  const AirBadge({super.key, required this.lo, required this.hi, required this.foreground});

  final int lo;
  final int hi;
  final Color foreground;

  @override
  State<AirBadge> createState() => _AirBadgeState();
}

class _AirBadgeState extends State<AirBadge> {
  AreaAir? _air;
  String _for = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(AirBadge old) {
    super.didUpdateWidget(old);
    if (old.lo != widget.lo || old.hi != widget.hi) _load();
  }

  Future<void> _load() async {
    final services = context.services;
    final key = '${identityHashCode(services.active)}:${widget.lo}-${widget.hi}';
    if (key == _for) return;
    _for = key;
    final a = await airForRange(services.directory, services.active, widget.lo, widget.hi);
    if (mounted && key == _for) setState(() => _air = a);
  }

  @override
  Widget build(BuildContext context) {
    final a = _air;
    if (a == null) return const SizedBox.shrink();
    final fg = widget.foreground;
    return Container(
      key: ValueKey('air_${a.code}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flight, size: 20, color: fg),
              const SizedBox(width: 4),
              Text(a.code, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: fg, letterSpacing: 1)),
            ],
          ),
          if (a.city != a.code)
            Text(a.city, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}
