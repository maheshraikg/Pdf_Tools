/// Reads .xlsx / .csv files into plain string tables, and writes them back.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;

class TableFile {
  const TableFile(this.sheets);

  /// Sheet name → rows (CSV files have a single sheet named "CSV").
  final Map<String, List<List<String>>> sheets;

  List<String> get sheetNames => sheets.keys.toList();

  /// The first sheet that has at least two non-empty rows.
  String get defaultSheet =>
      sheets.entries.firstWhere((e) => e.value.where((r) => r.any((c) => c.isNotEmpty)).length >= 2,
          orElse: () => sheets.entries.first).key;
}

String _cellToString(xl.CellValue? v) {
  switch (v) {
    case null:
      return '';
    case xl.IntCellValue(:final value):
      return '$value';
    case xl.DoubleCellValue(:final value):
      // PINs typed as numbers come back as 574201.0.
      if (value == value.roundToDouble() && value.abs() < 1e15) return value.toInt().toString();
      return '$value';
    case xl.DateCellValue():
      return v.asDateTimeLocal().toIso8601String().substring(0, 10);
    case xl.DateTimeCellValue():
      return v.asDateTimeLocal().toIso8601String().substring(0, 10);
    case xl.TextCellValue(:final value):
      return (value.text ?? value.toString()).trim();
    case xl.FormulaCellValue(:final formula):
      return formula;
    default:
      return v.toString().trim();
  }
}

/// Decodes [bytes] according to the file extension of [fileName].
TableFile readTable(Uint8List bytes, String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.xlsx') || lower.endsWith('.xlsm')) {
    final book = xl.Excel.decodeBytes(bytes);
    final sheets = <String, List<List<String>>>{};
    for (final name in book.tables.keys) {
      final rows = book.tables[name]!.rows
          .map((r) => r.map((c) => _cellToString(c?.value)).toList())
          .toList();
      sheets[name] = _trimTable(rows);
    }
    if (sheets.isEmpty) throw const FormatException('The workbook has no sheets.');
    return TableFile(sheets);
  }
  if (lower.endsWith('.xls')) {
    throw const FormatException('Old .xls files are not supported. Save as .xlsx or .csv and try again.');
  }
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('﻿')) text = text.substring(1);
  final rows = Csv().decode(text).map((r) => r.map((c) => '${c ?? ''}'.trim()).toList()).toList();
  return TableFile({'CSV': _trimTable(rows)});
}

/// Drops trailing empty rows / columns and pads rows to equal length.
List<List<String>> _trimTable(List<List<String>> rows) {
  var out = rows.toList();
  while (out.isNotEmpty && out.last.every((c) => c.isEmpty)) {
    out.removeLast();
  }
  var width = 0;
  for (final r in out) {
    for (var i = r.length - 1; i >= 0; i--) {
      if (r[i].isNotEmpty) {
        if (i + 1 > width) width = i + 1;
        break;
      }
    }
  }
  out = [for (final r in out) List.generate(width, (i) => i < r.length ? r[i] : '')];
  return out;
}

/// Writes [sheets] to .xlsx bytes. Numeric-looking PIN columns are written
/// as text so Excel does not reformat them.
Uint8List writeXlsx(Map<String, List<List<String>>> sheets) {
  final book = xl.Excel.createExcel();
  final defaultName = book.getDefaultSheet() ?? 'Sheet1';
  var first = true;
  for (final e in sheets.entries) {
    final name = e.key;
    if (first) {
      book.rename(defaultName, name);
      book.setDefaultSheet(name);
      first = false;
    }
    final sheet = book[name];
    for (final row in e.value) {
      sheet.appendRow([for (final c in row) xl.TextCellValue(c)]);
    }
  }
  return Uint8List.fromList(book.encode()!);
}

/// CSV with \n line endings and a UTF-8 BOM so Excel opens Kannada/Hindi
/// text correctly.
String writeCsv(List<List<String>> rows) => '﻿${Csv(lineDelimiter: '\n').encode(rows)}';
