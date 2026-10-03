import 'package:url_launcher/url_launcher.dart';

import '../../core/geo.dart';

/// Opens Google Maps (or any maps app) with a free directions URL. This is
/// handed to the other app; Beat Mitra itself makes no network request.
Future<bool> openInMaps(GeoPoint p) => launchUrl(
  Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}&travelmode=walking'),
  mode: LaunchMode.externalApplication,
);

Future<bool> callPhone(String phone) => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')));
