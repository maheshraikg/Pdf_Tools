/// Shared result widgets: bag card, Air/Surface badge, air code card, hub
/// route, office tiles, banners.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/office.dart';
import '../data/models/scheme.dart';
import '../data/resolver.dart';
import 'l10n/app_localizations.dart';
import 'labels.dart';
import 'pin_utils.dart';
import 'theme.dart';

Color bagColour(BuildContext context, Bag? bag) => parseColour(bag?.colour) ?? Theme.of(context).colorScheme.primaryContainer;

/// The final bag in huge bold text on the bag colour, with the position
/// (section) in a round badge – the main answer of the app.
class BagCard extends StatelessWidget {
  const BagCard({super.key, required this.bag, this.rule, this.level, this.compact = false});

  final Bag bag;
  final BagRule? rule;
  final RuleType? level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bg = bagColour(context, bag);
    final fg = onColour(bg);
    final t = Theme.of(context).textTheme;
    final dark = Color.lerp(bg, Colors.black, 0.28)!;
    final section = rule?.section ?? '';
    final remarks = rule?.remarks ?? '';
    return Semantics(
      label: '${l.bag}: ${bag.label}${section.isEmpty ? '' : ', ${l.section} $section'}',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bg, dark]),
          borderRadius: BorderRadius.circular(compact ? 16 : 24),
          boxShadow: compact ? null : [BoxShadow(color: bg.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        padding: EdgeInsets.fromLTRB(compact ? 14 : 20, compact ? 12 : 18, compact ? 14 : 16, compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compact)
                        Text(
                          l.bag.toUpperCase(),
                          style: t.labelMedium?.copyWith(color: fg.withValues(alpha: 0.8), letterSpacing: 1.5, fontWeight: FontWeight.w800),
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          bag.code,
                          style: (compact ? t.headlineMedium : t.displayMedium)?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (bag.name.isNotEmpty && bag.name != bag.code)
                        Text(
                          bag.name,
                          style: (compact ? t.titleMedium : t.headlineSmall)?.copyWith(color: fg, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                if (section.isNotEmpty && !compact) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: fg.withValues(alpha: 0.4), width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.section,
                          style: t.labelSmall?.copyWith(color: dark, fontWeight: FontWeight.w700),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              section,
                              style: t.headlineMedium?.copyWith(color: dark, fontWeight: FontWeight.w900, height: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (compact && section.isNotEmpty) Text('${l.section}: $section', style: t.titleMedium?.copyWith(color: fg)),
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_post_office_outlined, size: 20, color: fg.withValues(alpha: 0.9)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      remarks,
                      style: t.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (rule != null && level != null) ...[
              const SizedBox(height: 6),
              Text(l.matchedBy(ruleTypeLabel(l, level!), rule!.describe), style: t.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8))),
            ],
          ],
        ),
      ),
    );
  }
}

/// Parcel label badge: YELLOW "AIR" or BLUE "SURFACE".
class ConnectivityBadge extends StatelessWidget {
  const ConnectivityBadge({super.key, required this.connectivity, this.defaulted = false, this.large = true});

  final Connectivity connectivity;
  final bool defaulted;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final air = connectivity == Connectivity.air;
    final bg = air ? kAirYellow : kSurfaceBlue;
    final fg = air ? Colors.black : Colors.white;
    final text = air ? l.badgeAir : l.badgeSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l.labelBadge(text),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: large ? 14 : 6, horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black26, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(air ? Icons.flight : Icons.local_shipping, color: fg, size: large ? 36 : 20),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: (large ? Theme.of(context).textTheme.headlineMedium : Theme.of(context).textTheme.titleMedium)?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (defaulted)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.connectivityDefaulted,
              style: TextStyle(color: warningColor(context), fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// Air label code in very large letters with copy / speak buttons.
class AirCodeCard extends StatelessWidget {
  const AirCodeCard({super.key, required this.air, this.onSpeak});

  final Resolution<AirCodeRule>? air;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final a = air;
    if (a == null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.onErrorContainer, size: 36),
          title: Text(l.noAirCode, style: t.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer)),
        ),
      );
    }
    final r = a.rule;
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l.airLabelCode, style: t.labelLarge),
                const Spacer(),
                IconButton(
                  tooltip: l.copy,
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: r.airCode));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                  },
                ),
                if (onSpeak != null) IconButton(tooltip: l.readAloud, icon: const Icon(Icons.volume_up), onPressed: onSpeak),
              ],
            ),
            Semantics(
              label: '${l.airLabelCode}: ${r.airCode.split('').join(' ')}',
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(r.airCode, style: t.displayLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 6)),
              ),
            ),
            if (r.stationName.isNotEmpty) Text(r.stationName, style: t.titleLarge),
            if (r.viaHub.isNotEmpty) Text('${l.via}: ${r.viaHub}', style: t.titleMedium),
            if (r.remarks.isNotEmpty) Text(r.remarks, style: t.bodyMedium),
            Text(l.matchedBy(ruleTypeLabel(l, a.level), r.describe), style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// L2 hub → L1 hub (or "Direct to L1 hub").
class HubRouteCard extends StatelessWidget {
  const HubRouteCard({super.key, required this.hub, this.versionName});

  final Resolution<HubRule>? hub;
  final String? versionName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final h = hub;
    if (h == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(leading: const Icon(Icons.hub_outlined), title: Text(versionName == null ? l.noDmsl : l.noHubRoute)),
      );
    }
    final r = h.rule;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.hubRoute, style: t.labelLarge),
            const SizedBox(height: 4),
            if (r.directClosure)
              Text(l.directToL1(r.l1Hub), style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800))
            else
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text('L2: ${r.l2Hub}', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const Icon(Icons.arrow_forward),
                  Text('L1: ${r.l1Hub}', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            if (r.remarks.isNotEmpty) Text(r.remarks, style: t.bodyMedium),
            Text(
              [l.matchedBy(ruleTypeLabel(l, h.level), r.describe), if (versionName != null) l.dmslVersionLabel(versionName!)].join(' · '),
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class OfficeTile extends StatelessWidget {
  const OfficeTile({super.key, required this.office, this.trailing, this.onTap, this.subtitleExtra});

  final Office office;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitleExtra;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final warn = warningColor(context);
    return ListTile(
      onTap: onTap,
      title: Text('${office.officeName} ${office.officeType}', style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${office.pin} · ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: '${officeTypeLabel(l, office.officeType)} · '),
            TextSpan(
              text: office.delivery ? l.delivery : l.nonDelivery,
              style: office.delivery ? null : TextStyle(color: warn, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: '\n${office.district}, ${office.state}'),
            if (subtitleExtra != null)
              TextSpan(
                text: '\n$subtitleExtra',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
      isThreeLine: true,
      trailing: trailing,
    );
  }
}

/// PIN structure: zone · circle · sorting district · delivery office.
class PinBreakdownView extends StatelessWidget {
  const PinBreakdownView({super.key, required this.breakdown});

  final PinBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = breakdown;
    final rows = <(String, String, String)>[
      (b.zoneDigit ?? '', l.pinZone, b.zoneName ?? '—'),
      if (b.circleCode != null) (b.circleCode!, l.pinCircle, b.circleName ?? l.unknown),
      if (b.sortingDistrict != null) (b.sortingDistrict!, l.pinSortingDistrict, l.pinSortingDistrictHelp),
      if (b.deliveryOffice != null) (b.deliveryOffice!, l.pinDeliveryOffice, l.pinDeliveryOfficeHelp),
    ];
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        dense: true,
        shape: const Border(),
        leading: const Icon(Icons.pin_outlined),
        title: Text(l.pinStructure, style: Theme.of(context).textTheme.labelLarge),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        r.$1,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                    ),
                  ),
                  Expanded(child: Text('${r.$2}: ${r.$3}')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.text, this.icon = Icons.warning_amber, this.action});

  final String text;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = warningColor(context);
    return Card(
      margin: EdgeInsets.zero,
      color: c.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: c, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class SampleChip extends StatelessWidget {
  const SampleChip({super.key});

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      AppLocalizations.of(context).sampleBadge,
      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
    ),
    backgroundColor: kAmber,
    visualDensity: VisualDensity.compact,
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

Future<bool> confirm(BuildContext context, String message) async {
  final l = AppLocalizations.of(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.ok)),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));
