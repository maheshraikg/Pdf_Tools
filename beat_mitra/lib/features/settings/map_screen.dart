import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';
import '../places/place_detail_screen.dart';

/// The "map" build flavor has the INTERNET permission; the default
/// "offline" build has none, so the map cannot load there.
final bool mapAvailableInBuild = appFlavor == 'map';

/// Optional OpenStreetMap view (OFF by default). Follows the OSM tile usage
/// policy: visible attribution, an identifying User-Agent, normal browsing
/// only, no bulk or offline tile downloading.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with LiveLocation {
  List<PlaceDetails> _places = [];

  @override
  void initState() {
    super.initState();
    final beat = context.app.activeBeat;
    context.services.places.allDetails(beatId: beat?.id).then((p) {
      if (mounted) setState(() => _places = p.where((d) => d.place.point != null).toList());
    });
    startLocation();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final pts = _places.map((d) => LatLng(d.place.lat!, d.place.lng!)).toList();
    final center = here != null
        ? LatLng(here!.lat, here!.lng)
        : (pts.isNotEmpty ? pts.first : const LatLng(12.9716, 77.5946));
    return Scaffold(
      appBar: AppBar(title: Text(l.map)),
      body: !mapAvailableInBuild
          ? EmptyState(icon: Icons.cloud_off, text: l.mapNotInBuild)
          : FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 17, maxZoom: 19, minZoom: 3),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.beatmitra.beat_mitra',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    for (final d in _places)
                      Marker(
                        point: LatLng(d.place.lat!, d.place.lng!),
                        width: 120,
                        height: 56,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: d.place.id!)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                color: Colors.white.withValues(alpha: 0.85),
                                child: Text(
                                  d.place.doorNo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Icon(Icons.location_on, color: Color(0xFFC62828), size: 32),
                            ],
                          ),
                        ),
                      ),
                    if (here != null)
                      Marker(
                        point: LatLng(here!.lat, here!.lng),
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
                // Always-visible attribution as the policy asks.
                const Align(
                  alignment: Alignment.bottomRight,
                  child: ColoredBox(
                    color: Color(0xCCFFFFFF),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text('© OpenStreetMap contributors', style: TextStyle(color: Colors.black, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
