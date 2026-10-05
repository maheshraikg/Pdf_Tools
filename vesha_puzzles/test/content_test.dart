import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesha_puzzles/packs/content.dart';
import 'package:vesha_puzzles/packs/loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Content c;
  setUpAll(() async => c = await ContentLoader(rootBundle).load());

  test('bundled content loads without warnings', () {
    expect(c.warnings, isEmpty, reason: c.warnings.join('\n'));
    expect(c.packs.map((p) => p.id), ['yakshagana', 'karavali']);
    expect(c.allPuzzles.length, 12);
  });

  test('puzzle ids are unique and every puzzle has a story in en and kn', () {
    final ids = c.allPuzzles.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final p in c.allPuzzles) {
      final s = c.stories[p.storyId];
      expect(s, isNotNull, reason: p.id);
      for (final lang in [Lang.en, Lang.kn]) {
        expect(s!.title.has(lang), isTrue, reason: '${p.id} title $lang');
        expect(s.body.has(lang), isTrue, reason: '${p.id} body $lang');
        expect(s.fact.has(lang), isTrue, reason: '${p.id} fact $lang');
      }
      expect(p.title.has(Lang.kn), isTrue, reason: p.id);
    }
  });

  test('all cultural content carries a review flag until approved', () {
    for (final s in c.stories.values) {
      expect(s.review.status, anyOf('pending', 'approved'));
    }
    expect(c.dressUp!.review.status, isNotEmpty);
  });

  test('dress-up: required slots have options, unlocks reference puzzles', () {
    final d = c.dressUp!;
    expect(d.slots, isNotEmpty);
    for (final s in d.slots) {
      expect(s.options, isNotEmpty, reason: s.id);
      if (!s.optional) {
        expect(
          s.options.first.unlockPuzzle,
          isNull,
          reason: 'first ${s.id} option must be free',
        );
      }
      for (final o in s.options) {
        if (o.unlockPuzzle != null) {
          expect(
            c.puzzle(o.unlockPuzzle!),
            isNotNull,
            reason: '${s.id}/${o.id}',
          );
        }
      }
    }
  });

  test('events reference real puzzles and have ordered windows', () {
    expect(c.events, isNotEmpty);
    for (final e in c.events) {
      for (final f in e.featured) {
        expect(c.puzzle(f), isNotNull, reason: '${e.id}: $f');
      }
      for (final w in e.windows) {
        expect(w.$1.isAfter(w.$2), isFalse, reason: e.id);
      }
    }
    final nav = c.events.firstWhere((e) => e.id == 'navaratri_pili');
    expect(nav.activeOn(DateTime(2026, 10, 15, 21)), isTrue);
    expect(nav.activeOn(DateTime(2026, 10, 21)), isFalse);
  });

  test('guide has lines for every prefix the app uses', () {
    for (final p in ['home.', 'done.', 'story.', 'dress.']) {
      expect(c.linesWithPrefix(p), isNotEmpty, reason: p);
    }
    expect(c.line('tip.tray'), isNotNull);
    expect(c.guide.images.keys, containsAll(['idle', 'happy', 'think']));
  });

  test('LText falls back Tulu → Kannada → English', () {
    const t = LText({'en': 'Hello', 'kn': 'ನಮಸ್ಕಾರ'});
    expect(t.of(Lang.tcy), 'ನಮಸ್ಕಾರ');
    expect(const LText({'en': 'Hi'}).of(Lang.tcy), 'Hi');
  });

  test('a missing image skips only that puzzle and reports it', () async {
    final bundle = _OverrideBundle({
      'assets/packs/index.json': '{"packs":["x"]}',
      'assets/packs/x/pack.json': '{"id":"x","title":"X","puzzles":[{"id":"ok","image":"../yakshagana/images/y01_raja_vesha.jpg"},{"id":"gone","image":"images/nope.jpg"}]}',
    });
    final r = await ContentLoader(bundle).load();
    expect(r.allPuzzles.map((p) => p.id), ['ok']);
    expect(r.warnings.any((w) => w.contains('nope.jpg')), isTrue);
  });
}

/// Real bundle with a few files replaced.
class _OverrideBundle extends CachingAssetBundle {
  _OverrideBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) {
    final f = files[key];
    if (f != null)
      return Future.value(
        ByteData.sublistView(Uint8List.fromList(f.codeUnits)),
      );
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      files[key] ?? await rootBundle.loadString(key, cache: cache);
}
