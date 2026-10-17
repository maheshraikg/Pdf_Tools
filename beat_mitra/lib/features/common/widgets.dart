import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/article_number.dart';
import '../../core/l10n/app_localizations.dart';
import '../../data/models.dart';

extension L10nX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  AppServices get services => read<AppServices>();
  AppState get app => read<AppState>();

  /// Language code in use ("kn", "en", "hi").
  String get lang => Localizations.localeOf(this).languageCode;

  void toast(String msg) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 17))));
  }
}

/// Decrypts and shows a stored place photo.
class PhotoThumb extends StatefulWidget {
  const PhotoThumb(this.fileName, {super.key, this.size = 72, this.fit = BoxFit.cover, this.radius = 12});
  final String? fileName;
  final double size;
  final BoxFit fit;
  final double radius;

  @override
  State<PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<PhotoThumb> {
  Future<Uint8List?>? _f;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(PhotoThumb old) {
    super.didUpdateWidget(old);
    if (old.fileName != widget.fileName) _load();
  }

  void _load() {
    _f = widget.fileName == null ? Future.value(null) : context.services.photos.load(widget.fileName!);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<Uint8List?>(
          future: _f,
          builder: (context, snap) {
            final b = snap.data;
            if (b == null || b.isEmpty) {
              return ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(Icons.home_outlined, size: widget.size * 0.5, color: scheme.onSurfaceVariant),
              );
            }
            return Image.memory(b, fit: widget.fit, gaplessPlayback: true, cacheWidth: (widget.size * 3).round());
          },
        ),
      ),
    );
  }
}

/// Large square tile used on the home screen.
class BigTile extends StatelessWidget {
  const BigTile({super.key, required this.icon, required this.label, required this.onTap, this.color, this.badge});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.primaryContainer;
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark ? Colors.white : Colors.black;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 40, color: fg),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fg),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Badge(
                      label: Text(badge!, style: const TextStyle(fontSize: 14)),
                      largeSize: 24,
                      backgroundColor: scheme.secondary,
                      textColor: scheme.onSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// TextField with a microphone button for voice input.
class VoiceTextField extends StatefulWidget {
  const VoiceTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.icon,
    this.textInputAction,
    this.appendVoice = false,
  });
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final IconData? icon;
  final TextInputAction? textInputAction;

  /// Append the spoken text instead of replacing.
  final bool appendVoice;

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  bool _listening = false;

  Future<void> _listen() async {
    final voice = context.services.voice;
    final l = context.l;
    if (_listening) {
      await voice.stopListening();
      return;
    }
    setState(() => _listening = true);
    final heard = await voice.listenOnce(context.lang, onPartial: (_) {});
    if (!mounted) return;
    setState(() => _listening = false);
    if (heard == null || heard.trim().isEmpty) {
      context.toast(l.voiceNotHeard);
      return;
    }
    final c = widget.controller;
    c.text = widget.appendVoice && c.text.trim().isNotEmpty ? '${c.text.trim()} ${heard.trim()}' : heard.trim();
    c.selection = TextSelection.collapsed(offset: c.text.length);
    widget.onChanged?.call(c.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      minLines: 1,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: IconButton(
          tooltip: _listening ? l.voiceStop : l.voiceInput,
          icon: Icon(_listening ? Icons.stop_circle : Icons.mic, color: _listening ? Colors.red : null),
          onPressed: _listen,
        ),
      ),
    );
  }
}

Future<bool> confirm(BuildContext context, String title, String body, {String? ok, bool danger = false}) async {
  final l = context.l;
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body, style: const TextStyle(fontSize: 17)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok ?? l.ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askText(
  BuildContext context,
  String title, {
  String initial = '',
  String? label,
  bool obscure = false,
  TextInputType? keyboard,
}) async {
  final c = TextEditingController(text: initial);
  final l = context.l;
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.ok)),
      ],
    ),
  );
  return r;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

IconData articleTypeIcon(ArticleType t) => switch (t) {
  ArticleType.letter => Icons.mail_outline,
  ArticleType.registered => Icons.assignment_turned_in_outlined,
  ArticleType.speedPost => Icons.local_shipping_outlined,
  ArticleType.parcel => Icons.inventory_2_outlined,
  ArticleType.moneyOrder => Icons.currency_rupee,
  ArticleType.other => Icons.markunread_mailbox_outlined,
};

String articleTypeLabel(AppLocalizations l, ArticleType t) => switch (t) {
  ArticleType.letter => l.typeLetter,
  ArticleType.registered => l.typeRegistered,
  ArticleType.speedPost => l.typeSpeedPost,
  ArticleType.parcel => l.typeParcel,
  ArticleType.moneyOrder => l.typeMoneyOrder,
  ArticleType.other => l.typeOther,
};

IconData placeTypeIcon(PlaceType t) => switch (t) {
  PlaceType.house => Icons.house_outlined,
  PlaceType.shop => Icons.storefront_outlined,
  PlaceType.office => Icons.business_outlined,
  PlaceType.apartment => Icons.apartment_outlined,
  PlaceType.other => Icons.location_on_outlined,
};

String placeTypeLabel(AppLocalizations l, PlaceType t) => switch (t) {
  PlaceType.house => l.placeHouse,
  PlaceType.shop => l.placeShop,
  PlaceType.office => l.placeOffice,
  PlaceType.apartment => l.placeApartment,
  PlaceType.other => l.placeOther,
};

String reasonLabel(AppLocalizations l, String? code) => switch (reasonFromCode(code)) {
  NotDeliveredReason.doorLocked => l.reasonDoorLocked,
  NotDeliveredReason.addresseeAbsent => l.reasonAbsent,
  NotDeliveredReason.leftShifted => l.reasonLeft,
  NotDeliveredReason.refused => l.reasonRefused,
  NotDeliveredReason.wrongAddress => l.reasonWrongAddress,
  NotDeliveredReason.unclaimed => l.reasonUnclaimed,
  NotDeliveredReason.other => l.reasonOther,
  null => code ?? '',
};

String statusLabel(AppLocalizations l, ArticleStatus s) => switch (s) {
  ArticleStatus.pending => l.statusPending,
  ArticleStatus.delivered => l.statusDelivered,
  ArticleStatus.notDelivered => l.statusNotDelivered,
};

/// Small coloured label, e.g. "Needs signature / OTP".
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.color, this.icon});
  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    final fg = ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
