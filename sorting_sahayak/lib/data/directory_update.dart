/// "Update PIN directory": rebuilds the directory DB from a newer
/// data.gov.in CSV picked by the user. Parsing/cleaning runs in a background
/// isolate; inserts run through sqflite (native thread). Progress is
/// reported as 0..1.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:sqflite_common/sqlite_api.dart';

import 'directory_builder.dart';

class DirectoryUpdateProgress {
  const DirectoryUpdateProgress(this.stage, this.progress, {this.rows, this.error});

  /// 'parse', 'write', 'done', 'error'
  final String stage;
  final double progress;
  final int? rows;
  final String? error;
}

/// Parses [csvPath] in a background isolate, streaming progress and finally
/// the cleaned records (as plain lists, cheap to send between isolates).
Stream<Object> _parseInIsolate(String csvPath, String? state) {
  final port = ReceivePort();
  final controller = StreamController<Object>();
  Isolate.spawn<List<Object?>>((args) async {
    final send = args[0] as SendPort;
    try {
      final content = await File(args[1] as String).readAsString();
      final recs = parseDirectoryCsv(content, stateFilter: args[2] as String?, onProgress: (p) => send.send(p));
      send.send(recs.map((r) => r.toList()).toList());
    } on Object catch (e) {
      send.send('ERROR: $e');
    }
  }, [port.sendPort, csvPath, state]);
  port.listen((msg) {
    controller.add(msg as Object);
    if (msg is List || (msg is String && msg.startsWith('ERROR'))) {
      port.close();
      controller.close();
    }
  });
  return controller.stream;
}

/// Builds a new directory DB at [targetPath] from [csvPath]. The caller
/// opens it via [openDb] (sqflite in the app, ffi in tests) and swaps it in.
Stream<DirectoryUpdateProgress> buildDirectoryFromCsv({
  required String csvPath,
  required String targetPath,
  required Future<Database> Function(String path) openDb,
  String? stateFilter,
}) async* {
  List<OfficeRecord>? records;
  await for (final msg in _parseInIsolate(csvPath, stateFilter)) {
    if (msg is double) {
      yield DirectoryUpdateProgress('parse', msg * 0.4);
    } else if (msg is String) {
      yield DirectoryUpdateProgress('error', 0, error: msg.substring(7));
      return;
    } else if (msg is List) {
      records = [for (final l in msg) OfficeRecord.fromList((l as List).cast<Object?>())];
    }
  }
  if (records == null || records.isEmpty) {
    yield const DirectoryUpdateProgress('error', 0, error: 'No valid rows found in the CSV.');
    return;
  }
  final tmp = File(targetPath);
  if (tmp.existsSync()) tmp.deleteSync();
  final db = await openDb(targetPath);
  final progress = StreamController<double>();
  final done = writeDirectoryDb(
    db,
    records,
    meta: {
      'source': 'All India Pincode Directory, data.gov.in (OGDL) – imported by user',
      'file_date': File(csvPath).lastModifiedSync().toIso8601String().substring(0, 10),
      'built_at': DateTime.now().toIso8601String().substring(0, 10),
      'state_filter': stateFilter ?? '',
    },
    onProgress: progress.add,
  ).whenComplete(progress.close);
  await for (final p in progress.stream) {
    yield DirectoryUpdateProgress('write', 0.4 + p * 0.6);
  }
  await done;
  await db.close();
  yield DirectoryUpdateProgress('done', 1, rows: records.length);
}
