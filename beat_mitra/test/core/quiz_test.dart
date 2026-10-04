import 'dart:math';

import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/features/learn/quiz.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceDetails pd(
  int id,
  String door,
  String street, {
  String landmark = '',
  List<String> names = const [],
  bool photo = false,
}) => PlaceDetails(
  place: Place(id: id, beatId: 1, streetId: 1, doorNo: door, landmark: landmark),
  street: Street(id: 1, beatId: 1, name: street),
  addressees: [for (final n in names) Addressee(placeId: id, name: n)],
  photos: photo ? [PlacePhoto(placeId: id, filePath: 'p$id')] : const [],
);

void main() {
  final pool = [
    pd(1, '1', 'A St', landmark: 'Temple', names: ['Ramesh'], photo: true),
    pd(2, '2', 'A St', landmark: 'School', names: ['Sita'], photo: true),
    pd(3, '3', 'B St', landmark: 'Park', names: ['Anil']),
    pd(4, '4', 'B St', landmark: 'Lake', names: ['Kavya'], photo: true),
  ];

  test('questions have one correct option among up to four', () {
    final rnd = Random(3);
    for (final mode in [QuizMode.photoToPlace, QuizMode.nameToDoor, QuizMode.doorToLandmark]) {
      for (var i = 0; i < 20; i++) {
        final q = buildQuestion(mode, pool, const {}, rnd)!;
        expect(q.options.length, inInclusiveRange(2, 4));
        expect(q.options.toSet().length, q.options.length);
        final right = switch (mode) {
          QuizMode.doorToLandmark => q.target.place.landmark,
          _ => placeAnswer(q.target),
        };
        expect(q.options[q.correct], right);
        if (mode == QuizMode.photoToPlace) expect(q.photo, isNotNull);
      }
    }
  });

  test('weights favour weak places', () {
    final rnd = Random(1);
    var hits = 0;
    for (var i = 0; i < 200; i++) {
      if (buildQuestion(QuizMode.nameToDoor, pool, {1: 10, 2: 1, 3: 1, 4: 1}, rnd)!.target.place.id == 1) hits++;
    }
    expect(hits, greaterThan(100));
  });

  test('too little data returns null', () {
    expect(buildQuestion(QuizMode.nameToDoor, [pool.first], const {}, Random()), isNull);
    expect(buildQuestion(QuizMode.photoToPlace, [pool[2]], const {}, Random()), isNull);
  });
}
