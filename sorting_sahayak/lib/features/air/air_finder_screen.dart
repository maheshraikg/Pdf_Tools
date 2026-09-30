/// Air code finder: type a PIN, a city / airport name or a 3-letter code.
/// Uses the office's own air code sheet first (when imported), then the
/// built-in Indian airport list (nearest to the PIN's post office).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/fuzzy.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/pin_utils.dart';
import '../../core/theme.dart';
import '../../data/airports.dart';
import '../../data/models/office.dart';
import '../../data/models/scheme.dart';
import '../../data/resolver.dart';

class AirFinderScreen extends StatefulWidget {
  const AirFinderScreen({super.key});

  @override
  State<AirFinderScreen> createState() => _AirFinderScreenState();
}

class _AirFinderScreenState extends State<AirFinderScreen> {
  final _input = TextEditingController();
  String _q = '';
  int _seq = 0;

  // PIN results.
  List<Office> _offices = [];
  AirCodeRule? _schemeRule;
  List<String> _prefixStates = [];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _changed(String v) async {
    final q = PinUtils.normalizeDigits(v).trim();
    final seq = ++_seq;
    setState(() {
      _q = q;
      _offices = [];
      _schemeRule = null;
      _prefixStates = [];
    });
    final services = context.services;
    final digits = RegExp(r'^\d+$').hasMatch(q);
    if (!digits) return;
    if (q.length == 6 && PinUtils.isValid(q)) {
      final offices = await services.directory.officesForPin(int.parse(q));
      final scheme = services.active;
      AirCodeRule? rule;
      if (scheme != null && !scheme.airResolver.isEmpty) {
        rule = scheme.airResolver
            .resolve(
              ResolveQuery(
                pin: int.parse(q),
                officeNorms: [for (final o in offices) normalizePlace(o.officeName)],
                districtNorms: {for (final o in offices) normalizePlace(o.district)}.toList(),
                stateNorms: {for (final o in offices) normalizePlace(o.state)}.toList(),
              ),
            )
            ?.rule;
      }
      if (!mounted || seq != _seq) return;
      setState(() {
        _offices = offices;
        _schemeRule = rule;
      });
    } else if (q.length >= 2) {
      final s = await services.directory.prefixSummary(q);
      if (!mounted || seq != _seq) return;
      setState(() => _prefixStates = s.states);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.airFinderTitle), scrolledUnderElevation: 0),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            decoration: BoxDecoration(
              gradient: headerGradient(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: TextField(
              key: const ValueKey('air_field'),
              controller: _input,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: c.primary, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: l.airSearchHint,
                hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.onSurfaceVariant, letterSpacing: 0),
                filled: true,
                fillColor: c.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: c.tertiary, width: 3),
                ),
                prefixIcon: const Icon(Icons.flight_takeoff),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.clear,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _input.clear();
                          _changed('');
                        },
                      ),
              ),
              onChanged: _changed,
            ),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 24), children: _results(context, l)),
          ),
        ],
      ),
    );
  }

  List<Widget> _results(BuildContext context, AppLocalizations l) {
    final t = Theme.of(context).textTheme;
    final scheme = context.services.active;
    final schemeAir = scheme?.airResolver.rules ?? const <AirCodeRule>[];
    final q = _q;
    final digits = RegExp(r'^\d+$').hasMatch(q);
    final out = <Widget>[];
    Widget heading(String s) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(s, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );

    if (q.isEmpty) {
      out.add(Text(l.airFinderHelp, style: t.bodyLarge));
      out.add(heading(l.allAirports(kAirports.length)));
      out.addAll(kAirports.map((a) => _AirportTile(airport: a)));
      return out;
    }

    if (digits && q.length == 6) {
      final o = _offices.firstOrNull;
      if (o != null) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.local_post_office_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text('${o.officeName} ${o.officeType} · ${o.district}, ${o.state}', style: t.titleMedium)),
              ],
            ),
          ),
        );
      }
      final rule = _schemeRule;
      if (rule != null) {
        out.add(
          _AirHero(
            code: rule.airCode,
            title: rule.stationName.isNotEmpty ? rule.stationName : (airportByCode(rule.airCode)?.city ?? ''),
            subtitle: [l.fromYourScheme, if (rule.viaHub.isNotEmpty) '${l.via} ${rule.viaHub}'].join(' · '),
          ),
        );
      }
      final near = (o?.latitude != null && o?.longitude != null)
          ? nearestAirports(o!.latitude!, o.longitude!)
          : [
              for (final a in airportsInStates([if (o != null) o.state]).take(3)) (a, -1.0),
            ];
      if (near.isNotEmpty) {
        if (rule == null) {
          final (a, km) = near.first;
          out.add(
            _AirHero(code: a.iata, title: a.city, subtitle: [l.nearestAirport, if (km >= 0) l.kmAway(km.round().toString())].join(' · ')),
          );
          out.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(l.airRefNote, style: t.bodySmall),
            ),
          );
        }
        out.add(heading(l.otherNearbyAirports));
        for (final (a, km) in near.skip(rule == null ? 1 : 0)) {
          out.add(_AirportTile(airport: a, km: km < 0 ? null : km));
        }
      } else if (_offices.isEmpty) {
        out.add(Text(l.pinNotInDirectory, style: t.titleMedium));
      }
      return out;
    }

    // Partial PIN, name or code.
    final matchingRules = schemeAir
        .where((r) {
          if (digits) {
            final m = r.match;
            return switch (m.type) {
              RuleType.exact => '${m.pin}'.startsWith(q),
              RuleType.prefix => m.prefix!.startsWith(q) || q.startsWith(m.prefix!),
              RuleType.range => '${m.pinFrom}'.startsWith(q) || '${m.pinTo}'.startsWith(q),
              _ => false,
            };
          }
          final s = q.toLowerCase();
          return r.airCode.toLowerCase().startsWith(s) ||
              r.stationName.toLowerCase().contains(s) ||
              (r.district ?? '').toLowerCase().contains(s) ||
              (r.state ?? '').toLowerCase().contains(s);
        })
        .take(40)
        .toList();
    if (matchingRules.isNotEmpty) {
      out.add(heading(l.yourAirCodes));
      for (final r in matchingRules) {
        out.add(
          _AirportTile(
            code: r.airCode,
            title: '${r.match.describe(district: r.district, state: r.state)} → ${r.stationName.isNotEmpty ? r.stationName : r.airCode}',
            subtitle: r.viaHub.isNotEmpty ? '${l.via} ${r.viaHub}' : null,
          ),
        );
      }
    }
    final airports = digits ? airportsInStates(_prefixStates) : searchAirports(q);
    if (airports.isNotEmpty) {
      out.add(heading(digits ? l.airportsInState(_prefixStates.join(', ')) : l.airportCodes));
      out.addAll(airports.map((a) => _AirportTile(airport: a)));
    }
    if (out.isEmpty) out.add(Text(digits ? l.typeFullPinForAir : l.noAirportFound, style: t.titleMedium));
    return out;
  }
}

/// Big air code card – the main answer.
class _AirHero extends StatelessWidget {
  const _AirHero({required this.code, required this.title, required this.subtitle});

  final String code;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kSky, kSkyDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kSky.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    code,
                    style: t.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 6, height: 1),
                  ),
                ),
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                Text(subtitle, style: t.titleSmall?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          const Icon(Icons.flight, color: Colors.white, size: 56),
        ],
      ),
    );
  }
}

class _AirportTile extends StatelessWidget {
  const _AirportTile({this.airport, this.km, this.code, this.title, this.subtitle});

  final Airport? airport;
  final double? km;
  final String? code;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final a = airport;
    final sub = subtitle ?? (a == null ? null : [a.airport, a.state, if (km != null) l.kmAway(km!.round().toString())].join(' · '));
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: kSky.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code ?? a!.iata,
              maxLines: 1,
              softWrap: false,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2, color: c.primary),
            ),
          ),
        ),
        title: Text(title ?? a!.city, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: sub == null ? null : Text(sub),
      ),
    );
  }
}
