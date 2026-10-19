import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/settings.dart';
import '../core/masjid.dart';
import '../ui/widgets.dart';
import 'alerts_screen.dart';

/// Mosque profiles: add, rename, describe, delete and pick the active one.
class MasjidsScreen extends StatelessWidget {
  const MasjidsScreen({super.key});

  Future<(String, String)?> _edit(
    BuildContext context,
    String title,
    String name,
    String description,
  ) => showDialog<(String, String)>(
    context: context,
    builder: (_) => _MasjidDialog(title, name, description),
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    // No profiles yet: the current Iqama settings are "Masjid 1".
    final list = settings.masjids.isEmpty
        ? [Masjid.fromAlerts(s.masjidN(1), '', settings.alerts)]
        : settings.masjids;
    final active = settings.masjids.isEmpty ? 0 : settings.activeMasjid;

    Future<void> ensure() async {
      if (settings.masjids.isEmpty) {
        await settings.update((x) {
          x.masjids = [list.first];
          x.activeMasjid = 0;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.masjids)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              s.masjidsHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Section(
            children: [
              for (var i = 0; i < list.length; i++)
                ListTile(
                  leading: IconBadge(
                    i == active ? Icons.mosque : Icons.mosque_outlined,
                    color: i == active ? null : scheme.outline,
                  ),
                  title: Text(
                    list[i].name,
                    style: TextStyle(
                      fontWeight: i == active ? FontWeight.w700 : null,
                    ),
                  ),
                  subtitle: Text(
                    list[i].description.isEmpty
                        ? s.noDescription
                        : list[i].description,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: s.edit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final v = await _edit(
                            context,
                            s.edit,
                            list[i].name,
                            list[i].description,
                          );
                          if (v == null) return;
                          await ensure();
                          await settings.update((x) {
                            x.masjids = [...x.masjids]
                              ..[i] = x.masjids[i].copyWith(
                                name: v.$1.isEmpty ? x.masjids[i].name : v.$1,
                                description: v.$2,
                              );
                          });
                        },
                      ),
                      if (list.length > 1)
                        IconButton(
                          tooltip: s.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => settings.removeMasjid(i),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await ensure();
                    await settings.selectMasjid(i);
                  },
                ),
              if (list.length < AppSettings.maxMasjids)
                ListTile(
                  leading: IconBadge(Icons.add, color: scheme.tertiary),
                  title: Text(s.addMasjid),
                  onTap: () async {
                    final v = await _edit(
                      context,
                      s.addMasjid,
                      s.masjidN(list.length + 1),
                      '',
                    );
                    if (v == null) return;
                    await ensure();
                    await settings.update((x) {
                      x.masjids = [
                        ...x.masjids,
                        Masjid.fromAlerts(
                          v.$1.isEmpty ? s.masjidN(x.masjids.length + 1) : v.$1,
                          v.$2,
                          x.alerts,
                        ),
                      ];
                    });
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.schedule),
              label: Text(s.editIqamaOf(list[active].name)),
              onPressed: () async {
                await ensure();
                if (!context.mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MasjidDialog extends StatefulWidget {
  const _MasjidDialog(this.title, this.name, this.description);
  final String title, name, description;

  @override
  State<_MasjidDialog> createState() => _MasjidDialogState();
}

class _MasjidDialogState extends State<_MasjidDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _desc = TextEditingController(text: widget.description);

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(labelText: s.masjidName),
          ),
          TextField(
            controller: _desc,
            maxLength: 60,
            decoration: InputDecoration(labelText: s.masjidDescription),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (_name.text.trim(), _desc.text.trim())),
          child: Text(s.save),
        ),
      ],
    );
  }
}
