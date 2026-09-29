import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import '../../data/user_repo.dart';
import '../home_shell.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<Favourite>? _favs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final f = await context.services.user.favourites();
    if (mounted) setState(() => _favs = f);
  }

  Future<void> _addPin() async {
    final l = AppLocalizations.of(context);
    final c = TextEditingController();
    final n = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.addFavourite),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: c, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: l.fPin)),
          TextField(controller: n, decoration: InputDecoration(labelText: l.note)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.save)),
        ],
      ),
    );
    final pin = int.tryParse(c.text);
    if (ok == true && pin != null && c.text.length == 6 && mounted) {
      await context.services.user.addFavouritePin(pin, note: n.text.trim());
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = _favs;
    return Scaffold(
      appBar: AppBar(title: Text(l.favourites)),
      floatingActionButton: FloatingActionButton(tooltip: l.addFavourite, onPressed: _addPin, child: const Icon(Icons.add)),
      body: f == null
          ? const Center(child: CircularProgressIndicator())
          : f.isEmpty
          ? EmptyState(icon: Icons.star_outline, text: l.noFavourites)
          : ListView(
              children: [
                for (final x in f)
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text('${x.pin}${x.officeName.isEmpty ? '' : ' · ${x.officeName}'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    subtitle: Text([x.district, x.state, x.note].where((s) => s.isNotEmpty).join(' · ')),
                    onTap: () {
                      Navigator.popUntil(context, (r) => r.isFirst);
                      HomeShell.of(context)?.openSort('${x.pin}');
                    },
                    trailing: IconButton(
                      tooltip: l.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await context.services.user.removeFavourite(x.id!);
                        await _load();
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
