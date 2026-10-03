import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/geo.dart';
import '../../core/services/location_service.dart';
import 'widgets.dart';

/// Mixin for screens that show distance / direction: listens to GPS and
/// compass while the screen is visible.
mixin LiveLocation<T extends StatefulWidget> on State<T> {
  StreamSubscription<GpsFix>? _gpsSub;
  StreamSubscription<double?>? _headSub;
  GpsFix? fix;
  double? heading;

  GeoPoint? get here => fix?.point;

  /// Called on every GPS update.
  void onFix(GpsFix f) {}

  void startLocation() {
    final loc = context.services.location;
    _gpsSub = loc.fixes().listen((f) {
      if (!mounted) return;
      setState(() => fix = f);
      onFix(f);
    });
    _headSub = loc.heading().listen((h) {
      if (!mounted || h == null) return;
      // Ignore tiny changes to avoid rebuilding every frame.
      if (heading != null && ((h - heading!).abs() % 360) < 3) return;
      setState(() => heading = h);
    });
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _headSub?.cancel();
    super.dispose();
  }
}
