import 'package:flutter/material.dart';

import '../lipi/tulu_lipi.dart';
import '../panchanga/engine.dart';
import '../panchanga/names.dart';
import 'repo.dart';
import 'settings.dart';
import 'strings.dart';

/// Gives widgets access to the settings, strings and the panchanga repo for
/// the current place and conventions.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings settingsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static final Expando<PanchangaRepo> _repos = Expando();

  /// Repo for the current place/config (recreated when they change).
  static PanchangaRepo repoOf(BuildContext context) =>
      repoFor(settingsOf(context));

  static PanchangaRepo repoFor(AppSettings s) {
    final r = _repos[s];
    if (r != null && r.place == s.place && r.config == s.config) return r;
    return _repos[s] = PanchangaRepo(s.place, s.config);
  }
}

extension AppContext on BuildContext {
  AppSettings get settings => AppScope.settingsOf(this);
  S get s => S(settings.lang);
  PanchangaRepo get repo => AppScope.repoOf(this);
  Lang get lang => settings.lang;

  /// Text of [name] in the current language (Tulu lipi applied by
  /// [LipiText]).
  String n(Name name) => name.of(lang);
}

/// Text that switches to Tulu-Tigalari script when the language is Tulu and
/// the lipi toggle is on.
class LipiText extends StatelessWidget {
  const LipiText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final lipi = context.settings.useTuluLipi && TuluLipi.hasKannada(text);
    if (!lipi) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow,
      );
    }
    // The Tigalari font only for Tigalari runs; digits and punctuation keep
    // the normal font.
    final converted = TuluLipi.fromKannada(text);
    final spans = <TextSpan>[];
    final buf = StringBuffer();
    bool? inTulu;
    void flush() {
      if (buf.isEmpty) return;
      spans.add(
        TextSpan(
          text: buf.toString(),
          style: inTulu == true
              ? const TextStyle(fontFamily: kTuluFontFamily)
              : null,
        ),
      );
      buf.clear();
    }

    for (final r in converted.runes) {
      final tulu = r >= 0x11380 && r <= 0x113FF;
      if (tulu != inTulu) {
        flush();
        inTulu = tulu;
      }
      buf.writeCharCode(r);
    }
    flush();
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}

/// Converts plain text for places where a widget can't be used (share text,
/// notifications use Kannada script — fonts there are not under our control).
String hm(PanchangaEngine e, double jd) {
  final w = e.wall(jd);
  return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
}

/// Time, with a "next day" marker when [jd] falls after the civil [day].
String hmDay(BuildContext context, PanchangaEngine e, double jd, DateTime day) {
  final w = e.wall(jd);
  final t = hm(e, jd);
  final diff = PanchangaEngine.dateOnly(w).difference(day).inDays;
  if (diff == 0) return t;
  if (diff == 1) return '$t (${context.s.nextDay})';
  return '$t (${w.day}/${w.month})';
}

String gregMonthName(Lang lang, int month) =>
    gregorianMonthNames[month - 1].of(lang);

String longDate(Lang lang, DateTime d) =>
    '${d.day} ${gregMonthName(lang, d.month)} ${d.year}';

/// "Shukla Navami" style label for tithi [i] (0..29).
String tithiLabel(Lang lang, int i) {
  if (i == 14 || i == 29) return tithiName(i).of(lang);
  return '${pakshaNames[i < 15 ? 0 : 1].of(lang).split(' ').first} '
      '${tithiName(i).of(lang)}';
}

/// "Paggu 12" style Tulu date.
String tuluDate(Lang lang, DayPanchanga d) =>
    '${tuluMonthNames[d.solar.month].of(lang)} ${d.solar.day}';

String lunarMonthLabel(Lang lang, LunarMonth m) =>
    '${m.adhika ? '${adhikaName.of(lang)} ' : ''}${lunarMonthNames[m.index].of(lang)}';

/// Today's civil date at the selected place.
DateTime todayAt(PanchangaEngine e) => PanchangaEngine.dateOnly(
  DateTime.now().toUtc().add(e.offsetAtUtc(DateTime.now().toUtc())),
);
