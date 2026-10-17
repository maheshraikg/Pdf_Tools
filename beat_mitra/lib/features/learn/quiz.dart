import 'dart:math';

import '../../data/models.dart';

enum QuizMode { photoToPlace, nameToDoor, doorToLandmark, walk }

class QuizQuestion {
  QuizQuestion({required this.target, required this.prompt, required this.options, required this.correct, this.photo});
  final PlaceDetails target;

  /// Text shown as the question (name / door no.), empty for photo mode.
  final String prompt;
  final String? photo;
  final List<String> options;
  final int correct;
}

String placeAnswer(PlaceDetails d) =>
    [if (d.place.doorNo.isNotEmpty) d.place.doorNo, if (d.streetName.isNotEmpty) d.streetName].join(', ');

/// Can [d] be asked in [mode]?
bool usable(QuizMode mode, PlaceDetails d) => switch (mode) {
  QuizMode.photoToPlace => d.photos.isNotEmpty && placeAnswer(d).isNotEmpty,
  QuizMode.nameToDoor => d.addressees.isNotEmpty && placeAnswer(d).isNotEmpty,
  QuizMode.doorToLandmark => d.place.doorNo.isNotEmpty && d.place.landmark.isNotEmpty,
  QuizMode.walk => d.addressees.isNotEmpty || d.place.doorNo.isNotEmpty,
};

/// Picks a target (weighted towards weak / unseen places) and builds a
/// 4-option multiple-choice question. Returns null if there is too little data.
QuizQuestion? buildQuestion(
  QuizMode mode,
  List<PlaceDetails> pool,
  Map<int, int> weights,
  Random rnd, {
  PlaceDetails? fixedTarget,
}) {
  final candidates = pool.where((d) => usable(mode, d)).toList();
  if (fixedTarget == null && candidates.isEmpty) return null;
  final target = fixedTarget ?? _weightedPick(candidates, weights, rnd);

  String answerOf(PlaceDetails d) => switch (mode) {
    QuizMode.doorToLandmark => d.place.landmark,
    QuizMode.walk => d.addressees.isNotEmpty ? d.addressees.first.name : placeAnswer(d),
    _ => placeAnswer(d),
  };

  final right = answerOf(target);
  if (right.isEmpty) return null;
  final wrongPool =
      pool
          .where((d) => d.place.id != target.place.id)
          .map(answerOf)
          .where((a) => a.isNotEmpty && a != right)
          .toSet()
          .toList()
        ..shuffle(rnd);
  if (wrongPool.isEmpty) return null;
  final options = [right, ...wrongPool.take(3)]..shuffle(rnd);
  final prompt = switch (mode) {
    QuizMode.nameToDoor => target.addressees[rnd.nextInt(target.addressees.length)].name,
    QuizMode.doorToLandmark => placeAnswer(target),
    _ => '',
  };
  return QuizQuestion(
    target: target,
    prompt: prompt,
    photo: target.photos.isEmpty ? null : target.photos.first.filePath,
    options: options,
    correct: options.indexOf(right),
  );
}

PlaceDetails _weightedPick(List<PlaceDetails> list, Map<int, int> weights, Random rnd) {
  final total = list.fold<int>(0, (s, d) => s + (weights[d.place.id] ?? 1));
  var r = rnd.nextInt(max(1, total));
  for (final d in list) {
    r -= weights[d.place.id] ?? 1;
    if (r < 0) return d;
  }
  return list.last;
}
