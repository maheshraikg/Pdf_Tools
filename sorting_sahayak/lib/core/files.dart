/// File picking, saving and sharing (Storage Access Framework / share sheet;
/// no storage permission, nothing uploaded).
library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class PickedFile {
  const PickedFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Lets the user pick a spreadsheet (.xlsx / .csv).
Future<PickedFile?> pickTableFile() async {
  final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['xlsx', 'csv', 'xlsm']);
  if (f == null) return null;
  return PickedFile(f.name, await f.xFile.readAsBytes());
}

/// Picks a CSV file and returns its local path (for large directory files).
Future<String?> pickCsvPath() async {
  final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['csv']);
  return f?.path;
}

String mimeFor(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.xlsx')) return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  if (n.endsWith('.csv')) return 'text/csv';
  if (n.endsWith('.png')) return 'image/png';
  return 'text/plain';
}

Uint8List _bytes(Object content) => content is Uint8List ? content : Uint8List.fromList(utf8.encode(content as String));

/// Shares files ({name: bytes or text}) through the Android share sheet.
Future<void> shareFiles(Map<String, Object> files, {String? text}) async {
  await SharePlus.instance.share(ShareParams(
    files: [for (final e in files.entries) XFile.fromData(_bytes(e.value), mimeType: mimeFor(e.key), name: e.key)],
    fileNameOverrides: files.keys.toList(),
    text: text,
  ));
}

Future<void> shareText(String text, {String? subject}) =>
    SharePlus.instance.share(ShareParams(text: text, subject: subject));

/// Saves bytes to a user-chosen location (e.g. Downloads).
Future<bool> saveBytes(String name, Object content) async {
  final uri = await FilePicker.saveFile(fileName: name, bytes: _bytes(content), mimeType: mimeFor(name));
  return uri != null;
}

/// Saves a bundled asset (templates / samples).
Future<bool> saveAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return saveBytes(assetPath.split('/').last, data.buffer.asUint8List());
}

Future<Uint8List> loadAssetBytes(String path) async => (await rootBundle.load(path)).buffer.asUint8List();
