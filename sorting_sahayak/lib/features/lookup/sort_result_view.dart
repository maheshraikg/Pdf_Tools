/// The full answer for one PIN: air code, badge, hub route, bag, offices and
/// PIN structure. Shared by Sort, Scan and Find PIN.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/constants.dart';
import '../../core/feedback.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/pin_utils.dart';
import '../../core/widgets.dart';
import '../../data/sort_engine.dart';

class SortResultView extends StatelessWidget {
  const SortResultView({super.key, required this.result, this.showBreakdown = true});

  final SortResult result;
  final bool showBreakdown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = result;
    final services = context.services;
    final scheme = services.active;
    const gap = SizedBox(height: 10);
    final children = <Widget>[];

    if (r.digits.isEmpty) return const SizedBox.shrink();
    if (r.breakdown == null && !r.valid) {
      children.add(WarningBanner(text: l.invalidPin, icon: Icons.error_outline));
    } else if (!r.complete) {
      // Partial PIN: sorting district + likely bag.
      final s = r.prefixSummary;
      if (s != null) {
        children.add(Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l.sortingDistrictN(r.digits.substring(0, 3)), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(s.districts.isEmpty ? l.prefixNotInDirectory : '${s.districts.take(5).join(', ')}${s.districts.length > 5 ? '…' : ''}\n${s.states.join(', ')}'),
          ),
        ));
        children.add(gap);
      }
      if (r.likelyBag != null) {
        children.add(Text(l.likelyBag, style: Theme.of(context).textTheme.labelLarge));
        children.add(BagCard(bag: r.likelyBag!, compact: true));
        children.add(gap);
      }
      if (r.possibleBags.length > 1) {
        children.add(Wrap(spacing: 6, runSpacing: 4, children: [
          Text('${l.possibleBags}: '),
          for (final b in r.possibleBags) Chip(label: Text(b.code), backgroundColor: bagColour(context, b).withValues(alpha: 0.35), visualDensity: VisualDensity.compact),
        ]));
        children.add(gap);
      }
    } else {
      final air = isAirCategory(r.category);
      if (air) {
        children.add(AirCodeCard(
          air: r.air,
          onSpeak: r.air == null ? null : () => AppFeedback.speak(context.settings, AppFeedback.spell(r.air!.rule.airCode), force: true),
        ));
        children.add(gap);
      }
      if (r.connectivity != null) {
        children.add(ConnectivityBadge(connectivity: r.connectivity!, defaulted: r.connectivityDefaulted));
        children.add(gap);
      }
      if (isParcelCategory(r.category) && scheme != null) {
        children.add(HubRouteCard(hub: r.hub, versionName: scheme.dmsl?.versionName));
        children.add(gap);
      }
      if (scheme == null) {
        children.add(WarningBanner(text: l.noActiveScheme, icon: Icons.rule_folder_outlined));
        children.add(gap);
      } else if (r.bag != null) {
        children.add(BagCard(bag: r.bag!, rule: r.bagRule, level: r.bagLevel));
        children.add(gap);
      } else {
        children.add(WarningBanner(text: l.noBagRule));
        children.add(gap);
      }
      if (r.notInDirectory) {
        children.add(WarningBanner(text: l.pinNotInDirectory));
        children.add(gap);
      }
      if (r.offices.isNotEmpty) {
        children.add(Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(l.deliveryOfficesN(r.offices.length), style: Theme.of(context).textTheme.labelLarge),
              ),
              for (final o in r.offices.take(12)) OfficeTile(office: o),
              if (r.offices.length > 12) Padding(padding: const EdgeInsets.all(12), child: Text(l.andMore(r.offices.length - 12))),
            ],
          ),
        ));
        children.add(gap);
      }
    }
    if (showBreakdown && r.breakdown != null) children.add(PinBreakdownView(breakdown: r.breakdown!));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

/// Text to read out after a full PIN: "Bag 12" / air code spelled.
String spokenResult(AppLocalizations l, SortResult r) {
  final parts = <String>[];
  if (r.air != null) parts.add(AppFeedback.spell(r.air!.rule.airCode));
  if (r.bag != null) parts.add(AppFeedback.spellDigits(r.bag!.code));
  if (r.bag == null && r.air == null && PinUtils.isValid(r.digits)) parts.add(l.noBagRule);
  return parts.join('. ');
}
