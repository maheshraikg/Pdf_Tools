import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/geo.dart';
import '../../data/models.dart';
import '../common/widgets.dart';
import '../places/place_actions.dart';
import '../places/place_detail_screen.dart';
import '../places/place_edit_screen.dart';
import 'navigate_screen.dart';

/// Result card: photo, door no., street, landmark, names, notes, distance
/// and direction arrow, and big action buttons.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.details, this.here, this.heading, this.onPick, this.pickLabel});
  final PlaceDetails details;
  final GeoPoint? here;
  final double? heading;

  /// When set the card is used as a picker (e.g. to match an article).
  final VoidCallback? onPick;
  final String? pickLabel;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final p = details.place;
    final t = Theme.of(context).textTheme;
    final point = p.point;
    final dist = (here != null && point != null) ? haversineMeters(here!, point) : null;
    final bearing = (here != null && point != null) ? bearingDegrees(here!, point) : null;
    final phone = details.addressees.map((a) => a.phone).firstWhere((x) => x.isNotEmpty, orElse: () => '');
    final names = details.addressees.map((a) => a.name).join(', ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onPick ??
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: p.id!))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoThumb(details.photos.firstOrNull?.filePath, size: 84),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.doorNo.isEmpty ? (p.building.isEmpty ? '—' : p.building) : p.doorNo,
                          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (details.streetName.isNotEmpty)
                          Text(details.streetName, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (p.building.isNotEmpty && p.doorNo.isNotEmpty)
                          Text('${p.building} ${p.floorFlat}'.trim(), style: t.bodyMedium),
                        if (p.landmark.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.flag_outlined, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  p.landmark,
                                  style: t.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (dist != null)
                    Semantics(
                      label: l.distanceAway(formatDistance(dist)),
                      child: Column(
                        children: [
                          Transform.rotate(
                            angle: (relativeBearing(bearing!, heading ?? 0)) * math.pi / 180,
                            child: Icon(
                              heading == null ? Icons.navigation_outlined : Icons.navigation,
                              size: 36,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(formatDistance(dist), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(names, style: t.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              if (p.notes.isNotEmpty || p.deliveryPref.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [p.notes, p.deliveryPref].where((x) => x.isNotEmpty).join(' · '),
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              if (onPick != null)
                FilledButton.icon(onPressed: onPick, icon: const Icon(Icons.check), label: Text(pickLabel ?? l.select))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (point != null)
                      FilledButton.icon(
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => NavigateScreen(placeId: p.id!))),
                        icon: const Icon(Icons.explore),
                        label: Text(l.navigate),
                      ),
                    if (point != null)
                      OutlinedButton.icon(
                        onPressed: () => openInMaps(point),
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l.googleMaps),
                      ),
                    if (phone.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => callPhone(phone),
                        icon: const Icon(Icons.call),
                        label: Text(l.call),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceEditScreen(beatId: p.beatId, placeId: p.id),
                        ),
                      ),
                      icon: const Icon(Icons.edit),
                      label: Text(l.edit),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
