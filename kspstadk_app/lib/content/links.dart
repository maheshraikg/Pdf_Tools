import '../config.dart';

enum LinkKind {
  /// A Google Drive / Docs file.
  drive,

  /// A direct document link (.pdf, .zip, .docx …).
  file,

  /// A post or page on kspstadk.com.
  internal,
  youtube,
  whatsappGroup,
  telegramGroup,
  external,
}

/// A link classified for native rendering.
class LinkInfo {
  const LinkInfo(this.kind, this.url, {this.fileId, this.extension, this.slug, this.videoId});

  final LinkKind kind;
  final String url;

  /// Google Drive file id.
  final String? fileId;

  /// Lower-case extension without the dot (`pdf`, `zip` …), when known.
  final String? extension;

  /// Slug of an internal post/page.
  final String? slug;
  final String? videoId;

  bool get isDownload => kind == LinkKind.drive || kind == LinkKind.file;

  /// Direct download URL. Drive files use the usercontent host with
  /// `confirm=t`, which skips the "can't scan for viruses" page for big files.
  String get downloadUrl {
    if (kind == LinkKind.drive && fileId != null) {
      final docs = RegExp(r'docs\.google\.com/(document|spreadsheets|presentation)/').firstMatch(url);
      if (docs != null) {
        final type = docs.group(1);
        return 'https://docs.google.com/$type/d/$fileId/export?format=${type == 'spreadsheets' ? 'xlsx' : 'pdf'}';
      }
      return 'https://drive.usercontent.google.com/download?id=$fileId&export=download&confirm=t';
    }
    return url;
  }

  /// Stable key for the downloads library.
  String get key => fileId != null ? 'gd_$fileId' : 'url_${url.hashCode.toUnsigned(32)}';
}

const _docExtensions = {'pdf', 'zip', 'rar', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'epub', 'apk'};

final _driveIdPatterns = [
  RegExp(r'drive\.google\.com/file/d/([\w-]{10,})'),
  RegExp(r'drive\.google\.com/(?:uc|open)\?(?:[^#]*&)?id=([\w-]{10,})'),
  RegExp(r'drive\.usercontent\.google\.com/(?:u/\d+/)?(?:download|uc)\?(?:[^#]*&)?id=([\w-]{10,})'),
  RegExp(r'docs\.google\.com/(?:document|spreadsheets|presentation)/d/([\w-]{10,})'),
  RegExp(r'docs\.google\.com/uc\?(?:[^#]*&)?id=([\w-]{10,})'),
];

/// Google Drive file id from any of the link styles the site uses:
/// `uc?export=download&id=ID`, `/file/d/ID/view`, `open?id=ID`,
/// `drive.usercontent.google.com/download?id=ID`, Docs `/d/ID/edit`.
String? driveFileId(String url) {
  final u = url.replaceAll('&amp;', '&').replaceAll('&#038;', '&');
  for (final p in _driveIdPatterns) {
    final m = p.firstMatch(u);
    if (m != null) return m.group(1);
  }
  return null;
}

String? youtubeId(String url) {
  final m = RegExp(r'(?:youtube(?:-nocookie)?\.com/(?:embed/|watch\?(?:[^#]*&)?v=|shorts/|live/)|youtu\.be/)([\w-]{11})')
      .firstMatch(url);
  return m?.group(1);
}

/// Classifies [raw] (as found in an `href`/`src`).
LinkInfo classifyLink(String raw) {
  final url = raw.trim().replaceAll('&amp;', '&').replaceAll('&#038;', '&');
  final uri = Uri.tryParse(url);
  final host = uri?.host.toLowerCase() ?? '';

  final fileId = driveFileId(url);
  if (fileId != null && !url.contains('/drive/folders/')) {
    return LinkInfo(LinkKind.drive, url, fileId: fileId, extension: url.contains('spreadsheets') ? 'xlsx' : null);
  }

  final vid = youtubeId(url);
  if (vid != null) return LinkInfo(LinkKind.youtube, url, videoId: vid);

  if (host == 'chat.whatsapp.com' || (host.endsWith('whatsapp.com') && url.contains('/channel/'))) {
    return LinkInfo(LinkKind.whatsappGroup, url);
  }
  if ((host == 't.me' || host == 'telegram.me') && !(uri?.path.startsWith('/share') ?? false)) {
    return LinkInfo(LinkKind.telegramGroup, url);
  }

  final path = uri?.path.toLowerCase() ?? '';
  final ext = path.contains('.') ? path.split('.').last : '';
  if (_docExtensions.contains(ext)) return LinkInfo(LinkKind.file, url, extension: ext);

  if (AppConfig.siteHosts.contains(host)) {
    final segments = uri!.pathSegments.where((s) => s.isNotEmpty).toList();
    const notPosts = {'category', 'tag', 'author', 'wp-content', 'wp-admin', 'page', 'feed', 'wp-json'};
    if (segments.length == 1 && !notPosts.contains(segments.first)) {
      return LinkInfo(LinkKind.internal, url, slug: segments.first);
    }
    if (segments.length == 2 && segments.first == 'category') {
      return LinkInfo(LinkKind.internal, url, slug: 'category/${segments[1]}');
    }
    return LinkInfo(LinkKind.external, url);
  }
  return LinkInfo(LinkKind.external, url);
}

/// Cleans a button label: drops "ಇಲ್ಲಿ ಕ್ಲಿಕ್ ಮಾಡಿ"/"click here"/"download" filler.
String cleanLinkLabel(String label) {
  var s = label.replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceAll(
      RegExp(r'(ಇಲ್ಲಿ\s*)?ಕ್ಲಿಕ್\s*ಮಾಡಿ|click\s*here(\s*to\s*download)?|download\s*(here|now)|ಡೌನ್\s*‌?ಲೋಡ್\s*ಮಾಡಿ|👇|👉',
          caseSensitive: false),
      '');
  s = s.replaceAll(RegExp(r'\s*[-–:|]\s*$'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}
