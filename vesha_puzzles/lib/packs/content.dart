/// Content model: art packs, puzzles, stories, dress-up layers, guide
/// lines and events. Everything is plain data loaded from JSON assets so an
/// artist or writer can replace it without touching code.
library;

enum Lang { en, kn, tcy }

extension LangInfo on Lang {
  String get nativeName => switch (this) {
    Lang.en => 'English',
    Lang.kn => 'ಕನ್ನಡ',
    Lang.tcy => 'ತುಳು',
  };

  static Lang parse(String? s) =>
      Lang.values.firstWhere((l) => l.name == s, orElse: () => Lang.en);
}

/// Text in several languages. Tulu falls back to Kannada, then English.
class LText {
  const LText(this.values);
  final Map<String, String> values;

  factory LText.fromJson(Object? json) {
    if (json is String) return LText({'en': json});
    if (json is Map) {
      return LText({
        for (final e in json.entries)
          if (e.value is String) e.key as String: e.value as String,
      });
    }
    return const LText({});
  }

  String of(Lang lang) =>
      values[lang.name] ??
      (lang == Lang.tcy ? values['kn'] : null) ??
      values['en'] ??
      (values.isEmpty ? '' : values.values.first);

  bool has(Lang lang) => values.containsKey(lang.name);
  bool get isEmpty => values.values.every((v) => v.isEmpty);
}

/// Expert-review status attached to cultural content.
class Review {
  const Review(this.status, this.notes);
  final String status; // "pending" | "approved"
  final String notes;

  bool get pending => status != 'approved';

  factory Review.fromJson(Object? json) {
    if (json is Map) {
      return Review(
        (json['status'] as String?) ?? 'pending',
        (json['notes'] as String?) ?? '',
      );
    }
    return const Review('pending', '');
  }
}

class Credits {
  const Credits({
    required this.artist,
    required this.licence,
    this.url = '',
    this.year = '',
  });
  final String artist;
  final String licence;
  final String url;
  final String year;

  factory Credits.fromJson(Object? json) {
    final m = json is Map ? json : const {};
    return Credits(
      artist: (m['artist'] as String?) ?? 'Unknown',
      licence: (m['licence'] as String?) ?? 'All rights reserved',
      url: (m['url'] as String?) ?? '',
      year: (m['year'] as String?) ?? '',
    );
  }
}

/// Attribution for a picture taken from an openly licensed source.
class PhotoCredit {
  const PhotoCredit({
    required this.author,
    required this.licence,
    required this.source,
    this.changes = '',
  });
  final String author;
  final String licence;
  final String source;
  final String changes;

  static PhotoCredit? fromJson(Object? json) {
    if (json is! Map) return null;
    return PhotoCredit(
      author: '${json['author'] ?? ''}',
      licence: '${json['licence'] ?? ''}',
      source: '${json['source'] ?? ''}',
      changes: '${json['changes'] ?? ''}',
    );
  }

  /// Short attribution line, e.g. `Photo: A. Name · CC BY-SA 4.0`.
  String get short => 'Photo: $author · $licence';
}

class PuzzleDef {
  const PuzzleDef({
    required this.id,
    required this.packId,
    required this.image,
    required this.title,
    required this.storyId,
    required this.index,
    this.tags = const [],
    this.credit,
  });

  final String id;
  final String packId;

  /// Set when the picture is a third-party photo that needs attribution.
  final PhotoCredit? credit;

  /// Full asset path of the picture.
  final String image;
  final LText title;
  final String? storyId;

  /// Position within the pack (0-based), used for unlocking.
  final int index;
  final List<String> tags;
}

class ArtPack {
  const ArtPack({
    required this.id,
    required this.title,
    required this.description,
    required this.cover,
    required this.credits,
    required this.placeholder,
    required this.puzzles,
    required this.version,
  });

  final String id;
  final LText title;
  final LText description;
  final String cover;
  final Credits credits;

  /// True while the pack still contains generated placeholder art.
  final bool placeholder;
  final List<PuzzleDef> puzzles;
  final int version;
}

class Story {
  const Story({
    required this.id,
    required this.title,
    required this.body,
    required this.fact,
    required this.review,
    this.sources = const [],
  });

  final String id;
  final LText title;

  /// Paragraphs separated by blank lines.
  final LText body;

  /// One-line "Did you know?" fact.
  final LText fact;
  final Review review;
  final List<String> sources;

  factory Story.fromJson(Map json) => Story(
    id: json['id'] as String,
    title: LText.fromJson(json['title']),
    body: LText.fromJson(json['body']),
    fact: LText.fromJson(json['fact']),
    review: Review.fromJson(json['review']),
    sources: [for (final s in (json['sources'] as List? ?? const [])) '$s'],
  );
}

class DressOption {
  const DressOption({
    required this.id,
    required this.name,
    required this.image,
    this.about = const LText({}),
    this.unlockPuzzle,
  });

  final String id;
  final LText name;
  final LText about;

  /// Full asset path of the transparent layer image, or null for "none".
  final String? image;

  /// Puzzle that must be completed to unlock this option.
  final String? unlockPuzzle;
}

class DressSlot {
  const DressSlot({
    required this.id,
    required this.name,
    required this.z,
    required this.options,
    required this.optional,
  });

  final String id;
  final LText name;

  /// Draw order (low first).
  final int z;
  final List<DressOption> options;

  /// Whether "none" is allowed.
  final bool optional;
}

class DressUpDef {
  const DressUpDef({
    required this.base,
    required this.width,
    required this.height,
    required this.slots,
    required this.review,
    required this.credits,
  });

  final String base;
  final int width;
  final int height;
  final List<DressSlot> slots;
  final Review review;
  final Credits credits;

  List<DressSlot> get slotsByZ =>
      [...slots]..sort((a, b) => a.z.compareTo(b.z));
}

class GuideLine {
  const GuideLine(this.id, this.text, this.mood);
  final String id;
  final LText text;

  /// idle | happy | think
  final String mood;
}

class EventDef {
  const EventDef({
    required this.id,
    required this.title,
    required this.blurb,
    required this.windows,
    required this.featured,
    required this.review,
  });

  final String id;
  final LText title;
  final LText blurb;

  /// Inclusive date windows (local dates).
  final List<(DateTime, DateTime)> windows;

  /// Puzzle ids highlighted during the event.
  final List<String> featured;
  final Review review;

  bool activeOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return windows.any((w) => !d.isBefore(w.$1) && !d.isAfter(w.$2));
  }
}

class GuideAssets {
  const GuideAssets(this.images);

  /// mood → asset path.
  final Map<String, String> images;
  String? imageFor(String mood) => images[mood] ?? images['idle'];
}

/// Everything loaded from assets.
class Content {
  const Content({
    required this.packs,
    required this.stories,
    required this.dressUp,
    required this.guideLines,
    required this.guide,
    required this.events,
    this.warnings = const [],
  });

  final List<ArtPack> packs;
  final Map<String, Story> stories;
  final DressUpDef? dressUp;
  final List<GuideLine> guideLines;
  final GuideAssets guide;
  final List<EventDef> events;

  /// Problems found while loading (missing files, bad references).
  final List<String> warnings;

  Iterable<PuzzleDef> get allPuzzles => packs.expand((p) => p.puzzles);

  PuzzleDef? puzzle(String id) {
    for (final p in allPuzzles) {
      if (p.id == id) return p;
    }
    return null;
  }

  ArtPack? pack(String id) {
    for (final p in packs) {
      if (p.id == id) return p;
    }
    return null;
  }

  Iterable<GuideLine> linesWithPrefix(String prefix) =>
      guideLines.where((l) => l.id.startsWith(prefix));

  GuideLine? line(String id) {
    for (final l in guideLines) {
      if (l.id == id) return l;
    }
    return null;
  }
}
