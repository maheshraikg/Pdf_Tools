import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
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

/// A dictionary list row.
class WordTile extends StatelessWidget {
  const WordTile(this.word, {super.key});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Text(
            word.tulu,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          TuluText(word.lipi, size: 20, color: primary),
        ],
      ),
      subtitle: Text(
        '${word.en} · ${word.kn}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: FavouriteButton(word.id),
      onTap: () => openWord(context, word),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.surfaceContainerHighest],
        ),
        border: Border.all(color: cs.tertiary, width: 2),
      ),
      child: Column(
        children: [
          TuluText(
            tulu.isEmpty ? ' ' : tulu,
            size: tuluSize,
            color: cs.onPrimaryContainer,
            textAlign: TextAlign.center,
          ),
          if (kannada != null && kannada!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              kannada!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: cs.onPrimaryContainer),
            ),
          ],
          if (roman != null && roman!.isNotEmpty)
            Text(
              roman!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'ತುಳು ನಿಘಂಟು · Tulu Nighantu',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
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

/// A section heading.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.kannada, this.english, {super.key});

  final String kannada;
  final String english;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      '$kannada · $english',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
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
