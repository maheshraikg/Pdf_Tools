import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../audio/speaker.dart';
import '../lipi/tulu_lipi.dart';
import '../models/word.dart';
import '../screens/word_detail_screen.dart';

/// Text rendered in the Tulu-Tigalari font.
class TuluText extends StatelessWidget {
  const TuluText(
    this.text, {
    super.key,
    this.size = 24,
    this.color,
    this.textAlign,
  });

  final String text;
  final double size;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    style: TextStyle(
      fontFamily: kTuluFontFamily,
      fontSize: size,
      height: 1.4,
      color: color,
    ),
  );
}

/// Speaks [text] (Kannada-script Tulu) with the device's Kannada voice.
class SpeakButton extends StatelessWidget {
  const SpeakButton(this.text, {super.key, this.size = 24, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'ಕೇಳಿ · Listen',
    iconSize: size,
    color: color ?? Theme.of(context).colorScheme.primary,
    icon: const Icon(Icons.volume_up_rounded),
    onPressed: () => speakText(context, text),
  );
}

/// Speaks [text]; shows how to install a Kannada voice if none is present.
Future<void> speakText(BuildContext context, String text) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await Speaker.instance.speak(text);
  if (!ok) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'ಕನ್ನಡ ಧ್ವನಿ ಇಲ್ಲ · No Kannada voice found. Install it in '
            'Settings › Text-to-speech › Speech Services by Google.',
          ),
        ),
      );
  }
}

/// A row of 0–3 stars.
class StarRow extends StatelessWidget {
  const StarRow(this.stars, {super.key, this.size = 14});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: c,
          ),
      ],
    );
  }
}

/// Bookmark toggle bound to [AppState] favourites.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton(this.wordId, {super.key});

  final String wordId;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final fav = s.isFavourite(wordId);
        return IconButton(
          tooltip: fav ? 'ತೆಗೆದುಹಾಕಿ · Remove' : 'ಉಳಿಸಿ · Save',
          icon: Icon(fav ? Icons.bookmark : Icons.bookmark_border),
          color: fav ? Theme.of(context).colorScheme.primary : null,
          onPressed: () => s.toggleFavourite(wordId),
        );
      },
    );
  }
}

/// First Tulu-lipi syllable of [lipi] (base letter plus following signs).
String firstSyllable(String lipi) {
  final runes = lipi.runes.toList();
  if (runes.isEmpty) return '';
  var end = 1;
  while (end < runes.length && runes[end] >= 0x113B8 && runes[end] <= 0x113D5) {
    end++;
  }
  return String.fromCharCodes(runes.take(end));
}

/// Rounded badge showing a Tulu-lipi glyph.
class GlyphBadge extends StatelessWidget {
  const GlyphBadge(this.glyph, {super.key, this.size = 52});

  final String glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: TuluText(
            glyph,
            size: size * 0.5,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// A dictionary list row, drawn as a card.
class WordTile extends StatelessWidget {
  const WordTile(this.word, {super.key});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: () => openWord(context, word),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              GlyphBadge(firstSyllable(word.lipi)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          word.tulu,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (word.roman.isNotEmpty)
                          Text(
                            word.roman,
                            style: tt.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    TuluText(word.lipi, size: 18, color: cs.primary),
                    Text(
                      '${word.en} · ${word.kn}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FavouriteButton(word.id),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the detail screen for [word].
void openWord(BuildContext context, Word word) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => WordDetailScreen(word: word)));
}

/// A decorated card that can be captured as an image for sharing.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.tulu,
    this.kannada,
    this.roman,
    this.tuluSize = 44,
  });

  final String tulu;
  final String? kannada;
  final String? roman;
  final double tuluSize;

  /// Brand colours: the card looks the same in light and dark mode so
  /// shared images are consistent.
  static const _red = Color(0xFFB3261E);
  static const _deepRed = Color(0xFF7A1410);
  static const _yellow = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_red, _deepRed],
        ),
        boxShadow: [
          BoxShadow(
            color: _deepRed.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -40, child: _circle(140, 0.10)),
          Positioned(left: -30, bottom: -50, child: _circle(120, 0.07)),
          Column(
            children: [
              Container(height: 6, color: _yellow),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Column(
                  children: [
                    TuluText(
                      tulu.isEmpty ? ' ' : tulu,
                      size: tuluSize,
                      color: Colors.white,
                      textAlign: TextAlign.center,
                    ),
                    if (kannada != null && kannada!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        kannada!,
                        textAlign: TextAlign.center,
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (roman != null && roman!.isNotEmpty)
                      Text(
                        roman!,
                        textAlign: TextAlign.center,
                        style: tt.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 18, height: 2, color: _yellow),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ತುಳು ನಿಘಂಟು · Tulu Nighantu',
                            textAlign: TextAlign.center,
                            style: tt.labelSmall?.copyWith(
                              color: _yellow,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 18, height: 2, color: _yellow),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double d, double alpha) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

/// Captures the [RepaintBoundary] behind [key] as PNG and opens the share
/// sheet.
Future<void> shareBoundaryAsImage(
  BuildContext context,
  GlobalKey key,
  String name,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    if (data == null) throw StateError('encoding failed');
    final Uint8List bytes = data.buffer.asUint8List();
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'image/png', name: '$name.png'),
        ],
        fileNameOverrides: ['$name.png'],
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('ಹಂಚಲು ಆಗಲಿಲ್ಲ · Could not share ($e)')),
    );
  }
}

/// Copies [text] and shows a confirmation snackbar.
Future<void> copyText(BuildContext context, String text, String what) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what ನಕಲಿಸಲಾಗಿದೆ · copied')));
}

/// A section heading with an accent bar.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.kannada, this.english, {super.key});

  final String kannada;
  final String english;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: cs.tertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: kannada,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: '  $english',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty-state illustration with a message.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small italic note about data verification.
class DataNote extends StatelessWidget {
  const DataNote({super.key});

  @override
  Widget build(BuildContext context) {
    final note = AppState.instance.dataNote;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note.isEmpty
                  ? 'Sample list – verified by native speakers before publishing'
                  : note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
