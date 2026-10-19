import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/charts.dart';

Future<List<ChartPlace>>? _charts;

/// The bundled Azan Time Charts; empty when the app is built without them.
Future<List<ChartPlace>> loadCharts() => _charts ??= () async {
  try {
    final data = await rootBundle.load('assets/charts.tsv.gz');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return await compute(_parse, bytes);
  } catch (_) {
    return const <ChartPlace>[];
  }
}();

List<ChartPlace> _parse(Uint8List bytes) =>
    parseCharts(utf8.decode(gzip.decode(bytes)));

/// Forgets the loaded charts (tests load them outside the fake-async zone).
void debugResetCharts() => _charts = null;
