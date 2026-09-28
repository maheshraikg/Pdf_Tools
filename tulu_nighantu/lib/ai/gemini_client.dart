import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../lipi/tulu_lipi.dart';
import '../models/word.dart';

/// Default Gemini model; users can change it in Settings.
const String kDefaultGeminiModel = 'gemini-flash-latest';

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
  GeminiClient({
    required this.apiKey,
    this.model = kDefaultGeminiModel,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

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
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );
    final body = jsonEncode({
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
    final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const AiException('AI took too long. Please try again.');
    } on http.ClientException {
      throw const AiException(
        'No internet connection. AI needs internet; the dictionary works offline.',
      );
    }
    // Always decode as UTF-8 (Kannada script), whatever the headers say.
    return parseResponse(res.statusCode, utf8.decode(res.bodyBytes));
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
        429 => 'Gemini quota reached. Try again later.',
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
