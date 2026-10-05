import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Inbox of received push notifications; each links to its post.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final inbox = context.app.inbox;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: [
          ListenableBuilder(
            listenable: inbox,
            builder: (context, _) => inbox.items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(tooltip: l.clear, icon: const Icon(Icons.delete_sweep_rounded), onPressed: inbox.clear),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: inbox,
        builder: (context, _) {
          final items = inbox.items;
          if (items.isEmpty) {
            return EmptyState(icon: Icons.notifications_none_rounded, title: l.noNotifications, subtitle: l.noNotificationsHint);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final it = items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  semanticLabel: it.title,
                  onTap: () {
                    inbox.markRead(it.id);
                    if (it.postId != null) openPost(context, it.postId!);
                  },
                  padding: const EdgeInsets.all(14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: it.read ? null : Brand.primaryGradient,
                        color: it.read ? t.colorScheme.surfaceContainerHigh : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.campaign_rounded, color: it.read ? t.colorScheme.onSurfaceVariant : Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.title, style: t.textTheme.titleSmall?.copyWith(fontWeight: it.read ? FontWeight.w500 : FontWeight.w700)),
                        if (it.body.isNotEmpty)
                          Text(it.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(friendlyDate(context, it.at), style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
