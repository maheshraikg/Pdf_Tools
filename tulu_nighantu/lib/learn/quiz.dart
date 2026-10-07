import 'dart:math';

import '../lipi/tulu_lipi.dart';
import '../models/word.dart';

/// Kind of quiz question.
enum QuizKind {
  /// Tulu word → choose its meaning.
  meaning,

  /// English meaning → choose the Tulu word.
  tuluWord,

  /// Tulu lipi letter → choose the Kannada letter.
  letter,
}

/// One multiple-choice question.
class QuizQuestion {
  const QuizQuestion({
    required this.kind,
    required this.prompt,
    required this.promptLipi,
    required this.options,
    required this.answer,
    this.speech,
  });

  final QuizKind kind;

  /// Text shown as the question (Kannada script or English).
  final String prompt;

  /// Tulu lipi shown large above the prompt (may be empty).
  final String promptLipi;

  final List<String> options;

  /// Index of the correct option.
  final int answer;

  /// Kannada-script text to read aloud, if any.
  final String? speech;
}

/// First English meaning of [w] (before ';'), without "(10)" style notes.
String shortMeaning(Word w) =>
    w.en.split(';').first.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();

/// Builds a mixed quiz of [count] questions from dictionary [words] and the
/// alphabet. Deterministic for a given [random].
List<QuizQuestion> buildQuiz(
  List<Word> words, {
  int count = 10,
  Random? random,
}) {
  final rnd = random ?? Random();
  final pool = <Word>[];
  final seen = <String>{};
  for (final w in words) {
    final m = shortMeaning(w);
    if (w.custom || w.isPhrase || m.isEmpty || m.length > 24) continue;
    if (seen.add(m.toLowerCase())) pool.add(w);
  }
  final letters = kLipiLetters.where((l) => l.tulu.isNotEmpty).toList();
  final out = <QuizQuestion>[];
  final usedWords = <String>{};
  final usedLetters = <String>{};
  var guard = 0;
  while (out.length < count && guard++ < count * 20) {
    final kind = QuizKind.values[out.length % QuizKind.values.length];
    if (kind == QuizKind.letter) {
      if (letters.length < 4) continue;
      final l = letters[rnd.nextInt(letters.length)];
      if (!usedLetters.add(l.kannada)) continue;
      final others =
          (letters.where((o) => o.label != l.label).toList()..shuffle(rnd))
              .take(3)
              .map((o) => o.label);
      final options = [l.label, ...others]..shuffle(rnd);
      out.add(
        QuizQuestion(
          kind: kind,
          prompt: 'ಈ ಅಕ್ಷರ ಯಾವುದು? · Which letter is this?',
          promptLipi: l.tulu,
          options: options,
          answer: options.indexOf(l.label),
          speech: l.kannada,
        ),
      );
      continue;
    }
    if (pool.length < 4) break;
    final w = pool[rnd.nextInt(pool.length)];
    if (!usedWords.add(w.id)) continue;
    final distractors = (pool.where((o) => o.id != w.id).toList()..shuffle(rnd))
        .take(3)
        .toList();
    if (kind == QuizKind.meaning) {
      final options = [shortMeaning(w), ...distractors.map(shortMeaning)]
        ..shuffle(rnd);
      out.add(
        QuizQuestion(
          kind: kind,
          prompt: w.tulu,
          promptLipi: w.lipi,
          options: options,
          answer: options.indexOf(shortMeaning(w)),
          speech: w.tulu,
        ),
      );
    } else {
      final options = [w.tulu, ...distractors.map((d) => d.tulu)]..shuffle(rnd);
      out.add(
        QuizQuestion(
          kind: kind,
          prompt: '“${shortMeaning(w)}” ತುಳುವಿನಲ್ಲಿ? · in Tulu?',
          promptLipi: '',
          options: options,
          answer: options.indexOf(w.tulu),
        ),
      );
    }
  }
  return out;
}

/// Daily practice streak.
class Streak {
  const Streak({this.current = 0, this.best = 0, this.lastDay});

  final int current;
  final int best;

  /// Last practice day as yyyy-mm-dd (local date).
  final String? lastDay;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// The streak after practising on [today].
  Streak practisedOn(DateTime today) {
    final key = dayKey(today);
    if (key == lastDay) return this;
    final yesterday = dayKey(DateTime(today.year, today.month, today.day - 1));
    final next = lastDay == yesterday ? current + 1 : 1;
    return Streak(current: next, best: max(best, next), lastDay: key);
  }

  /// Streak to show on [today] (0 when a day was missed).
  int activeOn(DateTime today) {
    if (lastDay == null) return 0;
    final yesterday = dayKey(DateTime(today.year, today.month, today.day - 1));
    return lastDay == dayKey(today) || lastDay == yesterday ? current : 0;
  }

  Map<String, Object?> toJson() => {
    'current': current,
    'best': best,
    'lastDay': lastDay,
  };

  factory Streak.fromJson(Map<String, dynamic> j) => Streak(
    current: (j['current'] as num?)?.toInt() ?? 0,
    best: (j['best'] as num?)?.toInt() ?? 0,
    lastDay: j['lastDay'] as String?,
  );
}
