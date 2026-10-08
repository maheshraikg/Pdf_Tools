import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/airports.dart';

/// Public airport IATA code reference (not sorting rules).
class AirportsScreen extends StatefulWidget {
  const AirportsScreen({super.key});

  @override
  State<AirportsScreen> createState() => _AirportsScreenState();
}

class _AirportsScreenState extends State<AirportsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = searchAirports(_q);
    return Scaffold(
      appBar: AppBar(title: Text(l.airportCodes)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.airportSearchHint),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l.airportDisclaimer, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final a = list[i];
                return ListTile(
                  // One line, scaled down if the phone uses large text.
                  leading: SizedBox(
                    width: 84,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        a.iata,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                  title: Text(a.city, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${a.airport} · ${a.state}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
