import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../lipi/tulu_lipi.dart';
import '../models/word.dart';

/// Default Gemini model; users can change it in Settings.
const String kDefaultGeminiModel = 'gemini-flash-latest';

/// Built-in AI server (the Cloudflare Worker in backend/ai-worker), set at
/// build time: `flutter build apk --dart-define=AI_PROXY_URL=https://…`.
/// Empty means no built-in AI; users can still add their own key.
const String kAiProxyUrl = String.fromEnvironment('AI_PROXY_URL');

/// An AI (unverified) Tulu answer.
class AiAnswer {
  const AiAnswer({
    required this.tulu,
    required this.roman,
    required this.en,
    required this.kn,
    required this.notes,
    required this.confidence,
  });

  factory AiAnswer.fromJson(Map<String, dynamic> j) => AiAnswer(
    tulu: (j['tulu'] as String? ?? '').trim(),
    roman: (j['roman'] as String? ?? '').trim(),
    en: (j['english'] as String? ?? '').trim(),
    kn: (j['kannada'] as String? ?? '').trim(),
    notes: (j['notes'] as String? ?? '').trim(),
    confidence: (j['confidence'] as String? ?? 'low').trim().toLowerCase(),
  );

  /// Tulu in Kannada script.
  final String tulu;
  final String roman;

  /// English and Kannada meaning of the Tulu answer.
  final String en;
  final String kn;

  /// Short usage / grammar note.
  final String notes;

  /// "high", "medium" or "low" (the model's own estimate).
  final String confidence;

  /// Tulu in Tulu-Tigalari script.
  String get lipi => TuluLipi.fromKannada(tulu);
}

/// Sends a POST request; used for the AI server fallback.
typedef PostFn = Future<http.Response> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

/// A friendly, displayable AI error.
class AiException implements Exception {
  const AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Minimal client for the Gemini `generateContent` REST API.
///
/// The key is supplied by the user at runtime (Settings) and sent only to
/// Google's API. Nothing is sent unless the user taps "Ask AI".
class GeminiClient {
  /// Calls Gemini directly with the user's own [apiKey].
  GeminiClient({
    required String this.apiKey,
    this.model = kDefaultGeminiModel,
    http.Client? client,
  }) : proxyUrl = null,
       fallbackPost = null,
       _client = client ?? http.Client();

  /// Calls the built-in AI server, which holds the key.
  GeminiClient.proxy({
    required String this.proxyUrl,
    http.Client? client,
    this.fallbackPost = postViaDoh,
  }) : apiKey = null,
       model = kDefaultGeminiModel,
       _client = client ?? http.Client();

  final String? apiKey;
  final String? proxyUrl;
  final String model;
  final http.Client _client;

  /// Second attempt when the AI server can't be reached (proxy mode only).
  final PostFn? fallbackPost;

  // Keep in sync with SYSTEM_PROMPT in backend/ai-worker/src/index.js.
  static const _system =
      'You are a careful Tulu language assistant for a Tulu–Kannada–English '
      'dictionary app. Tulu must be written in Kannada script (never in '
      'Malayalam or Latin script). Translate the user\'s Kannada or English '
      'text into natural Tulu (Tulunadu common dialect). Prefer the words in '
      'the provided verified glossary when they fit. Do not invent words: if '
      'you are unsure, give your best guess, say so in "notes" and set '
      'confidence to "low". Reply ONLY with JSON: {"tulu": string, "roman": '
      'string (simple romanisation), "english": string (English meaning of '
      'your Tulu), "kannada": string (Kannada meaning), "notes": string (one '
      'or two short sentences on usage or grammar), "confidence": "high" | '
      '"medium" | "low"}.';

  /// Builds the user prompt with dictionary [glossary] entries as context.
  static String buildPrompt(String text, List<Word> glossary) {
    final b = StringBuffer('Text to translate into Tulu: ${text.trim()}\n');
    if (glossary.isNotEmpty) {
      b.writeln('Verified glossary (Tulu = English / Kannada):');
      for (final w in glossary.take(20)) {
        b.writeln('- ${w.tulu} (${w.roman}) = ${w.en} / ${w.kn}');
      }
    }
    return b.toString();
  }

  /// Asks Gemini to translate [text]; [glossary] grounds the answer.
  Future<AiAnswer> translate(
    String text, {
    List<Word> glossary = const [],
  }) async {
    final proxy = proxyUrl;
    final Uri uri;
    final Map<String, String> headers;
    final String body;
    if (proxy != null) {
      // The server builds the prompt and adds the key.
      uri = Uri.parse(
        '${proxy.endsWith('/') ? proxy.substring(0, proxy.length - 1) : proxy}'
        '/translate',
      );
      headers = {'Content-Type': 'application/json'};
      body = jsonEncode({
        'text': text,
        'glossary': [
          for (final w in glossary.take(20))
            {'tulu': w.tulu, 'roman': w.roman, 'en': w.en, 'kn': w.kn},
        ],
      });
    } else {
      uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
      );
      headers = {'Content-Type': 'application/json', 'x-goog-api-key': apiKey!};
      body = jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': buildPrompt(text, glossary)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      });
    }
    http.Response res;
    try {
      res = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const AiException('AI took too long. Please try again.');
    } on Exception catch (e) {
      if (e is! http.ClientException && e is! IOException) rethrow;
      final fallback = fallbackPost;
      if (fallback == null) {
        throw AiException(
          'No internet connection. AI needs internet; the dictionary works '
          'offline.\n\nDetails: ${_short(e)}',
        );
      }
      // Some networks block the server's name; retry with a private lookup.
      try {
        res = await fallback(
          uri,
          headers,
          body,
        ).timeout(const Duration(seconds: 30));
      } on Exception catch (e2) {
        throw AiException(
          'Can\'t reach the AI server. Check your internet, or try mobile '
          'data or another Wi-Fi. The dictionary works offline.\n\n'
          'Details: ${_short(e)} / ${_short(e2)}',
        );
      }
    }
    // Always decode as UTF-8 (Kannada script), whatever the headers say.
    return parseResponse(res.statusCode, utf8.decode(res.bodyBytes));
  }

  static String _short(Object e) {
    final t = e.toString();
    return t.length > 160 ? '${t.substring(0, 160)}…' : t;
  }

  /// Posts to [uri] after resolving its host with DNS-over-HTTPS
  /// (Cloudflare's 1.1.1.1, reached by IP address), for networks whose DNS
  /// blocks the AI server. TLS still verifies the server's certificate.
  static Future<http.Response> postViaDoh(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    final dns = await http
        .get(
          Uri.https('1.1.1.1', '/dns-query', {'name': uri.host, 'type': 'A'}),
          headers: {'accept': 'application/dns-json'},
        )
        .timeout(const Duration(seconds: 10));
    final answers =
        (jsonDecode(dns.body) as Map<String, dynamic>)['Answer'] as List? ??
        const [];
    final ips = [
      for (final a in answers.cast<Map<String, dynamic>>())
        if (a['type'] == 1) a['data'] as String,
    ];
    if (ips.isEmpty) throw const SocketException('No address from 1.1.1.1');
    final io = HttpClient()
      ..connectionFactory = (u, _, _) async {
        final task = await Socket.startConnect(ips.first, u.port);
        return ConnectionTask.fromSocket(
          task.socket.then((s) => SecureSocket.secure(s, host: u.host)),
          task.cancel,
        );
      };
    final client = IOClient(io);
    try {
      return await client.post(uri, headers: headers, body: body);
    } finally {
      client.close();
    }
  }

  /// Parses a Gemini HTTP response into an [AiAnswer]. Exposed for tests.
  static AiAnswer parseResponse(int status, String body) {
    Map<String, dynamic>? j;
    try {
      j = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {}
    if (status != 200) {
      final msg = (j?['error'] as Map?)?['message'] as String? ?? '';
      throw AiException(switch (status) {
        400 when msg.toLowerCase().contains('api key') =>
          'The Gemini API key is not valid. Check it in Settings.',
        401 || 403 => 'The Gemini API key was rejected. Check it in Settings.',
        404 => 'Model not found. Check the model name in Settings.',
        429 => msg.isNotEmpty ? msg : 'AI limit reached. Try again later.',
        _ => 'AI error ($status). ${msg.isEmpty ? '' : msg}'.trim(),
      });
    }
    try {
      final parts =
          ((j!['candidates'] as List).first as Map)['content']['parts'] as List;
      final text = parts.map((p) => (p as Map)['text'] ?? '').join();
      final cleaned = text
          .replaceAll(RegExp(r'^```(json)?', multiLine: true), '')
          .replaceAll('```', '')
          .trim();
      final answer = AiAnswer.fromJson(
        jsonDecode(cleaned) as Map<String, dynamic>,
      );
      if (answer.tulu.isEmpty) throw const FormatException('empty');
      return answer;
    } catch (_) {
      throw const AiException('AI gave no usable answer. Please try again.');
    }
  }
}
