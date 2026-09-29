import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../schemes/schemes_screen.dart';
import 'about_screen.dart';
import 'airports_screen.dart';
import 'directory_screen.dart';
import 'favourites_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget item(IconData i, String t, String s, Widget page) => ListTile(
      leading: Icon(i, size: 30),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(s),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.navMore)),
      body: ListView(
        children: [
          item(Icons.rule_folder_outlined, l.schemes, l.schemesSub, const SchemesScreen()),
          item(Icons.storage_outlined, l.pinDirectory, l.pinDirectorySub, const DirectoryScreen()),
          item(Icons.star_outline, l.favourites, l.favouritesSub, const FavouritesScreen()),
          item(Icons.flight, l.airportCodes, l.airportCodesSub, const AirportsScreen()),
          item(Icons.settings_outlined, l.settings, l.settingsSub, const SettingsScreen()),
          item(Icons.help_outline, l.help, l.helpSub, const HelpScreen()),
          item(Icons.info_outline, l.about, l.aboutSub, const AboutScreen()),
        ],
      ),
    );
  }
}
