/// Decorative, animated building blocks: entrance animation, the read-aloud
/// button, the festival banner and the Tulunadu hero header.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/speech.dart';
import '../app/summary.dart';
import '../app/theme.dart';
import '../art/festival_art.dart';
import '../art/tulunadu_scene.dart';
import '../astro/astro.dart';
import '../panchanga/engine.dart';
import '../panchanga/festivals.dart';
import '../panchanga/names.dart';
import 'day_widgets.dart';

/// Fades and slides its child in, [index] steps after the first.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final total = 380 + index * 90;
    final start = (index * 90) / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Play/stop button for reading text aloud, with a pulsing ring while
/// speaking.
class SpeakButton extends StatefulWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.color,
    this.filled = false,
  });

  /// Builds the text to read at the moment of the tap.
  final FutureOr<String> Function() text;
  final Color? color;
  final bool filled;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    Speech.instance.speaking.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    if (Speech.instance.speaking.value) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    Speech.instance.speaking.removeListener(_sync);
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    final s = context.s, lang = context.lang;
    if (Speech.instance.speaking.value) {
      await Speech.instance.stop();
      return;
    }
    final text = await widget.text();
    final ok = await Speech.instance.speak(text, lang);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.noVoice)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final speaking = Speech.instance.speaking.value;
    final s = context.s;
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: Icon(
        speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
        key: ValueKey(speaking),
        color: widget.filled ? Colors.white : color,
      ),
    );
    return Tooltip(
      message: speaking ? s.stopListening : s.listen,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => CustomPaint(
          painter: _RingPainter(_pulse.value, color, speaking),
          child: child,
        ),
        child: Material(
          color: widget.filled ? color : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _tap,
            child: Padding(padding: const EdgeInsets.all(10), child: icon),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.color, this.on);
  final double t;
  final Color color;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    if (!on) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (var i = 0; i < 2; i++) {
      final p = (t + i * 0.5) % 1;
      canvas.drawCircle(
        c,
        r * (1 + p * 0.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - p) * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.on != on;
}

/// Text read aloud for a day (uses that year's festival list when loaded).
Future<String> speechFor(BuildContext context, DayPanchanga d) async {
  final f = await context.repo.festivalsOn(d.date);
  if (!context.mounted) return '';
  return daySpeech(context.s, context.lang, context.repo.engine, d, f);
}

/// Hero header: animated Tulunadu landscape with the date on top.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.day,
    required this.isToday,
    required this.festive,
    required this.onPrev,
    required this.onNext,
  });

  final DayPanchanga day;
  final bool isToday;
  final bool festive;
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final now = jdNow();
    double f;
    bool night;
    double elong;
    if (isToday && now >= day.sunrise && now < day.nextSunrise) {
      night = now >= day.sunset;
      f = night
          ? (now - day.sunset) / (day.nextSunrise - day.sunset)
          : (now - day.sunrise) / (day.sunset - day.sunrise);
      elong = elongation(now);
    } else {
      night = false;
      f = 0.42;
      elong = elongation((day.sunrise + day.sunset) / 2);
    }
    final top = MediaQuery.paddingOf(context).top;
    const shadow = [Shadow(blurRadius: 8, color: Colors.black54)];
    final t = Theme.of(context).textTheme;
    return TulunaduScene(
      height: 250 + top,
      dayFraction: f,
      isNight: night,
      moonElongation: elong,
      festive: festive,
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, top + 56, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.chevron_left_rounded, size: 32),
              onPressed: onPrev,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(a),
                    child: c,
                  ),
                ),
                child: FittedBox(
                  key: ValueKey(day.date),
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LipiText(
                        varaNames[day.weekday].of(lang),
                        style: t.titleMedium?.copyWith(
                          color: TuluColors.turmeric,
                          fontWeight: FontWeight.w700,
                          shadows: shadow,
                        ),
                      ),
                      Text(
                        longDate(lang, day.date),
                        textAlign: TextAlign.center,
                        style: t.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: shadow,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _GlassChip(
                        child: LipiText(
                          '${tuluDate(lang, day)} · '
                          '${lunarMonthLabel(lang, day.lunarMonth)} '
                          '${tithiLabel(lang, day.tithi)}',
                          textAlign: TextAlign.center,
                          style: t.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 2),
                          LipiText(
                            context.settings.place.name.of(lang),
                            style: t.bodySmall?.copyWith(
                              color: Colors.white,
                              shadows: shadow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.chevron_right_rounded, size: 32),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: child,
  );
}

/// The day's festivals as a big illustrated card, or a teaser for the next
/// festival when there is none today.
class FestivalBanner extends StatelessWidget {
  const FestivalBanner({super.key, required this.date});
  final DateTime date;

  static bool notable(FestivalOccurrence o) =>
      o.festival.category != FestivalCategory.vrata ||
      o.festival.id == 'ekadashi' ||
      o.festival.id == 'purnima' ||
      o.festival.id == 'amavasya';

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    return FutureBuilder<List<FestivalOccurrence>>(
      future: () async {
        final a = await repo.festivals(date.year);
        final b = date.month == 12
            ? await repo.festivals(date.year + 1)
            : const <FestivalOccurrence>[];
        return [...a, ...b];
      }(),
      builder: (context, snap) {
        final all = snap.data;
        if (all == null) return const SizedBox.shrink();
        var today = all.where((o) => o.date == date && notable(o)).toList();
        // A named festival makes the generic Purnima/Amavasya redundant.
        if (today.any((o) => o.festival.category != FestivalCategory.vrata)) {
          today = today
              .where((o) => o.festival.category != FestivalCategory.vrata)
              .toList();
        }
        if (today.isNotEmpty) {
          return Column(
            children: [for (final o in today) _BannerCard(o: o, daysAway: 0)],
          );
        }
        final next = all.where(
          (o) =>
              o.date.isAfter(date) &&
              o.festival.category != FestivalCategory.vrata &&
              o.festival.category != FestivalCategory.sankramana,
        );
        if (next.isEmpty) return const SizedBox.shrink();
        final o = next.first;
        final n = o.date.difference(date).inDays;
        if (n > 45) return const SizedBox.shrink();
        return _BannerCard(o: o, daysAway: n);
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.o, required this.daysAway});
  final FestivalOccurrence o;
  final int daysAway;

  @override
  Widget build(BuildContext context) {
    final s = context.s, lang = context.lang;
    final t = Theme.of(context).textTheme;
    final kind = artFor(o.festival);
    final today = daysAway == 0;
    final bg = artBackground(kind);
    final dark = bg.computeLuminance() < 0.3;
    final fg = dark ? Colors.white : const Color(0xFF3B2314);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => showFestivalSheet(context, o),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  bg,
                  Color.lerp(
                    bg,
                    today ? TuluColors.turmeric : Colors.white,
                    0.35,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: bg.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Hero(
                    tag: 'art-${o.festival.id}-${o.date}',
                    child: FestivalArt(kind: kind, size: today ? 92 : 68),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: today
                                ? TuluColors.red
                                : fg.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LipiText(
                            today
                                ? s.todayFestival
                                : '${s.comingUp} · ${s.inDays(daysAway)}',
                            style: t.labelMedium?.copyWith(
                              color: today ? Colors.white : fg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        LipiText(
                          o.festival.name.of(lang),
                          style: (today ? t.titleLarge : t.titleMedium)
                              ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (!today)
                          Text(
                            longDate(lang, o.date),
                            style: t.bodySmall?.copyWith(
                              color: fg.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SpeakButton(
                    color: fg,
                    text: () =>
                        '${o.festival.name.of(lang)}. '
                        '${longDate(lang, o.date)}',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with a large animated illustration and the rule used.
Future<void> showFestivalSheet(BuildContext context, FestivalOccurrence o) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final t = Theme.of(ctx), lang = ctx.lang, s = ctx.s;
      final f = o.festival;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'art-${f.id}-${o.date}',
                child: FestivalArt.of(f, size: 160),
              ),
              const SizedBox(height: 14),
              LipiText(
                f.name.of(lang),
                textAlign: TextAlign.center,
                style: t.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(longDate(lang, o.date), style: t.textTheme.titleMedium),
              const SizedBox(height: 8),
              SpeakButton(
                filled: true,
                text: () => [
                  f.name.of(lang),
                  longDate(lang, o.date),
                  if (lang == Lang.en && f.note.isNotEmpty) f.note,
                ].join('. '),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.rule}: ${f.rule.describe()}'),
                      if (o.detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(o.detail),
                      ],
                      if (o.instant != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${s.sankramana}: ${hm(ctx.repo.engine, o.instant!)}',
                        ),
                      ],
                      if (f.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(f.note),
                      ],
                      if (f.confidence == Confidence.low) ...[
                        const SizedBox(height: 8),
                        Text(
                          s.confidenceLow,
                          style: TextStyle(color: t.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A row of three floating diyas/flowers used as a decorative divider.
class FlowerDivider extends StatelessWidget {
  const FlowerDivider({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 18,
    child: CustomPaint(painter: _FlowerPainter(), size: Size.infinite),
  );
}

class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = TuluColors.gold.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(24, y), Offset(size.width / 2 - 26, y), line);
    canvas.drawLine(
      Offset(size.width / 2 + 26, y),
      Offset(size.width - 24, y),
      line,
    );
    for (var k = -1; k <= 1; k++) {
      final c = Offset(size.width / 2 + k * 16, y);
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5;
        canvas.drawCircle(
          c + Offset(math.cos(a) * 3.2, math.sin(a) * 3.2),
          2.4,
          Paint()..color = k == 0 ? TuluColors.red : TuluColors.turmeric,
        );
      }
      canvas.drawCircle(c, 1.8, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_FlowerPainter old) => false;
}
