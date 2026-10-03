import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../core/crypto.dart';
import '../core/services/photo_store.dart';
import 'db.dart';
import 'models.dart';
import 'repos/beat_repo.dart';
import 'repos/place_repo.dart';

const int backupFormat = 1;

enum ExportKind { handover, fullBackup }

class ImportResult {
  ImportResult(this.beats, this.places, this.photos, this.articles);
  final int beats;
  final int places;
  final int photos;
  final int articles;
}

class BadBackupException implements Exception {}

/// Builds and reads ".beatmitra" files: a zip (data.json + photos) that is
/// then encrypted with AES-256-GCM using a key derived from a password
/// (PBKDF2-HMAC-SHA256). See core/crypto.dart.
class BackupCodec {
  BackupCodec(this.db, this.photos);
  final Database db;
  final PhotoStore photos;

  BeatRepo get _beats => BeatRepo(db);
  PlaceRepo get _places => PlaceRepo(db);

  /// Zip bytes for [beatIds] (or all beats for a full backup).
  Future<Uint8List> buildZip({
    required ExportKind kind,
    List<int>? beatIds,
    bool includePhones = true,
    bool includePhotos = true,
  }) async {
    final archive = Archive();
    final beats = (await _beats.beats()).where((b) => beatIds == null || beatIds.contains(b.id)).toList();
    final beatsJson = <Map<String, Object?>>[];
    for (final b in beats) {
      final places = await _places.allDetails(beatId: b.id);
      final placesJson = <Map<String, Object?>>[];
      for (final d in places) {
        final photoNames = <String>[];
        if (includePhotos) {
          for (final ph in d.photos) {
            final bytes = await photos.load(ph.filePath);
            if (bytes == null) continue;
            final name = 'photos/${ph.id}.jpg';
            archive.addFile(ArchiveFile.bytes(name, bytes));
            photoNames.add(name);
          }
        }
        placesJson.add({
          'place': d.place.toMap(),
          'addressees': [for (final a in d.addressees) (includePhones ? a : a.copyWith(phone: '')).toMap()],
          'photos': photoNames,
        });
      }
      beatsJson.add({
        'beat': b.toMap(),
        'streets': [for (final s in await _beats.streets(b.id!)) s.toMap()],
        'area_notes': [for (final n in await _beats.areaNotes(b.id!)) n.toMap()],
        'places': placesJson,
      });
    }
    final data = <String, Object?>{
      'format': backupFormat,
      'kind': kind.name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'beats': beatsJson,
    };
    if (kind == ExportKind.fullBackup) {
      data['articles'] = await db.query('articles');
      data['learn_progress'] = await db.query('learn_progress');
      data['day_log'] = await db.query('day_log');
    }
    archive.addFile(ArchiveFile.string('data.json', jsonEncode(data)));
    return ZipEncoder().encodeBytes(archive);
  }

  Future<Uint8List> export({
    required String password,
    required ExportKind kind,
    List<int>? beatIds,
    bool includePhones = true,
    int iterations = defaultPbkdf2Iterations,
  }) async {
    final zip = await buildZip(kind: kind, beatIds: beatIds, includePhones: includePhones);
    return encryptWithPassword(zip, password, iterations: iterations);
  }

  /// Decrypts [file] and returns its kind (throws [WrongPasswordException]).
  static Future<(ExportKind, Archive)> open(Uint8List file, String password) async {
    final zip = await decryptWithPassword(file, password);
    final archive = ZipDecoder().decodeBytes(zip);
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) throw BadBackupException();
    final data = jsonDecode(utf8.decode(dataFile.content)) as Map<String, Object?>;
    final kind = data['kind'] == ExportKind.fullBackup.name ? ExportKind.fullBackup : ExportKind.handover;
    return (kind, archive);
  }

  /// Imports an opened archive. A handover adds its beats as new beats.
  /// With [replaceAll] (full restore) every existing row is deleted first.
  Future<ImportResult> import(Archive archive, {bool replaceAll = false}) async {
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) throw BadBackupException();
    final data = jsonDecode(utf8.decode(dataFile.content)) as Map<String, Object?>;
    if ((data['format'] as int? ?? 0) > backupFormat) throw BadBackupException();

    if (replaceAll) {
      for (final f in await _places.allPhotoFiles()) {
        await photos.delete(f);
      }
      await AppDatabase(db).wipe();
    }

    // Save photos first (outside the DB transaction: they are files).
    final photoMap = <String, String>{};
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('photos/')) {
        photoMap[f.name] = await photos.saveBytes(Uint8List.fromList(f.content));
      }
    }

    var nBeats = 0, nPlaces = 0, nPhotos = 0, nArticles = 0;
    final placeIdMap = <int, int>{};
    await db.transaction((t) async {
      for (final bj in (data['beats'] as List).cast<Map<String, Object?>>()) {
        final beatMap = Map<String, Object?>.from(bj['beat'] as Map)..remove('id');
        final beatId = await t.insert('beats', beatMap);
        nBeats++;
        final streetIdMap = <int, int>{};
        for (final sj in (bj['streets'] as List).cast<Map<String, Object?>>()) {
          final m = Map<String, Object?>.from(sj);
          final oldId = m.remove('id') as int;
          m['beat_id'] = beatId;
          streetIdMap[oldId] = await t.insert('streets', m);
        }
        for (final nj in (bj['area_notes'] as List).cast<Map<String, Object?>>()) {
          final m = Map<String, Object?>.from(nj)..remove('id');
          m['beat_id'] = beatId;
          await t.insert('area_notes', m);
        }
        for (final pj in (bj['places'] as List).cast<Map<String, Object?>>()) {
          final m = Map<String, Object?>.from(pj['place'] as Map);
          final oldId = m.remove('id') as int;
          m['beat_id'] = beatId;
          final sid = m['street_id'] as int?;
          m['street_id'] = sid == null ? null : streetIdMap[sid];
          final pid = await t.insert('places', m);
          placeIdMap[oldId] = pid;
          nPlaces++;
          for (final aj in (pj['addressees'] as List).cast<Map<String, Object?>>()) {
            final am = Map<String, Object?>.from(aj)..remove('id');
            am['place_id'] = pid;
            await t.insert('addressees', am);
          }
          for (final name in (pj['photos'] as List).cast<String>()) {
            final stored = photoMap[name];
            if (stored == null) continue;
            await t.insert('place_photos', PlacePhoto(placeId: pid, filePath: stored).toMap()..remove('id'));
            nPhotos++;
          }
        }
      }
      for (final aj in ((data['articles'] as List?) ?? const []).cast<Map<String, Object?>>()) {
        final m = Map<String, Object?>.from(aj)..remove('id');
        final pid = m['place_id'] as int?;
        m['place_id'] = pid == null ? null : placeIdMap[pid];
        await t.insert('articles', m);
        nArticles++;
      }
      for (final lj in ((data['learn_progress'] as List?) ?? const []).cast<Map<String, Object?>>()) {
        final pid = placeIdMap[lj['place_id'] as int];
        if (pid == null) continue;
        await t.insert('learn_progress', {...lj, 'place_id': pid}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final dj in ((data['day_log'] as List?) ?? const []).cast<Map<String, Object?>>()) {
        await t.insert('day_log', dj, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return ImportResult(nBeats, nPlaces, nPhotos, nArticles);
  }
}
