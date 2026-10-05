import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/links.dart';
import '../content/post_content.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import 'downloads/file_actions.dart';
import 'screens/post_list_screen.dart';
import 'screens/post_screen.dart';

Future<void> openPost(BuildContext context, int id, {Post? preview, String? heroTag}) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PostScreen(postId: id, preview: preview, heroTag: heroTag),
  ));
}

Future<void> openCategory(BuildContext context, {required String title, required List<int> ids, Color? color}) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PostListScreen(title: title, categoryIds: ids, color: color),
  ));
}

/// Opens [url] in a Chrome Custom Tab (falls back to the browser).
Future<void> openInApp(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Opens [url] in the app that owns it (YouTube, WhatsApp, Telegram …).
Future<void> openExternal(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Central link router used by post bodies, notifications and deep links.
Future<void> openLink(BuildContext context, String url, {Post? from, String? label}) async {
  final info = classifyLink(url);
  switch (info.kind) {
    case LinkKind.internal:
      await _openInternal(context, info);
    case LinkKind.drive:
    case LinkKind.file:
      await showFileActions(context, FileLink(label: label ?? '', link: info), from: from);
    case LinkKind.youtube:
    case LinkKind.whatsappGroup:
    case LinkKind.telegramGroup:
      await openExternal(info.url);
    case LinkKind.external:
      if (info.url.startsWith('mailto:') || info.url.startsWith('tel:')) {
        await openExternal(info.url);
      } else {
        await openInApp(info.url);
      }
  }
}

Future<void> _openInternal(BuildContext context, LinkInfo info) async {
  final repo = context.app.repo;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = AppLocalizations.of(context);
  final slug = info.slug!;
  try {
    if (slug.startsWith('category/')) {
      final cat = await repo.categoryBySlug(slug.substring(9));
      if (cat != null && context.mounted) {
        await openCategory(context, title: cat.name, ids: [cat.id]);
        return;
      }
    } else {
      final id = await repo.postIdForSlug(slug);
      if (id != null && context.mounted) {
        await openPost(context, id);
        return;
      }
    }
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(l.errorOffline)));
    return;
  }
  // Not a post (a page or archive): show it on the website.
  await openInApp(info.url);
}
