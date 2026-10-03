import 'dart:math' as math;

import 'package:sqflite_common/sqlite_api.dart';

import '../../core/fuzzy.dart';
import '../../core/geo.dart';
import '../models.dart';

class NearbyPlace {
  NearbyPlace(this.details, this.distanceM);
  final PlaceDetails details;
  final double distanceM;
}

class PlaceRepo {
  PlaceRepo(this.db);
  final Database db;

  Future<int> savePlace(Place p) async {
    final m = p.toMap()..remove('id');
    if (p.id == null) return db.insert('places', m);
    await db.update('places', m, where: 'id = ?', whereArgs: [p.id]);
    return p.id!;
  }

  Future<void> deletePlace(int id) => db.delete('places', where: 'id = ?', whereArgs: [id]);

  Future<Place?> place(int id) async {
    final r = await db.query('places', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Place.fromMap(r.first);
  }

  Future<int> countPlaces({int? beatId}) async {
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM places${beatId != null ? ' WHERE beat_id = ?' : ''}', [
      ?beatId,
    ]);
    return r.first['c'] as int;
  }

  // ---- Addressees ----

  Future<List<Addressee>> addressees(int placeId) async => (await db.query(
    'addressees',
    where: 'place_id = ?',
    whereArgs: [placeId],
    orderBy: 'id',
  )).map(Addressee.fromMap).toList();

  /// Replaces the addressee list of a place.
  Future<void> setAddressees(int placeId, List<Addressee> list) async {
    await db.transaction((t) async {
      final keepIds = list.where((a) => a.id != null).map((a) => a.id!).toList();
      if (keepIds.isEmpty) {
        await t.delete('addressees', where: 'place_id = ?', whereArgs: [placeId]);
      } else {
        await t.delete(
          'addressees',
          where: 'place_id = ? AND id NOT IN (${List.filled(keepIds.length, '?').join(',')})',
          whereArgs: [placeId, ...keepIds],
        );
      }
      for (final a in list) {
        final m = a.copyWith(placeId: placeId).toMap()..remove('id');
        if (a.id == null) {
          await t.insert('addressees', m);
        } else {
          await t.update('addressees', m, where: 'id = ?', whereArgs: [a.id]);
        }
      }
    });
  }

  // ---- Photos ----

  Future<List<PlacePhoto>> photos(int placeId) async => (await db.query(
    'place_photos',
    where: 'place_id = ?',
    whereArgs: [placeId],
    orderBy: 'id',
  )).map(PlacePhoto.fromMap).toList();

  Future<int> addPhoto(PlacePhoto p) => db.insert('place_photos', p.toMap()..remove('id'));

  Future<void> deletePhoto(int id) => db.delete('place_photos', where: 'id = ?', whereArgs: [id]);

  Future<List<String>> allPhotoFiles() async =>
      (await db.query('place_photos', columns: ['file_path'])).map((r) => r['file_path'] as String).toList();

  // ---- Details ----

  Future<PlaceDetails?> details(int id) async {
    final list = await detailsWhere('p.id = ?', [id]);
    return list.isEmpty ? null : list.first;
  }

  Future<List<PlaceDetails>> detailsForIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final out = <PlaceDetails>[];
    // SQLite variable limit: chunk.
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, math.min(ids.length, i + 500));
      out.addAll(await detailsWhere('p.id IN (${List.filled(chunk.length, '?').join(',')})', chunk));
    }
    final byId = {for (final d in out) d.place.id!: d};
    return [for (final id in ids) ?byId[id]];
  }

  Future<List<PlaceDetails>> allDetails({int? beatId}) =>
      beatId == null ? detailsWhere('1 = 1', []) : detailsWhere('p.beat_id = ?', [beatId]);

  /// Loads places with their street, addressees and photos in four queries.
  Future<List<PlaceDetails>> detailsWhere(String where, List<Object?> args) async {
    final rows = await db.rawQuery('SELECT p.* FROM places p WHERE $where', args);
    if (rows.isEmpty) return [];
    final places = rows.map(Place.fromMap).toList();
    final placeIds = places.map((p) => p.id!).toSet();
    final streetIds = places.map((p) => p.streetId).whereType<int>().toSet();

    final streets = <int, Street>{};
    if (streetIds.isNotEmpty) {
      for (final r in await db.query(
        'streets',
        where: 'id IN (${List.filled(streetIds.length, '?').join(',')})',
        whereArgs: streetIds.toList(),
      )) {
        final s = Street.fromMap(r);
        streets[s.id!] = s;
      }
    }
    final addr = <int, List<Addressee>>{};
    final photos = <int, List<PlacePhoto>>{};
    final allIds = placeIds.length > 500 ? null : placeIds.toList();
    final inClause = allIds == null ? '' : ' WHERE place_id IN (${List.filled(allIds.length, '?').join(',')})';
    for (final r in await db.rawQuery('SELECT * FROM addressees$inClause ORDER BY id', allIds ?? [])) {
      final a = Addressee.fromMap(r);
      if (placeIds.contains(a.placeId)) addr.putIfAbsent(a.placeId, () => []).add(a);
    }
    for (final r in await db.rawQuery('SELECT * FROM place_photos$inClause ORDER BY id', allIds ?? [])) {
      final ph = PlacePhoto.fromMap(r);
      if (placeIds.contains(ph.placeId)) photos.putIfAbsent(ph.placeId, () => []).add(ph);
    }
    return [
      for (final p in places)
        PlaceDetails(
          place: p,
          street: p.streetId == null ? null : streets[p.streetId],
          addressees: addr[p.id] ?? const [],
          photos: photos[p.id] ?? const [],
        ),
    ];
  }

  /// Saved places sorted by distance from [here] (only places with GPS).
  Future<List<NearbyPlace>> nearby(GeoPoint here, {int? beatId, int limit = 30, double maxMeters = 2000}) async {
    // Bounding-box prefilter, then exact haversine.
    final dLat = maxMeters / 111320.0;
    final dLng = maxMeters / (111320.0 * math.max(0.1, math.cos(here.lat * math.pi / 180)));
    final where = StringBuffer('p.lat BETWEEN ? AND ? AND p.lng BETWEEN ? AND ?');
    final args = <Object?>[here.lat - dLat, here.lat + dLat, here.lng - dLng, here.lng + dLng];
    if (beatId != null) {
      where.write(' AND p.beat_id = ?');
      args.add(beatId);
    }
    final list = await detailsWhere(where.toString(), args);
    final out = [for (final d in list) NearbyPlace(d, haversineMeters(here, d.place.point!))]
      ..sort((a, b) => a.distanceM.compareTo(b.distanceM));
    return out.length > limit ? out.sublist(0, limit) : out;
  }

  /// Saves the manual order of places (inside one street) for next time.
  Future<void> saveWalkOrder(List<int> placeIdsInOrder) async {
    final b = db.batch();
    for (var i = 0; i < placeIdsInOrder.length; i++) {
      b.update('places', {'walk_order': i}, where: 'id = ?', whereArgs: [placeIdsInOrder[i]]);
    }
    await b.commit(noResult: true);
  }

  /// Merges [dropId] into [keepId]: addressees (de-duplicated), photos,
  /// articles and learn progress move over; empty fields are filled in.
  Future<void> merge({required int keepId, required int dropId}) async {
    if (keepId == dropId) return;
    await db.transaction((t) async {
      final keepRows = await t.query('places', where: 'id = ?', whereArgs: [keepId]);
      final dropRows = await t.query('places', where: 'id = ?', whereArgs: [dropId]);
      if (keepRows.isEmpty || dropRows.isEmpty) return;
      final keep = Place.fromMap(keepRows.first);
      final drop = Place.fromMap(dropRows.first);
      String pick(String a, String b) => a.isNotEmpty ? a : b;
      String joinNotes(String a, String b) => a.isEmpty ? b : (b.isEmpty || a.contains(b) ? a : '$a\n$b');
      final betterGps =
          keep.lat == null || (drop.lat != null && (drop.gpsAccuracyM ?? 999) < (keep.gpsAccuracyM ?? 999));
      final merged = Place(
        id: keep.id,
        beatId: keep.beatId,
        streetId: keep.streetId ?? drop.streetId,
        doorNo: pick(keep.doorNo, drop.doorNo),
        building: pick(keep.building, drop.building),
        floorFlat: pick(keep.floorFlat, drop.floorFlat),
        area: pick(keep.area, drop.area),
        pin: pick(keep.pin, drop.pin),
        landmark: pick(keep.landmark, drop.landmark),
        lat: betterGps ? drop.lat : keep.lat,
        lng: betterGps ? drop.lng : keep.lng,
        gpsAccuracyM: betterGps ? drop.gpsAccuracyM : keep.gpsAccuracyM,
        type: keep.type,
        notes: joinNotes(keep.notes, drop.notes),
        deliveryPref: pick(keep.deliveryPref, drop.deliveryPref),
        walkOrder: keep.walkOrder ?? drop.walkOrder,
        createdAt: math.min(keep.createdAt, drop.createdAt),
      );
      await t.update('places', merged.toMap()..remove('id'), where: 'id = ?', whereArgs: [keepId]);

      final keepNames = (await t.query(
        'addressees',
        columns: ['name_norm'],
        where: 'place_id = ?',
        whereArgs: [keepId],
      )).map((r) => r['name_norm'] as String).toSet();
      for (final r in await t.query('addressees', where: 'place_id = ?', whereArgs: [dropId])) {
        if (keepNames.contains(r['name_norm'])) {
          await t.delete('addressees', where: 'id = ?', whereArgs: [r['id']]);
        } else {
          await t.update('addressees', {'place_id': keepId}, where: 'id = ?', whereArgs: [r['id']]);
        }
      }
      await t.update('place_photos', {'place_id': keepId}, where: 'place_id = ?', whereArgs: [dropId]);
      await t.update('articles', {'place_id': keepId}, where: 'place_id = ?', whereArgs: [dropId]);
      await t.delete('learn_progress', where: 'place_id = ?', whereArgs: [dropId]);
      await t.delete('places', where: 'id = ?', whereArgs: [dropId]);
    });
  }

  /// Search documents for the fuzzy index.
  Future<List<SearchDoc>> searchDocs({int? beatId}) async =>
      (await allDetails(beatId: beatId)).map(searchDocFor).toList();
}

SearchDoc searchDocFor(PlaceDetails d) {
  final p = d.place;
  return SearchDoc(
    id: p.id!,
    fields: {
      'name': d.addressees.map((a) => '${a.name} ${a.aliases.replaceAll(',', ' ')}').join(' '),
      'door': p.doorNo,
      'building': '${p.building} ${p.floorFlat}',
      'street': '${d.street?.name ?? ''} ${d.street?.crossMainNote ?? ''}',
      'landmark': p.landmark,
      'area': '${p.area} ${d.street?.area ?? ''}',
      'pin': p.pin,
      'notes': p.notes,
    },
  );
}
