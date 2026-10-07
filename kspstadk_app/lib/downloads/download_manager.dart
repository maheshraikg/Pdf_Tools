import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';

import '../content/links.dart';
import '../data/store.dart';

/// Metadata of a file saved for offline use.
class DownloadRecord {
  const DownloadRecord({
    required this.key,
    required this.url,
    required this.title,
    required this.path,
    required this.bytes,
    required this.savedAt,
    this.postId,
    this.postTitle,
    this.group,
    this.subgroup,
  });

  final String key;
  final String url;
  final String title;
  final String path;
  final int bytes;
  final DateTime savedAt;
  final int? postId;
  final String? postTitle;

  /// Class label (e.g. "4 ನೇ ತರಗತಿ") used to group the library.
  final String? group;

  /// Subject label.
  final String? subgroup;

  bool get isPdf => path.toLowerCase().endsWith('.pdf');
  String get extension => path.contains('.') ? path.split('.').last.toLowerCase() : '';

  factory DownloadRecord.fromJson(Map<String, dynamic> j) => DownloadRecord(
        key: j['key'] as String,
        url: j['url'] as String,
        title: j['title'] as String,
        path: j['path'] as String,
        bytes: j['bytes'] as int? ?? 0,
        savedAt: DateTime.fromMillisecondsSinceEpoch(j['savedAt'] as int),
        postId: j['postId'] as int?,
        postTitle: j['postTitle'] as String?,
        group: j['group'] as String?,
        subgroup: j['subgroup'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'url': url,
        'title': title,
        'path': path,
        'bytes': bytes,
        'savedAt': savedAt.millisecondsSinceEpoch,
        'postId': postId,
        'postTitle': postTitle,
        'group': group,
        'subgroup': subgroup,
      };
}

enum DownloadStatus { idle, running, done, failed }

class DownloadState {
  const DownloadState(this.status, {this.progress, this.error});

  final DownloadStatus status;

  /// 0..1, or null when the size is unknown.
  final double? progress;
  final DownloadError? error;

  static const idle = DownloadState(DownloadStatus.idle);
}

enum DownloadError {
  /// Google returned an HTML page (file not shared publicly, quota, …).
  notPublic,
  network,
  other,
}

class DownloadException implements Exception {
  DownloadException(this.error, [this.message]);

  final DownloadError error;
  final String? message;

  @override
  String toString() => 'DownloadException($error, $message)';
}

/// Context stored with a download so the library can group it.
class DownloadMeta {
  const DownloadMeta({required this.title, this.postId, this.postTitle, this.group, this.subgroup});

  final String title;
  final int? postId;
  final String? postTitle;
  final String? group;
  final String? subgroup;
}

/// Downloads files into app storage and keeps a library of them.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this._box, {Dio? dio, Future<Directory> Function()? baseDir})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 20))),
        _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  final KvBox _box;
  final Dio _dio;
  final Future<Directory> Function() _baseDir;
  final _states = <String, ValueNotifier<DownloadState>>{};
  final _cancel = <String, CancelToken>{};

  /// Called after each successful download (used for the review prompt).
  void Function()? onCompleted;

  List<DownloadRecord> get all {
    final list = [
      for (final v in _box.values)
        if (v is Map) DownloadRecord.fromJson(Map<String, dynamic>.from(v)),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  DownloadRecord? record(String key) {
    final v = _box.get(key);
    if (v is! Map) return null;
    final r = DownloadRecord.fromJson(Map<String, dynamic>.from(v));
    return File(r.path).existsSync() ? r : null;
  }

  int get totalBytes => all.fold(0, (sum, r) => sum + r.bytes);

  ValueListenable<DownloadState> state(String key) => _states.putIfAbsent(
        key,
        () => ValueNotifier(record(key) != null ? const DownloadState(DownloadStatus.done) : DownloadState.idle),
      );

  void _set(String key, DownloadState s) {
    (state(key) as ValueNotifier<DownloadState>).value = s;
  }

  /// Downloads [link] (no-op if already saved) and returns the record.
  Future<DownloadRecord> download(LinkInfo link, DownloadMeta meta) async {
    final existing = record(link.key);
    if (existing != null) return existing;
    if (state(link.key).value.status == DownloadStatus.running) {
      return _waitFor(link.key);
    }
    _set(link.key, const DownloadState(DownloadStatus.running, progress: 0));
    final token = _cancel[link.key] = CancelToken();
    final dir = Directory('${(await _baseDir()).path}/downloads');
    await dir.create(recursive: true);
    final tmp = File('${dir.path}/.${link.key}.part');
    try {
      var url = link.downloadUrl;
      var headers = await _fetch(url, tmp, link.key, token);
      if (await _looksLikeHtml(tmp)) {
        // Drive's virus-scan interstitial: follow its form once.
        final next = _confirmUrl(await tmp.readAsString());
        if (next == null) throw DownloadException(DownloadError.notPublic);
        url = next;
        headers = await _fetch(url, tmp, link.key, token);
        if (await _looksLikeHtml(tmp)) throw DownloadException(DownloadError.notPublic);
      }
      final ext = _extension(headers, link);
      final name = '${_safeName(meta.title)}_${link.key.hashCode.toUnsigned(20)}.$ext';
      final dest = File('${dir.path}/$name');
      await tmp.rename(dest.path);
      final rec = DownloadRecord(
        key: link.key,
        url: link.url,
        title: meta.title,
        path: dest.path,
        bytes: await dest.length(),
        savedAt: DateTime.now(),
        postId: meta.postId,
        postTitle: meta.postTitle,
        group: meta.group,
        subgroup: meta.subgroup,
      );
      await _box.put(link.key, rec.toJson());
      _set(link.key, const DownloadState(DownloadStatus.done, progress: 1));
      notifyListeners();
      onCompleted?.call();
      return rec;
    } catch (e) {
      if (await tmp.exists()) await tmp.delete();
      final err = e is DownloadException
          ? e.error
          : (e is DioException && e.response == null ? DownloadError.network : DownloadError.other);
      _set(link.key, DownloadState(DownloadStatus.failed, error: err));
      if (e is DownloadException) rethrow;
      throw DownloadException(err, '$e');
    } finally {
      _cancel.remove(link.key);
    }
  }

  void cancel(String key) => _cancel[key]?.cancel();

  Future<DownloadRecord> _waitFor(String key) {
    final c = Completer<DownloadRecord>();
    final notifier = state(key);
    void listener() {
      final s = notifier.value;
      if (s.status == DownloadStatus.done) {
        notifier.removeListener(listener);
        c.complete(record(key));
      } else if (s.status == DownloadStatus.failed) {
        notifier.removeListener(listener);
        c.completeError(DownloadException(s.error ?? DownloadError.other));
      }
    }

    notifier.addListener(listener);
    return c.future;
  }

  Future<Headers> _fetch(String url, File to, String key, CancelToken token) async {
    final r = await _dio.download(
      url,
      to.path,
      cancelToken: token,
      options: Options(followRedirects: true, headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android) KSPSTADK-App'}),
      onReceiveProgress: (got, total) {
        _set(key, DownloadState(DownloadStatus.running, progress: total > 0 ? got / total : null));
      },
    );
    return r.headers;
  }

  static Future<bool> _looksLikeHtml(File f) async {
    final raf = await f.open();
    try {
      final head = utf8.decode(await raf.read(512), allowMalformed: true).trimLeft().toLowerCase();
      return head.startsWith('<!doctype html') || head.startsWith('<html');
    } finally {
      await raf.close();
    }
  }

  /// Builds the URL behind Drive's "Download anyway" form.
  static String? _confirmUrl(String html) {
    final doc = html_parser.parse(html);
    final form = doc.querySelector('form#download-form') ?? doc.querySelector('form[action*="download"]');
    if (form == null) return null;
    final action = form.attributes['action'];
    if (action == null) return null;
    final params = {
      for (final i in form.querySelectorAll('input[type=hidden]'))
        if (i.attributes['name'] != null) i.attributes['name']!: i.attributes['value'] ?? '',
    };
    return Uri.parse(action).replace(queryParameters: params).toString();
  }

  static String _extension(Headers h, LinkInfo link) {
    final cd = h.value('content-disposition') ?? '';
    final m = RegExp(r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''', caseSensitive: false).firstMatch(cd);
    if (m != null) {
      final name = Uri.decodeComponent(m.group(1)!);
      if (name.contains('.')) return name.split('.').last.toLowerCase();
    }
    final ct = (h.value('content-type') ?? '').toLowerCase();
    if (ct.contains('pdf')) return 'pdf';
    if (ct.contains('zip')) return 'zip';
    if (ct.contains('spreadsheet')) return 'xlsx';
    if (ct.contains('wordprocessing')) return 'docx';
    if (ct.contains('presentation')) return 'pptx';
    return link.extension ?? 'pdf';
  }

  static String _safeName(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ').replaceAll(RegExp(r'\s+'), '_').trim();
    return cleaned.isEmpty ? 'file' : (cleaned.length > 60 ? cleaned.substring(0, 60) : cleaned);
  }

  Future<void> delete(String key) async {
    final r = record(key);
    if (r != null) {
      final f = File(r.path);
      if (await f.exists()) await f.delete();
    }
    await _box.delete(key);
    _set(key, DownloadState.idle);
    notifyListeners();
  }
}
