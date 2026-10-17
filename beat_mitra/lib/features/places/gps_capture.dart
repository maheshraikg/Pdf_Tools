import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/location_service.dart';
import '../common/widgets.dart';

/// Live GPS reading with accuracy. Calls [onAccept] automatically once the
/// accuracy is within [thresholdM] (if [autoAccept]) or when the user taps
/// "Use this location".
class GpsCaptureCard extends StatefulWidget {
  const GpsCaptureCard({
    super.key,
    required this.thresholdM,
    required this.onAccept,
    this.autoAccept = true,
    this.accepted,
  });
  final int thresholdM;
  final ValueChanged<GpsFix> onAccept;
  final bool autoAccept;
  final GpsFix? accepted;

  @override
  State<GpsCaptureCard> createState() => _GpsCaptureCardState();
}

class _GpsCaptureCardState extends State<GpsCaptureCard> {
  StreamSubscription<GpsFix>? _sub;
  GpsFix? _fix;
  LocationProblem _problem = LocationProblem.none;
  bool _listening = false;
  bool _autoDone = false;

  @override
  void initState() {
    super.initState();
    if (widget.accepted == null) WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final loc = context.services.location;
    final p = await loc.ensurePermission();
    if (!mounted) return;
    setState(() {
      _problem = p;
      _listening = p == LocationProblem.none;
    });
    if (p != LocationProblem.none) return;
    await _sub?.cancel();
    _sub = loc.fixes().listen((f) {
      if (!mounted) return;
      setState(() => _fix = f);
      if (widget.autoAccept && !_autoDone && f.accuracyM <= widget.thresholdM) {
        _autoDone = true;
        HapticFeedback.mediumImpact();
        _accept(f);
      }
    });
  }

  void _accept(GpsFix f) {
    widget.onAccept(f);
    _sub?.cancel();
    setState(() => _listening = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final acc = widget.accepted;
    if (_problem != LocationProblem.none) {
      return Card(
        color: scheme.errorContainer,
        child: ListTile(
          leading: const Icon(Icons.location_off, size: 32),
          title: Text(_problem == LocationProblem.serviceOff ? l.gpsOff : l.gpsDenied),
          trailing: TextButton(
            onPressed: () async {
              await context.services.location.openSettings();
              _start();
            },
            child: Text(l.openSettings),
          ),
        ),
      );
    }
    if (acc != null && !_listening) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.gps_fixed, color: Colors.green.shade700, size: 32),
          title: Text(l.gpsSaved(acc.accuracyM.round())),
          subtitle: Text('${acc.point.lat.toStringAsFixed(5)}, ${acc.point.lng.toStringAsFixed(5)}'),
          trailing: TextButton(onPressed: _start, child: Text(l.gpsRetake)),
        ),
      );
    }
    if (!_listening) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.gps_not_fixed, size: 32),
          title: Text(l.gpsNotSet),
          trailing: FilledButton.tonal(onPressed: _start, child: Text(l.gpsCapture)),
        ),
      );
    }
    final f = _fix;
    final good = f != null && f.accuracyM <= widget.thresholdM;
    return Card(
      color: good ? Colors.green.shade50 : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    f == null ? l.gpsWaiting : l.gpsAccuracy(f.accuracyM.round(), widget.thresholdM),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: good ? Colors.black : null),
                  ),
                ),
              ],
            ),
            if (f != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(onPressed: () => _accept(f), icon: const Icon(Icons.check), label: Text(l.gpsUseNow)),
            ],
          ],
        ),
      ),
    );
  }
}
