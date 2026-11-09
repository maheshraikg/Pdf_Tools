import 'package:flutter/widgets.dart';

import '../app.dart';
import '../notifications/deep_links.dart';
import 'routes.dart';

LinkTarget? _pending;

/// Opens a notification / App Link target on top of the current screen.
/// Targets that arrive before the navigator exists are kept until
/// [flushPendingLink] runs (after the first frame of the shell).
void routeTarget(LinkTarget target) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) {
    _pending = target;
    return;
  }
  switch (target) {
    case PostTarget(:final id):
      openPost(ctx, id);
    case UrlTarget(:final url):
      openLink(ctx, url);
    case HomeTarget():
      Navigator.of(ctx).popUntil((r) => r.isFirst);
  }
}

void flushPendingLink() {
  final t = _pending;
  _pending = null;
  if (t != null) routeTarget(t);
}
