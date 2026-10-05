import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../game/audio.dart';
import '../monetization/flags.dart';
import '../packs/content.dart';
import '../widgets/share_image.dart';
import '../widgets/vesha_guide.dart';

/// Dress a Yakshagana performer layer by layer: face paint, costume,
/// ornaments, crown and prop. All layers share one canvas size, so they
/// simply stack.
class DressUpScreen extends StatefulWidget {
  const DressUpScreen({super.key});

  @override
  State<DressUpScreen> createState() => _DressUpScreenState();
}

class _DressUpScreenState extends State<DressUpScreen> {
  final Map<String, String?> _choice = {};
  String? _slot;
  final _canvasKey = GlobalKey();
  static const _storeKey = 'dressup.current';

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    final def = app.content.dressUp!;
    _slot = def.slots.isEmpty ? null : def.slots.first.id;
    try {
      final raw = app.store.getString(_storeKey);
      if (raw != null) {
        (jsonDecode(raw) as Map).forEach((k, v) => _choice['$k'] = v as String?);
      }
    } catch (_) {}
    for (final slot in def.slots) {
      if (!_choice.containsKey(slot.id) && !slot.optional && slot.options.isNotEmpty) {
        _choice[slot.id] = slot.options.first.id;
      }
    }
  }

  void _set(String slot, String? option) {
    setState(() => _choice[slot] = option);
    final app = AppScope.read(context);
    app.store.setString(_storeKey, jsonEncode(_choice));
    app.audio.play(Sfx.tap);
  }

  void _surprise(DressUpDef def, AppState app) {
    final r = math.Random();
    setState(() {
      for (final slot in def.slots) {
        final opts = slot.options.where(app.optionUnlocked).toList();
        if (opts.isEmpty) continue;
        _choice[slot.id] = slot.optional && r.nextInt(5) == 0 ? null : opts[r.nextInt(opts.length)].id;
      }
    });
    app.store.setString(_storeKey, jsonEncode(_choice));
    app.audio.play(Sfx.snap);
  }

  void _reset(DressUpDef def, AppState app) {
    setState(() {
      _choice.clear();
      for (final slot in def.slots) {
        if (!slot.optional && slot.options.isNotEmpty) _choice[slot.id] = slot.options.first.id;
      }
    });
    app.store.remove(_storeKey);
  }

  Future<ui.Image?> _capture() async {
    final b = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    return b?.toImage(pixelRatio: 3);
  }

  Future<void> _saveLook(AppState app, S s) async {
    final fresh = app.lookSaved();
    app.audio.play(Sfx.place);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          [s.lookSaved, if (fresh.isNotEmpty) '${s.unlockedAchievement}: ${fresh.map(s.achievementTitle).join(', ')}'].join(' '),
        ),
        action: SnackBarAction(
          label: s.share,
          onPressed: () async {
            final img = await _capture();
            if (img == null) return;
            final png = await renderShareImage(img, s.dressUp, s.appTitle);
            img.dispose();
            await shareImage(png, 'vesha_look.png', s.appTitle);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final def = app.content.dressUp!;
    final slot = def.slots.where((x) => x.id == _slot).firstOrNull;
    final selected = slot?.options.where((o) => o.id == _choice[slot.id]).firstOrNull;
    final scheme = Theme.of(context).colorScheme;

    final layers = <String>[
      def.base,
      for (final sl in def.slotsByZ)
        ?sl.options.where((o) => o.id == _choice[sl.id]).firstOrNull?.image,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.dressUp),
        actions: [
          IconButton(tooltip: s.surprise, icon: const Icon(Icons.casino_outlined), onPressed: () => _surprise(def, app)),
          IconButton(tooltip: s.reset, icon: const Icon(Icons.restart_alt), onPressed: () => _reset(def, app)),
          IconButton(tooltip: s.saveLook, icon: const Icon(Icons.bookmark_add_outlined), onPressed: () => _saveLook(app, s)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: def.width / def.height,
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [scheme.secondaryContainer, scheme.surface],
                        radius: 0.9,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        for (final l in layers)
                          Image.asset(l, key: ValueKey(l), fit: BoxFit.contain, gaplessPlayback: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (selected != null && !selected.about.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                selected.about.of(lang) +
                    (kShowReviewFlags && def.review.pending ? '  (${s.underReview})' : ''),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else if (app.settings.guideTips)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VeshaGuide(compact: true, size: 44, line: VeshaGuide.pick(app.content, 'dress.', salt: _choice.length)),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final sl in def.slots)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sl.name.of(lang)),
                      selected: sl.id == _slot,
                      onSelected: (_) => setState(() => _slot = sl.id),
                    ),
                  ),
              ],
            ),
          ),
          if (slot != null)
            SafeArea(
              top: false,
              child: SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  children: [
                    if (slot.optional)
                      _OptionCard(
                        label: s.none,
                        selected: _choice[slot.id] == null,
                        onTap: () => _set(slot.id, null),
                        child: const Icon(Icons.block, size: 36),
                      ),
                    for (final o in slot.options)
                      Builder(
                        builder: (context) {
                          final unlocked = app.optionUnlocked(o);
                          final needed = o.unlockPuzzle == null ? null : app.content.puzzle(o.unlockPuzzle!);
                          return _OptionCard(
                            label: o.name.of(lang),
                            selected: _choice[slot.id] == o.id,
                            locked: !unlocked,
                            onTap: unlocked
                                ? () => _set(slot.id, o.id)
                                : () => ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(content: Text(s.unlockBy(needed?.title.of(lang) ?? '?'))),
                                  ),
                            child: Image.asset(o.image!, fit: BoxFit.contain, cacheWidth: 240),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 92,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 3),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(padding: const EdgeInsets.all(4), child: Opacity(opacity: locked ? 0.3 : 1, child: child)),
                      if (locked) const Center(child: Icon(Icons.lock, size: 28)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
