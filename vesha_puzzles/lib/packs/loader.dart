/// Loads [Content] from JSON assets and checks every referenced file
/// exists, so a half-delivered art pack degrades gracefully instead of
/// crashing.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'content.dart';

class ContentLoader {
  ContentLoader(this.bundle);
  final AssetBundle bundle;

  static const root = 'assets';

  Future<Content> load() async {
    final warnings = <String>[];
    Set<String>? assets;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      assets = manifest.listAssets().toSet();
    } catch (_) {
      // Fake bundles in tests may have no manifest; skip existence checks.
    }
    bool exists(String path) => assets == null || assets.contains(path);

    Future<Object?> json(String path) async {
      try {
        return jsonDecode(await bundle.loadString(path));
      } catch (e) {
        warnings.add('Cannot read $path: $e');
        return null;
      }
    }

    // Packs.
    final index = await json('$root/packs/index.json');
    final packs = <ArtPack>[];
    for (final id
        in (index is Map ? index['packs'] as List? : null) ?? const []) {
      final dir = '$root/packs/$id';
      final raw = await json('$dir/pack.json');
      if (raw is! Map) continue;
      final puzzles = <PuzzleDef>[];
      for (final p in (raw['puzzles'] as List? ?? const []).cast<Map>()) {
        final image = joinAsset(dir, '${p['image']}');
        if (!exists(image)) {
          warnings.add(
            'Pack $id: missing image $image (puzzle ${p['id']} skipped)',
          );
          continue;
        }
        puzzles.add(
          PuzzleDef(
            id: p['id'] as String,
            packId: '$id',
            image: image,
            title: LText.fromJson(p['title']),
            storyId: p['story'] as String?,
            index: puzzles.length,
            tags: [for (final t in (p['tags'] as List? ?? const [])) '$t'],
            credit: PhotoCredit.fromJson(p['credit']),
          ),
        );
      }
      final cover = joinAsset(dir, '${raw['cover'] ?? ''}');
      packs.add(
        ArtPack(
          id: '$id',
          version: (raw['version'] as num?)?.toInt() ?? 1,
          title: LText.fromJson(raw['title']),
          description: LText.fromJson(raw['description']),
          cover: exists(cover)
              ? cover
              : (puzzles.isEmpty ? '' : puzzles.first.image),
          credits: Credits.fromJson(raw['credits']),
          placeholder: raw['placeholder'] == true,
          puzzles: puzzles,
        ),
      );
    }

    // Stories.
    final storiesRaw = await json('$root/content/stories.json');
    final stories = <String, Story>{
      for (final s
          in ((storiesRaw is Map ? storiesRaw['stories'] : null) as List? ??
                  const [])
              .cast<Map>())
        s['id'] as String: Story.fromJson(s),
    };
    for (final p in packs.expand((p) => p.puzzles)) {
      if (p.storyId != null && !stories.containsKey(p.storyId)) {
        warnings.add('Puzzle ${p.id}: story ${p.storyId} not found');
      }
    }

    // Dress-up.
    DressUpDef? dressUp;
    final d = await json('$root/dressup/dressup.json');
    if (d is Map) {
      final dir = '$root/dressup';
      final slots = <DressSlot>[];
      for (final s in (d['slots'] as List? ?? const []).cast<Map>()) {
        final options = <DressOption>[];
        for (final o in (s['options'] as List? ?? const []).cast<Map>()) {
          final img = joinAsset(dir, '${o['image']}');
          if (!exists(img)) {
            warnings.add('Dress-up: missing layer $img');
            continue;
          }
          options.add(
            DressOption(
              id: o['id'] as String,
              name: LText.fromJson(o['name']),
              about: LText.fromJson(o['about']),
              image: img,
              unlockPuzzle: o['unlock'] as String?,
            ),
          );
        }
        slots.add(
          DressSlot(
            id: s['id'] as String,
            name: LText.fromJson(s['name']),
            z: (s['z'] as num?)?.toInt() ?? slots.length,
            options: options,
            optional: s['optional'] != false,
            thumb: switch (s['thumb']) {
              [num x, num y, num w, num h] => Rect.fromLTWH(
                x.toDouble(),
                y.toDouble(),
                w.toDouble(),
                h.toDouble(),
              ),
              _ => null,
            },
          ),
        );
      }
      final base = joinAsset(dir, '${d['base']}');
      if (exists(base)) {
        dressUp = DressUpDef(
          base: base,
          width: (d['width'] as num?)?.toInt() ?? 1024,
          height: (d['height'] as num?)?.toInt() ?? 1536,
          slots: slots,
          review: Review.fromJson(d['review']),
          credits: Credits.fromJson(d['credits']),
        );
      } else {
        warnings.add('Dress-up: missing base $base (mode disabled)');
      }
    }

    // Guide.
    final g = await json('$root/content/guide.json');
    final lines = <GuideLine>[];
    final images = <String, String>{};
    if (g is Map) {
      for (final l in (g['lines'] as List? ?? const []).cast<Map>()) {
        lines.add(
          GuideLine(
            l['id'] as String,
            LText.fromJson(l['text']),
            (l['mood'] as String?) ?? 'idle',
          ),
        );
      }
      for (final e in ((g['images'] as Map?) ?? const {}).entries) {
        final path = joinAsset('$root/guide', '${e.value}');
        if (exists(path)) {
          images['${e.key}'] = path;
        } else {
          warnings.add('Guide: missing image $path');
        }
      }
    }

    // Events.
    final ev = await json('$root/content/events.json');
    final events = <EventDef>[];
    for (final e
        in ((ev is Map ? ev['events'] : null) as List? ?? const [])
            .cast<Map>()) {
      final windows = <(DateTime, DateTime)>[];
      for (final w in (e['windows'] as List? ?? const []).cast<Map>()) {
        final a = DateTime.tryParse('${w['from']}');
        final b = DateTime.tryParse('${w['to']}');
        if (a != null && b != null) windows.add((a, b));
      }
      events.add(
        EventDef(
          id: e['id'] as String,
          title: LText.fromJson(e['title']),
          blurb: LText.fromJson(e['blurb']),
          windows: windows,
          featured: [
            for (final f in (e['featured'] as List? ?? const [])) '$f',
          ],
          review: Review.fromJson(e['review']),
        ),
      );
    }

    return Content(
      packs: packs,
      stories: stories,
      dressUp: dressUp,
      guideLines: lines,
      guide: GuideAssets(images),
      events: events,
      warnings: warnings,
    );
  }
}

/// Joins an asset directory and a relative path, resolving `.` and `..`
/// so packs can share files (e.g. `../other_pack/images/x.jpg`).
String joinAsset(String dir, String rel) {
  final out = <String>[];
  for (final part in '$dir/$rel'.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (out.isNotEmpty) out.removeLast();
    } else {
      out.add(part);
    }
  }
  return out.join('/');
}
