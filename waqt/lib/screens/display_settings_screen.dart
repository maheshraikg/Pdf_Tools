import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/settings.dart';
import '../ui/widgets.dart';
import 'display_screen.dart';
import 'settings_screen.dart';

/// Pages of the mosque display: name, next-prayer page, timing and
/// announcements.
class DisplaySettingsScreen extends StatelessWidget {
  const DisplaySettingsScreen({super.key});

  Future<String?> _editText(
    BuildContext context,
    String title,
    String initial, {
    bool multiline = false,
  }) => showDialog<String>(
    context: context,
    builder: (context) => _TextDialog(title, initial, multiline: multiline),
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final ann = settings.announcements;

    return Scaffold(
      appBar: AppBar(title: Text(s.displayMode)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.tv),
              label: Text(s.openDisplay),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DisplayScreen()),
              ),
            ),
          ),
          Section(
            children: [
              ListTile(
                leading: const IconBadge(Icons.mosque_outlined),
                title: Text(s.mosqueName),
                subtitle: Text(
                  settings.mosqueName.isEmpty
                      ? s.mosqueNameHint
                      : settings.mosqueName,
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  final v = await _editText(
                    context,
                    s.mosqueName,
                    settings.mosqueName,
                  );
                  if (v != null) {
                    await settings.update((x) => x.mosqueName = v.trim());
                  }
                },
              ),
              SwitchListTile(
                secondary: const IconBadge(Icons.timer_outlined),
                title: Text(s.nextPrayerPage),
                subtitle: Text(s.nextPrayerPageHelp),
                value: settings.displayNextPage,
                onChanged: (v) => settings.update((x) => x.displayNextPage = v),
              ),
              SwitchListTile(
                secondary: const IconBadge(Icons.light_mode_outlined),
                title: Text(s.keepScreenOn),
                subtitle: Text(s.keepScreenOnHelp),
                value: settings.displayKeepOn,
                onChanged: (v) => settings.update((x) => x.displayKeepOn = v),
              ),
              MinutesStepper(
                label: s.secondsPerPage,
                value: settings.displaySeconds,
                min: 5,
                max: 60,
                step: 5,
                unit: s.secondsShort,
                onChanged: (v) => settings.update((x) => x.displaySeconds = v),
              ),
            ],
          ),
          Section(
            title: s.announcements,
            children: [
              for (var i = 0; i < ann.length; i++)
                ListTile(
                  leading: IconBadge(Icons.campaign_outlined),
                  title: Text(
                    ann[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: s.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => settings.update(
                      (x) => x.announcements = [...ann]..removeAt(i),
                    ),
                  ),
                  onTap: () async {
                    final v = await _editText(
                      context,
                      s.announcements,
                      ann[i],
                      multiline: true,
                    );
                    if (v == null) return;
                    await settings.update((x) {
                      final list = [...ann];
                      if (v.trim().isEmpty) {
                        list.removeAt(i);
                      } else {
                        list[i] = v.trim();
                      }
                      x.announcements = list;
                    });
                  },
                ),
              if (ann.length < AppSettings.maxAnnouncements)
                ListTile(
                  leading: IconBadge(Icons.add, color: scheme.tertiary),
                  title: Text(s.addAnnouncement),
                  subtitle: ann.isEmpty ? Text(s.announcementHint) : null,
                  onTap: () async {
                    final v = await _editText(
                      context,
                      s.announcements,
                      '',
                      multiline: true,
                    );
                    if (v != null && v.trim().isNotEmpty) {
                      await settings.update(
                        (x) => x.announcements = [...ann, v.trim()],
                      );
                    }
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
            child: Text(
              s.displayPagesHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog(this.title, this.initial, {this.multiline = false});
  final String title, initial;
  final bool multiline;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLines: widget.multiline ? 5 : 1,
        minLines: 1,
        maxLength: widget.multiline ? 200 : 60,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _c.text),
          child: Text(s.save),
        ),
      ],
    );
  }
}
