import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/word.dart';
import 'gemini_client.dart';

/// Sends a user's new word to the dictionary team (the AI server stores it
/// for review on its /admin page). Nothing is sent without the user's choice.
class SuggestClient {
  SuggestClient({
    required this.proxyUrl,
    http.Client? client,
    this.fallbackPost = GeminiClient.postViaDoh,
  }) : _client = client ?? http.Client();

  final String proxyUrl;
  final PostFn? fallbackPost;
  final http.Client _client;

  /// Sends [word] with an optional [note]. Throws [AiException] on failure.
  Future<void> send(Word word, {String note = ''}) async {
    final base = proxyUrl.endsWith('/')
        ? proxyUrl.substring(0, proxyUrl.length - 1)
        : proxyUrl;
    final uri = Uri.parse('$base/suggest');
    const headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'tulu': word.tulu,
      'roman': word.roman,
      'kn': word.kn,
      'en': word.en,
      'cat': word.cat,
      'note': note,
    });
    http.Response res;
    try {
      res = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AiException('Sending took too long. Please try again.');
    } on Exception catch (e) {
      if (e is! http.ClientException && e is! IOException) rethrow;
      final fallback = fallbackPost;
      if (fallback == null) throw _offline;
      try {
        res = await fallback(
          uri,
          headers,
          body,
        ).timeout(const Duration(seconds: 20));
      } on Exception {
        throw _offline;
      }
    }
    if (res.statusCode == 200) return;
    String msg = '';
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      msg = ((j['error'] as Map?)?['message'] as String?) ?? '';
    } catch (_) {}
    throw AiException(
      msg.isNotEmpty ? msg : 'Could not send (error ${res.statusCode}).',
    );
  }

  static const _offline = AiException(
    'No internet connection. The word is saved on your phone; '
    'you can send it later from Saved › My words.',
  );
}
