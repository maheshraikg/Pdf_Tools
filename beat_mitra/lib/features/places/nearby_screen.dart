import 'package:flutter/material.dart';

import '../../core/geo.dart';
import '../../core/services/location_service.dart';
import '../../data/repos/place_repo.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';
import '../search/place_card.dart';

/// Saved places sorted by GPS distance (helps avoid duplicates and find
/// the house in front of you).
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with LiveLocation {
  List<NearbyPlace> _list = [];
  GeoPoint? _lastQueried;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    startLocation();
  }

  @override
  void onFix(GpsFix f) {
    // Re-query when we moved > 10 m.
    if (_lastQueried != null && haversineMeters(_lastQueried!, f.point) < 10) return;
    _lastQueried = f.point;
    _query(f.point);
  }

  Future<void> _query(GeoPoint p) async {
    final list = await context.services.places.nearby(
      p,
      beatId: context.app.activeBeat?.id,
      limit: 40,
      maxMeters: 1500,
    );
    if (mounted) {
      setState(() {
        _list = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.nearby)),
      body: fix == null
          ? EmptyState(icon: Icons.gps_not_fixed, text: l.gpsWaiting)
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
          ? EmptyState(icon: Icons.location_searching, text: l.noNearby)
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [for (final n in _list) PlaceCard(details: n.details, here: here, heading: heading)],
            ),
    );
  }
}
