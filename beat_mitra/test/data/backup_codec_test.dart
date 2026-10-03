import 'dart:typed_data';

import 'package:beat_mitra/core/crypto.dart';
import 'package:beat_mitra/core/services/photo_store.dart';
import 'package:beat_mitra/data/backup_codec.dart';
import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/data/repos/article_repo.dart';
import 'package:beat_mitra/data/repos/beat_repo.dart';
import 'package:beat_mitra/data/repos/place_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_db.dart';

void main() {
  Future<(BackupCodec, int)> seeded() async {
    final db = await openTestDatabase();
    final photos = MemoryPhotoStore();
    final beats = BeatRepo(db.db);
    final places = PlaceRepo(db.db);
    final b = await beats.saveBeat(Beat(name: 'Beat 7', office: 'HAL SO'));
    final s = await beats.saveStreet(Street(beatId: b, name: '4th Cross', area: 'HAL 2nd Stage'));
    await beats.saveAreaNote(AreaNote(beatId: b, title: 'Numbering', text: 'Cross numbers increase towards the lake'));
    final p = await places.savePlace(
      Place(beatId: b, streetId: s, doorNo: '12/3', landmark: 'Temple', lat: 12.9, lng: 77.6),
    );
    await places.setAddressees(p, [Addressee(placeId: p, name: 'ರಮೇಶ್', phone: '9876543210')]);
    final file = await photos.saveBytes(Uint8List.fromList([1, 2, 3, 4]));
    await places.addPhoto(PlacePhoto(placeId: p, filePath: file));
    await ArticleRepo(db.db).save(Article(date: '2026-10-03', articleNo: 'EK123456785IN', placeId: p));
    return (BackupCodec(db.db, photos), b);
  }

  test('handover export/import round-trip (encrypted)', () async {
    final (src, beatId) = await seeded();
    final file = await src.export(
      password: 'secret-pw',
      kind: ExportKind.handover,
      beatIds: [beatId],
      iterations: 2000,
    );
    expect(isBeatMitraFile(file), isTrue);

    final dstDb = await openTestDatabase();
    final dstPhotos = MemoryPhotoStore();
    final dst = BackupCodec(dstDb.db, dstPhotos);
    final (kind, archive) = await BackupCodec.open(file, 'secret-pw');
    expect(kind, ExportKind.handover);
    final r = await dst.import(archive);
    expect(r.beats, 1);
    expect(r.places, 1);
    expect(r.photos, 1);
    expect(r.articles, 0); // handover has no delivery history

    final places = await PlaceRepo(dstDb.db).allDetails();
    final d = places.single;
    expect(d.place.doorNo, '12/3');
    expect(d.street!.name, '4th Cross');
    expect(d.addressees.single.name, 'ರಮೇಶ್');
    expect(d.addressees.single.phone, '9876543210');
    expect(await dstPhotos.load(d.photos.single.filePath), [1, 2, 3, 4]);
    expect((await BeatRepo(dstDb.db).areaNotes(d.place.beatId)).single.title, 'Numbering');
  });

  test('exclude phone numbers', () async {
    final (src, beatId) = await seeded();
    final file = await src.export(
      password: 'pw',
      kind: ExportKind.handover,
      beatIds: [beatId],
      includePhones: false,
      iterations: 2000,
    );
    final dstDb = await openTestDatabase();
    final (_, archive) = await BackupCodec.open(file, 'pw');
    await BackupCodec(dstDb.db, MemoryPhotoStore()).import(archive);
    expect((await PlaceRepo(dstDb.db).allDetails()).single.addressees.single.phone, '');
  });

  test('wrong password', () async {
    final (src, _) = await seeded();
    final file = await src.export(password: 'right', kind: ExportKind.handover, iterations: 2000);
    expect(() => BackupCodec.open(file, 'wrong'), throwsA(isA<WrongPasswordException>()));
  });

  test('full backup restore replaces data and keeps articles linked', () async {
    final (src, _) = await seeded();
    final file = await src.export(password: 'pw', kind: ExportKind.fullBackup, iterations: 2000);
    // Restore into the same DB (replace all).
    final (kind, archive) = await BackupCodec.open(file, 'pw');
    expect(kind, ExportKind.fullBackup);
    final r = await src.import(archive, replaceAll: true);
    expect(r.articles, 1);
    final places = await PlaceRepo(src.db).allDetails();
    expect(places.length, 1);
    final art = (await ArticleRepo(src.db).forDate('2026-10-03')).single;
    expect(art.placeId, places.single.place.id);
  });
}
