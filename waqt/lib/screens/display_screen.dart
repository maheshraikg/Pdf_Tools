import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/scope.dart';
import '../core/alerts.dart';
import '../core/prayer_calc.dart';

/// Full-screen clock for a mosque / prayer-room screen: current time,
/// date, next prayer countdown, Azan and Iqama times. Keeps the screen on.
class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key, this.keepAwake = true});

  /// Off in tests (no platform channels there).
  final bool keepAwake;

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final now = DateTime.now().toUtc();
    final today = settings.today;
    final days = settings.calculator.days(today, 2);
    final day = days.first;
    final next = nextPrayer(days, now);
    final w = settings.wall(now);
    String two(int v) => v.toString().padLeft(2, '0');
    final clock = settings.use24h
        ? '${two(w.hour)}:${two(w.minute)}'
        : '${w.hour % 12 == 0 ? 12 : w.hour % 12}:${two(w.minute)}';

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

    const gold = Color(0xFFE8C468);
    const fg = Colors.white;
    return Scaffold(
      backgroundColor: const Color(0xFF06261D),
      body: GestureDetector(
        onLongPress: () => Navigator.pop(context),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > box.maxHeight;
              final unit = (wide ? box.maxHeight : box.maxWidth) / 10;
              final header = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    child: Text(
                      '$clock${settings.use24h ? '' : (w.hour < 12 ? ' AM' : ' PM')}',
                      style: TextStyle(
                        color: fg,
                        fontSize: unit * 2.2,
                        fontWeight: FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    '${longDate(settings.lang, day.date)} · ${day.hijri.day} ${day.hijri.monthName(s.ml)} ${day.hijri.year}',
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
                      iqama: hm(settings, iqamaTime(day, p, settings.alerts)),
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
              return Padding(
                padding: EdgeInsets.all(unit * 0.3),
                // scaleDown: any screen shape fits without overflow.
                child: wide
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
                      ),
              );
            },
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
    const gold = Color(0xFFE8C468);
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
