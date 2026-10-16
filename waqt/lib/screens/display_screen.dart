import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/scope.dart';
import '../core/alerts.dart';
import '../core/prayer_calc.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Full-screen display for a mosque / prayer-room screen. Pages rotate:
/// the clock with Azan and Iqama times, a big next-prayer countdown and up
/// to five announcements. Keeps the screen on.
class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key, this.keepAwake = true, this.clock});

  /// Off in tests (no platform channels there).
  final bool keepAwake;

  /// Current time (tests); null = the real clock.
  final DateTime Function()? clock;

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    if (widget.keepAwake) {
      WakelockPlus.enable();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    if (widget.keepAwake) {
      WakelockPlus.disable();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  int _seconds = 0;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final now = (widget.clock?.call() ?? DateTime.now()).toUtc();
    final w = settings.wall(now);
    final today = DateTime.utc(w.year, w.month, w.day);
    final days = settings.calculator.days(today, 2);
    final day = days.first;
    final next = nextPrayer(days, now);
    String two(int v) => v.toString().padLeft(2, '0');
    final clock = settings.use24h
        ? '${two(w.hour)}:${two(w.minute)}'
        : '${w.hour % 12 == 0 ? 12 : w.hour % 12}:${two(w.minute)}';
    final clockFull =
        '$clock${settings.use24h ? '' : ' ${amPm(settings.lang, w.hour)}'}';

    // Between Azan and Iqama: big Iqama countdown.
    Prayer? waitingIqama;
    DateTime? iqamaAt;
    for (final p in Prayer.fard) {
      final iq = iqamaTime(day, p, settings.alerts);
      if (now.isAfter(day[p]) && now.isBefore(iq)) {
        waitingIqama = p;
        iqamaAt = iq;
      }
    }

    // Pages: times, next prayer, announcements. They rotate, but from Azan
    // to Iqama (and in the last 5 minutes before Azan) the countdown stays.
    final pages = <String>[
      'times',
      if (settings.displayNextPage) 'next',
      for (var i = 0; i < settings.announcements.length; i++) 'a$i',
    ];
    final soon =
        next != null && next.at.difference(now) <= const Duration(minutes: 5);
    final String page;
    if (waitingIqama != null || soon) {
      page = settings.displayNextPage ? 'next' : 'times';
    } else {
      page =
          pages[(_seconds ~/ settings.displaySeconds.clamp(5, 120)) %
              pages.length];
    }

    const gold = kGold;
    const fg = Colors.white;
    return Scaffold(
      backgroundColor: const Color(0xFF06261D),
      body: GestureDetector(
        onLongPress: () => Navigator.pop(context),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: heroGradient(Brightness.dark)),
          child: CustomPaint(
            painter: IslamicPatternPainter(
              color: Colors.white.withValues(alpha: 0.04),
              cell: 72,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth > box.maxHeight;
                  final unit = (wide ? box.maxHeight : box.maxWidth) / 10;
                  final dateLine =
                      '${longDate(settings.lang, day.date)} · ${hijriLabel(settings.lang, day.hijri)}';
                  final nameLine = settings.mosqueName.trim().isEmpty
                      ? null
                      : Text(
                          settings.mosqueName.trim(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: gold,
                            fontSize: unit * 0.55,
                            fontWeight: FontWeight.w700,
                          ),
                        );

                  Widget timesPage() {
                    final header = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ?nameLine,
                        FittedBox(
                          child: Text(
                            clockFull,
                            style: TextStyle(
                              color: fg,
                              fontSize: unit * 2.2,
                              fontWeight: FontWeight.w300,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          dateLine,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: gold, fontSize: unit * 0.4),
                        ),
                        SizedBox(height: unit * 0.3),
                        if (waitingIqama != null)
                          Text(
                            '${s.prayer(waitingIqama, friday: day.isFriday)} · ${s.iqama} ${clockCountdown(iqamaAt!.difference(now))}',
                            style: TextStyle(
                              color: fg,
                              fontSize: unit * 0.7,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (next != null)
                          Text(
                            '${s.next}: ${s.prayer(next.prayer, friday: next.day.isFriday)} · ${clockCountdown(next.at.difference(now))}',
                            style: TextStyle(color: fg, fontSize: unit * 0.6),
                          ),
                      ],
                    );
                    final table = _Table(
                      unit: unit,
                      rows: [
                        for (final p in Prayer.fard)
                          (
                            name: s.prayer(p, friday: day.isFriday),
                            azan: hm(settings, day[p]),
                            iqama: hm(
                              settings,
                              iqamaTime(day, p, settings.alerts),
                            ),
                            highlight:
                                p == waitingIqama ||
                                (waitingIqama == null &&
                                    next?.prayer == p &&
                                    next?.day == day),
                          ),
                      ],
                      azanLabel: s.azan,
                      iqamaLabel: s.iqama,
                      sunrise:
                          '${s.prayer(Prayer.sunrise)} ${hm(settings, day[Prayer.sunrise])}',
                    );
                    // scaleDown: any screen shape fits without overflow.
                    return wide
                        ? Row(
                            children: [
                              Expanded(child: _Fit(header)),
                              Expanded(
                                child: _Fit(
                                  SizedBox(width: unit * 8, child: table),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _Fit(header),
                              SizedBox(height: unit * 0.4),
                              Expanded(
                                child: _Fit(
                                  SizedBox(width: unit * 9, child: table),
                                ),
                              ),
                            ],
                          );
                  }

                  Widget footer() => Text(
                    '$clockFull · $dateLine',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.75),
                      fontSize: unit * 0.38,
                    ),
                  );

                  Widget nextPage() {
                    final iq = waitingIqama != null;
                    final p = iq ? waitingIqama : next?.prayer;
                    if (p == null) return timesPage();
                    final friday = iq ? day.isFriday : next!.day.isFriday;
                    final at = iq ? iqamaAt! : next!.at;
                    return Column(
                      children: [
                        ?nameLine,
                        Expanded(
                          child: _Fit(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (iq ? s.iqama : s.next).toUpperCase(),
                                  style: TextStyle(
                                    color: gold,
                                    fontSize: unit * 0.55,
                                    letterSpacing: unit * 0.08,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${s.prayer(p, friday: friday)}  ${hm(settings, at)}',
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: unit * 1.1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    clockCountdown(
                                      at.difference(now),
                                      withHours: true,
                                    ),
                                    style: TextStyle(
                                      color: fg,
                                      fontSize: unit * 2.6,
                                      fontWeight: FontWeight.w200,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        footer(),
                      ],
                    );
                  }

                  Widget announcementPage(String text) => Column(
                    children: [
                      ?nameLine,
                      Expanded(
                        child: _Fit(
                          SizedBox(
                            width: unit * (wide ? 14 : 9),
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: fg,
                                fontSize: unit * 0.9,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (next != null)
                        Text(
                          '${s.next}: ${s.prayer(next.prayer, friday: next.day.isFriday)} ${hm(settings, next.at)} · ${clockCountdown(next.at.difference(now))}',
                          style: TextStyle(color: gold, fontSize: unit * 0.45),
                        ),
                      footer(),
                    ],
                  );

                  final Widget body = switch (page) {
                    'times' => timesPage(),
                    'next' => nextPage(),
                    _ => announcementPage(
                      settings.announcements[int.parse(page.substring(1))],
                    ),
                  };
                  return Padding(
                    padding: EdgeInsets.all(unit * 0.3),
                    child: Column(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            child: KeyedSubtree(
                              key: ValueKey(page),
                              child: body,
                            ),
                          ),
                        ),
                        if (pages.length > 1)
                          Padding(
                            padding: EdgeInsets.only(top: unit * 0.15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final p in pages)
                                  Container(
                                    width: unit * 0.12,
                                    height: unit * 0.12,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: unit * 0.06,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: p == page
                                          ? gold
                                          : fg.withValues(alpha: 0.25),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fit extends StatelessWidget {
  const _Fit(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: FittedBox(fit: BoxFit.scaleDown, child: child),
  );
}

class _Table extends StatelessWidget {
  const _Table({
    required this.unit,
    required this.rows,
    required this.azanLabel,
    required this.iqamaLabel,
    required this.sunrise,
  });

  final double unit;
  final List<({String name, String azan, String iqama, bool highlight})> rows;
  final String azanLabel, iqamaLabel, sunrise;

  @override
  Widget build(BuildContext context) {
    const gold = kGold;
    final head = TextStyle(color: gold, fontSize: unit * 0.35);
    Widget cell(String t, TextStyle st, {TextAlign a = TextAlign.end}) =>
        Expanded(
          child: Text(t, style: st, textAlign: a),
        );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            cell('', head, a: TextAlign.start),
            cell(azanLabel, head),
            cell(iqamaLabel, head),
          ],
        ),
        for (final r in rows)
          Container(
            margin: EdgeInsets.symmetric(vertical: unit * 0.06),
            padding: EdgeInsets.symmetric(
              vertical: unit * 0.12,
              horizontal: unit * 0.2,
            ),
            decoration: BoxDecoration(
              color: r.highlight ? const Color(0xFF0E5A43) : null,
              borderRadius: BorderRadius.circular(unit * 0.15),
            ),
            child: Row(
              children: [
                for (final (i, t) in [r.name, r.azan, r.iqama].indexed)
                  cell(
                    t,
                    TextStyle(
                      color: Colors.white,
                      fontSize: unit * (i == 0 ? 0.5 : 0.45),
                      fontWeight: r.highlight
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    a: i == 0 ? TextAlign.start : TextAlign.end,
                  ),
              ],
            ),
          ),
        SizedBox(height: unit * 0.2),
        Text(sunrise, style: head),
      ],
    );
  }
}
