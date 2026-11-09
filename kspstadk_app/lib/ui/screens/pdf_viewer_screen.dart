import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

/// In-app PDF viewer (pdfrx, MIT): smooth scrolling, pinch zoom, page jump,
/// night mode and share. Files are always local (downloaded first).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _controller = PdfViewerController();
  int _page = 1;
  int _pages = 0;

  static const _invert = ColorFilter.matrix([
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0,
  ]);

  Future<void> _jump() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.goToPage),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: '1 – $_pages'),
          onSubmitted: (v) => Navigator.pop(c, int.tryParse(v)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, int.tryParse(ctrl.text)), child: Text(l.go)),
        ],
      ),
    );
    if (n != null && n >= 1 && n <= _pages) await _controller.goToPage(pageNumber: n);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.app.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final night = settings.pdfNightMode;
        final viewer = PdfViewer.file(
          widget.path,
          controller: _controller,
          params: PdfViewerParams(
            backgroundColor: night ? const Color(0xFF0B0F1A) : const Color(0xFFE9EDF4),
            pageDropShadow: const BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
            onViewerReady: (doc, c) => setState(() => _pages = doc.pages.length),
            onPageChanged: (p) {
              if (p != null && p != _page) setState(() => _page = p);
            },
            loadingBannerBuilder: (context, bytes, total) => const Center(child: CircularProgressIndicator()),
            errorBannerBuilder: (context, error, stack, ref) =>
                EmptyState(icon: Icons.picture_as_pdf_outlined, title: l.pdfLoadFailed, subtitle: '$error'),
            viewerOverlayBuilder: (context, size, handleLinkTap) => [
              PdfViewerScrollThumb(
                controller: _controller,
                orientation: ScrollbarOrientation.right,
                thumbSize: const Size(44, 28),
                thumbBuilder: (context, thumbSize, pageNumber, controller) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  ),
                  alignment: Alignment.center,
                  child: Text('${pageNumber ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            actions: [
              IconButton(
                tooltip: l.nightMode,
                icon: Icon(night ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: () => settings.setPdfNightMode(!night),
              ),
              IconButton(
                tooltip: l.share,
                icon: const Icon(Icons.share_rounded),
                onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(widget.path)], text: widget.title)),
              ),
            ],
          ),
          body: night ? ColorFiltered(colorFilter: _invert, child: viewer) : viewer,
          floatingActionButton: _pages > 0
              ? FloatingActionButton.extended(
                  heroTag: 'pdf-page',
                  onPressed: _jump,
                  icon: const Icon(Icons.find_in_page_rounded),
                  label: Text(l.pageOf(_page, _pages)),
                )
              : null,
        );
      },
    );
  }
}
