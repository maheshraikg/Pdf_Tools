/// ✅ / ⚠️ / ❌ PIN-vs-place result with suggested PINs.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../data/mismatch.dart';
import '../../data/models/office.dart';

class MismatchView extends StatefulWidget {
  const MismatchView({super.key, required this.pin, required this.place, this.onPickPin});

  final String pin;
  final String place;
  final ValueChanged<Office>? onPickPin;

  @override
  State<MismatchView> createState() => _MismatchViewState();
}

class _MismatchViewState extends State<MismatchView> {
  MismatchResult? _r;
  int _seq = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(MismatchView old) {
    super.didUpdateWidget(old);
    if (old.pin != widget.pin || old.place != widget.place) _run();
  }

  Future<void> _run() async {
    final seq = ++_seq;
    if (widget.place.trim().length < 2) {
      setState(() => _r = null);
      return;
    }
    final r = await context.services.mismatch.check(widget.pin, widget.place);
    if (mounted && seq == _seq) setState(() => _r = r);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _r;
    if (r == null) return const SizedBox.shrink();
    final (icon, colour, title) = switch (r.level) {
      MismatchLevel.match => (Icons.check_circle, okColor(context), l.mmMatch),
      MismatchLevel.sameDistrict => (Icons.warning_amber, warningColor(context), l.mmSameDistrict),
      MismatchLevel.different => (Icons.cancel, Theme.of(context).colorScheme.error, l.mmDifferent),
      MismatchLevel.unknownPlace => (Icons.help_outline, warningColor(context), l.mmUnknownPlace),
      MismatchLevel.pinNotFound => (Icons.error_outline, warningColor(context), l.pinNotInDirectory),
      MismatchLevel.invalidPin => (Icons.error_outline, Theme.of(context).colorScheme.error, l.invalidPin),
    };
    final placeOffice = r.placeOffices.firstOrNull;
    final pinOffice = r.pinOffices.firstOrNull;
    return Semantics(
      liveRegion: true,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colour, width: 3)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: colour, size: 36),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colour))),
              ]),
              if (pinOffice != null && r.level != MismatchLevel.match)
                Text(l.mmPinIs(widget.pin, '${pinOffice.officeName}, ${pinOffice.district}')),
              if (placeOffice != null && r.level != MismatchLevel.match)
                Text(l.mmPlaceIs(widget.place, '${placeOffice.district}, ${placeOffice.state}')),
              if (r.suggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(l.suggestedPins, style: const TextStyle(fontWeight: FontWeight.w700)),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final o in r.suggestions)
                      ActionChip(
                        label: Text('${o.pin} · ${o.officeName} (${o.district})'),
                        onPressed: widget.onPickPin == null ? null : () => widget.onPickPin!(o),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
