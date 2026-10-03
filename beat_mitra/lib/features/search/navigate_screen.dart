import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/geo.dart';
import '../../data/models.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';

/// Offline navigation: a big arrow from GPS bearing + compass heading,
/// distance in metres, photo and landmark. Vibrates within 20 m.
class NavigateScreen extends StatefulWidget {
  const NavigateScreen({super.key, required this.placeId});
  final int placeId;

  @override
  State<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends State<NavigateScreen> with LiveLocation {
  PlaceDetails? _d;
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    context.services.places.details(widget.placeId).then((d) {
      if (mounted) setState(() => _d = d);
    });
    startLocation();
  }

  @override
  void onFix(fix) {
    final p = _d?.place.point;
    if (p == null) return;
    final dist = haversineMeters(fix.point, p);
    if (dist <= 20 && !_arrived) {
      _arrived = true;
      if (context.services.settings.vibrateNear) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 250), HapticFeedback.heavyImpact);
      }
    } else if (dist > 35) {
      _arrived = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final d = _d;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final target = d?.place.point;
    final dist = (here != null && target != null) ? haversineMeters(here!, target) : null;
    final bearing = (here != null && target != null) ? bearingDegrees(here!, target) : null;
    final rel = bearing == null ? null : relativeBearing(bearing, heading ?? 0);

    return Scaffold(
      appBar: AppBar(title: Text(d?.title ?? l.navigate)),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : target == null
          ? EmptyState(icon: Icons.gps_off, text: l.placeHasNoGps)
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: dist == null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(l.gpsWaiting, style: t.titleLarge),
                              ],
                            )
                          : Semantics(
                              label: l.distanceAway(formatDistance(dist)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_arrived)
                                    Icon(Icons.where_to_vote, size: 200, color: Colors.green.shade600)
                                  else
                                    Transform.rotate(
                                      angle: rel! * math.pi / 180,
                                      child: Icon(Icons.navigation, size: 220, color: scheme.primary),
                                    ),
                                  Text(
                                    _arrived ? l.arrived : formatDistance(dist),
                                    style: t.displayMedium?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  if (heading == null)
                                    Text(l.noCompass, textAlign: TextAlign.center, style: t.bodyMedium),
                                  if (fix != null)
                                    Text(l.gpsAccuracyShort(fix!.accuracyM.round()), style: t.bodyMedium),
                                ],
                              ),
                            ),
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              PhotoThumb(d.photos.firstOrNull?.filePath, size: 110),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.title, style: t.titleLarge),
                                    if (d.place.landmark.isNotEmpty)
                                      Text('⚑ ${d.place.landmark}', style: t.titleMedium),
                                    if (d.addressees.isNotEmpty)
                                      Text(d.addressees.map((a) => a.name).join(', '), style: t.bodyLarge),
                                    if (d.place.notes.isNotEmpty)
                                      Text(d.place.notes, style: t.bodyLarge?.copyWith(color: scheme.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
