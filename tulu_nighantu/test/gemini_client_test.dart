import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulu_nighantu/ai/gemini_client.dart';
import 'package:tulu_nighantu/app_state.dart';
import 'package:tulu_nighantu/screens/settings_screen.dart';
import 'package:tulu_nighantu/widgets/ai_answer_sheet.dart';

String _geminiBody(Map<String, dynamic> answer) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': jsonEncode(answer)},
        ],
      },
    },
  ],
});

void main() {
  test('sends key in header, grounds with glossary, parses JSON', () async {
    late http.Request sent;
    final client = GeminiClient(
      apiKey: 'test-key',
      model: 'some-model',
      client: MockClient((req) async {
        sent = req;
        return http.Response.bytes(
          utf8.encode(
            _geminiBody({
              'tulu': 'ನೀರ್',
              'roman': 'neer',
              'english': 'water',
              'kannada': 'ನೀರು',
              'notes': 'Common word.',
              'confidence': 'High',
            }),
          ),
          200,
        );
      }),
    );
    final state = AppState.instance
      ..loadFromJson(File('assets/data/words.json').readAsStringSync());
    final a = await client.translate(
      'water',
      glossary: state.search('water').take(1).toList(),
    );
    expect(sent.headers['x-goog-api-key'], 'test-key');
    expect(sent.url.path, contains('some-model:generateContent'));
    expect(sent.url.queryParameters.containsKey('key'), isFalse);
    expect(sent.body, contains('ನೀರ್ (neer) = water'));
    expect(a.tulu, 'ನೀರ್');
    expect(a.confidence, 'high');
    expect(a.lipi, isNotEmpty);
  });

  test('friendly errors', () {
    expect(
      () => GeminiClient.parseResponse(403, '{"error":{"message":"denied"}}'),
      throwsA(
        isA<AiException>().having((e) => e.message, 'm', contains('key')),
      ),
    );
    expect(
      () => GeminiClient.parseResponse(429, '{}'),
      throwsA(isA<AiException>()),
    );
    expect(
      () => GeminiClient.parseResponse(200, '{"candidates":[]}'),
      throwsA(isA<AiException>()),
    );
  });

  test('accepts JSON wrapped in a code fence', () {
    final body = jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '```json\n{"tulu":"ಎಡ್ಡೆ","confidence":"medium"}\n```'},
            ],
          },
        },
      ],
    });
    expect(GeminiClient.parseResponse(200, body).tulu, 'ಎಡ್ಡೆ');
  });

  testWidgets('Ask AI without a key points to Settings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppState.instance.setAiSettings(key: '', model: '');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AskAiButton('king'))),
    );
    await tester.tap(find.text('AI ಸಹಾಯ · Ask AI'));
    await tester.pumpAndSettle();
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('settings fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(720, 1480);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(360, 740),
          textScaler: TextScaler.linear(1.4),
        ),
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
