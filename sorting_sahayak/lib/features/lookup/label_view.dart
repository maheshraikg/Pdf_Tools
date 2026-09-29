/// Big label card (air code, PIN, office, district, bag, Air/Surface) for
/// reading from a distance; share as image or text. No printer needed.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/files.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models/scheme.dart';
import '../../data/sort_engine.dart';

String labelText(AppLocalizations l, SortResult r) {
  final o = r.offices.firstOrNull;
  return [
    if (r.air != null) '${l.airLabelCode}: ${r.air!.rule.airCode}${r.air!.rule.stationName.isEmpty ? '' : ' (${r.air!.rule.stationName})'}',
    if (r.connectivity != null) '${l.labelBadgeShort}: ${r.connectivity == Connectivity.air ? l.badgeAir : l.badgeSurface}',
    'PIN: ${r.digits}',
    if (o != null) '${l.fOffice}: ${o.officeName} ${o.officeType}',
    if (o != null) '${l.fDistrict}: ${o.district}, ${o.state}',
    if (r.bag != null) '${l.bag}: ${r.bag!.label}',
    if (r.hub != null) '${l.hubRoute}: ${r.hub!.rule.route}',
    categoryLabel(l, r.category),
  ].join('\n');
}

class LabelViewScreen extends StatefulWidget {
  const LabelViewScreen({super.key, required this.result});

  final SortResult result;

  @override
  State<LabelViewScreen> createState() => _LabelViewScreenState();
}

class _LabelViewScreenState extends State<LabelViewScreen> {
  final _key = GlobalKey();

  Future<void> _shareImage() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return;
    await shareFiles({'label_${widget.result.digits}.png': data.buffer.asUint8List()});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = widget.result;
    final o = r.offices.firstOrNull;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.labelView),
        actions: [
          IconButton(tooltip: l.shareImage, icon: const Icon(Icons.image), onPressed: _shareImage),
          IconButton(tooltip: l.shareText, icon: const Icon(Icons.text_snippet), onPressed: () => shareText(labelText(l, r))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: RepaintBoundary(
          key: _key,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (r.connectivity != null) ConnectivityBadge(connectivity: r.connectivity!),
                  if (r.air != null) ...[
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(r.air!.rule.airCode, style: const TextStyle(fontSize: 120, fontWeight: FontWeight.w900, letterSpacing: 10, color: Colors.black)),
                    ),
                    if (r.air!.rule.stationName.isNotEmpty)
                      Text(r.air!.rule.stationName, textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(color: Colors.black)),
                  ],
                  const Divider(color: Colors.black54, thickness: 2),
                  FittedBox(
                    child: Text(r.digits, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.black)),
                  ),
                  if (o != null)
                    Text('${o.officeName} ${o.officeType}\n${o.district}, ${o.state}',
                        textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w700)),
                  if (r.hub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(r.hub!.rule.directClosure ? l.directToL1(r.hub!.rule.l1Hub) : r.hub!.rule.route,
                          textAlign: TextAlign.center, style: t.titleLarge?.copyWith(color: Colors.black)),
                    ),
                  if (r.bag != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: parseColour(r.bag!.colour) ?? Colors.black12,
                      child: Text(r.bag!.label, textAlign: TextAlign.center,
                          style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: onColour(parseColour(r.bag!.colour) ?? Colors.white))),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(categoryLabel(l, r.category), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
