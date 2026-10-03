import 'package:beat_mitra/core/geo.dart';
import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/data/repos/article_repo.dart';
import 'package:beat_mitra/data/repos/beat_repo.dart';
import 'package:beat_mitra/data/repos/learn_repo.dart';
import 'package:beat_mitra/data/repos/place_repo.dart';
import 'package:beat_mitra/core/fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_db.dart';

void main() {
  late BeatRepo beats;
  late PlaceRepo places;
  late ArticleRepo articles;
  late LearnRepo learn;
  late int beatId;

  setUp(() async {
    final db = await openTestDatabase();
    beats = BeatRepo(db.db);
    places = PlaceRepo(db.db);
    articles = ArticleRepo(db.db);
    learn = LearnRepo(db.db);
    beatId = await beats.saveBeat(Beat(name: 'Beat 7', office: 'HAL 2nd Stage SO'));
  });

  test('streets keep walking order and can be reordered', () async {
    final a = await beats.saveStreet(Street(beatId: beatId, name: '4th Cross'));
    final b = await beats.saveStreet(Street(beatId: beatId, name: '2nd Main'));
    final c = await beats.saveStreet(Street(beatId: beatId, name: '1st Cross'));
    expect((await beats.streets(beatId)).map((s) => s.id), [a, b, c]);
    await beats.reorderStreets([c, a, b]);
    expect((await beats.streets(beatId)).map((s) => s.id), [c, a, b]);
  });

  test('place with addressees and photos; details and search docs', () async {
    final s = await beats.saveStreet(Street(beatId: beatId, name: '4th Cross'));
    final id = await places.savePlace(
      Place(beatId: beatId, streetId: s, doorNo: '12/3', landmark: 'Ganesha temple', lat: 12.97, lng: 77.64),
    );
    await places.setAddressees(id, [
      Addressee(placeId: id, name: 'Ramesh Kumar'),
      Addressee(placeId: id, name: 'Geetha'),
    ]);
    await places.addPhoto(PlacePhoto(placeId: id, filePath: 'a.enc'));
    final d = (await places.details(id))!;
    expect(d.title, '12/3, 4th Cross');
    expect(d.addressees.map((a) => a.name), ['Ramesh Kumar', 'Geetha']);
    expect(d.photos.single.filePath, 'a.enc');

    // Replace list: keep one, add one.
    await places.setAddressees(id, [d.addressees.first, Addressee(placeId: id, name: 'Anil')]);
    expect((await places.addressees(id)).map((a) => a.name), ['Ramesh Kumar', 'Anil']);

    final idx = SearchIndex(await places.searchDocs(beatId: beatId));
    expect(idx.search('ರಮೇಶ್').single.id, id);
    expect(idx.search('12-3').single.id, id);
  });

  test('nearby sorts by distance', () async {
    const here = GeoPoint(12.9716, 77.6412);
    final far = await places.savePlace(Place(beatId: beatId, doorNo: '1', lat: here.lat + 0.003, lng: here.lng));
    final near = await places.savePlace(Place(beatId: beatId, doorNo: '2', lat: here.lat + 0.0002, lng: here.lng));
    await places.savePlace(Place(beatId: beatId, doorNo: '3')); // no GPS
    await places.savePlace(Place(beatId: beatId, doorNo: '4', lat: here.lat + 0.5, lng: here.lng)); // too far
    final list = await places.nearby(here);
    expect(list.map((n) => n.details.place.id), [near, far]);
    expect(list.first.distanceM, closeTo(22, 2));
  });

  test('merge duplicates', () async {
    final a = await places.savePlace(Place(beatId: beatId, doorNo: '12', gpsAccuracyM: 30, lat: 1, lng: 1));
    final b = await places.savePlace(
      Place(beatId: beatId, landmark: 'Blue gate', gpsAccuracyM: 5, lat: 2, lng: 2, notes: 'Dog'),
    );
    await places.setAddressees(a, [Addressee(placeId: a, name: 'Ramesh')]);
    await places.setAddressees(b, [Addressee(placeId: b, name: 'Ramesh'), Addressee(placeId: b, name: 'Sita')]);
    await places.addPhoto(PlacePhoto(placeId: b, filePath: 'b.enc'));
    final art = await articles.save(Article(date: '2026-10-03', placeId: b));
    await places.merge(keepId: a, dropId: b);
    final d = (await places.details(a))!;
    expect(d.place.doorNo, '12');
    expect(d.place.landmark, 'Blue gate');
    expect(d.place.lat, 2); // better GPS accuracy kept
    expect(d.place.notes, 'Dog');
    expect(d.addressees.map((x) => x.name), ['Ramesh', 'Sita']);
    expect(d.photos.single.filePath, 'b.enc');
    expect((await articles.article(art))!.placeId, a);
    expect(await places.place(b), isNull);
  });

  test('deleting a place keeps the article but unlinks it', () async {
    final p = await places.savePlace(Place(beatId: beatId, doorNo: '9'));
    final art = await articles.save(Article(date: '2026-10-03', placeId: p));
    await places.deletePlace(p);
    expect((await articles.article(art))!.placeId, isNull);
  });

  test('articles: carry forward re-attempts once, retention', () async {
    await articles.save(
      Article(
        date: '2026-10-02',
        articleNo: 'A1',
        status: ArticleStatus.notDelivered,
        reason: 'doorLocked',
        attempts: 1,
      ),
    );
    await articles.save(
      Article(date: '2026-10-02', articleNo: 'A2', status: ArticleStatus.notDelivered, reason: 'refused', attempts: 1),
    );
    await articles.save(Article(date: '2026-10-02', articleNo: 'A3', status: ArticleStatus.delivered));
    expect(await articles.carryForward('2026-10-02', '2026-10-03'), 1);
    expect(await articles.carryForward('2026-10-02', '2026-10-03'), 0);
    final today = await articles.forDate('2026-10-03');
    expect(today.single.articleNo, 'A1');
    expect(today.single.status, ArticleStatus.pending);
    expect(today.single.attempts, 1);
    expect(today.single.carriedFrom, '2026-10-02');

    await articles.save(Article(date: '2026-01-01', articleNo: 'OLD'));
    expect(await articles.deleteOlderThan(90, now: DateTime(2026, 10, 3)), 1);
    expect((await articles.history()).keys, ['2026-10-03', '2026-10-02']);
  });

  test('learn progress', () async {
    final s = await beats.saveStreet(Street(beatId: beatId, name: 'Temple Rd'));
    final p1 = await places.savePlace(Place(beatId: beatId, streetId: s, doorNo: '1'));
    final p2 = await places.savePlace(Place(beatId: beatId, streetId: s, doorNo: '2'));
    await learn.record(p1, true);
    await learn.record(p1, true);
    await learn.record(p2, false);
    final pr = await learn.progress(beatId);
    expect(pr.learned, 1);
    expect(pr.total, 2);
    expect(pr.percent, 50);
    expect(pr.weakStreets.single.streetName, 'Temple Rd');
    final w = await learn.weights(beatId);
    expect(w[p2]!, greaterThan(w[p1]!));
  });

  test('deleting a beat cascades', () async {
    final s = await beats.saveStreet(Street(beatId: beatId, name: 'X'));
    final p = await places.savePlace(Place(beatId: beatId, streetId: s));
    await places.setAddressees(p, [Addressee(placeId: p, name: 'Y')]);
    await beats.deleteBeat(beatId);
    expect(await places.countPlaces(), 0);
    expect(await beats.streets(beatId), isEmpty);
  });
}
