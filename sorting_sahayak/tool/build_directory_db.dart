// Converts the data.gov.in "All India Pincode Directory" CSV into the SQLite
// database bundled with the app.
//
//   dart run tool/build_directory_db.dart \
//       [--input data/pincode_directory.csv] \
//       [--output assets/db/pincode_directory.db] \
//       [--state Karnataka] [--no-fts]
//
// Uses sqflite_common_ffi (desktop SQLite), so it runs without a device.
import 'dart:io';

import 'package:sorting_sahayak/data/directory_builder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> args) async {
  String opt(String name, String def) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : def;
  }

  final input = opt('input', 'data/pincode_directory.csv');
  final output = opt('output', 'assets/db/pincode_directory.db');
  final state = opt('state', '');
  final fts = !args.contains('--no-fts');

  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('Missing $input.\n'
        'Download "All India Pincode Directory" (CSV) from\n'
        '  https://www.data.gov.in/resource/all-india-pincode-directory-till-last-month\n'
        'and save it as $input.');
    exit(2);
  }
  stdout.writeln('Reading $input …');
  final content = await file.readAsString();
  final records = parseDirectoryCsv(
    content,
    stateFilter: state.isEmpty ? null : state,
    onProgress: (p) => stdout.write('\r  cleaning ${(p * 100).toStringAsFixed(0)}%   '),
  );
  stdout.writeln('\n  ${records.length} unique offices${state.isEmpty ? '' : ' in $state'}');

  final out = File(output);
  if (out.existsSync()) out.deleteSync();
  out.parent.createSync(recursive: true);
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(out.absolute.path);
  final modified = file.lastModifiedSync().toIso8601String().substring(0, 10);
  final hasFts = await writeDirectoryDb(
    db,
    records,
    tryFts: fts,
    meta: {
      'source': opt('source', 'All India Pincode Directory, data.gov.in (OGDL)'),
      'file_date': modified,
      'built_at': DateTime.now().toIso8601String().substring(0, 10),
      'state_filter': state,
    },
    onProgress: (p) => stdout.write('\r  writing ${(p * 100).toStringAsFixed(0)}%   '),
  );
  await db.execute('VACUUM');
  await db.close();
  final size = out.lengthSync() / (1024 * 1024);
  stdout.writeln('\nWrote $output (${size.toStringAsFixed(1)} MB, FTS5: ${hasFts ? 'yes' : 'no'})');
}
