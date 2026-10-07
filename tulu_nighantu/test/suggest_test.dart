import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulu_nighantu/ai/gemini_client.dart';
import 'package:tulu_nighantu/ai/suggest_client.dart';
import 'package:tulu_nighantu/app_state.dart';
import 'package:tulu_nighantu/models/word.dart';

final _word = Word(
  id: 'u:1',
  tulu: 'ರಾಜೆ',
  roman: 'raaje',
  kn: 'ರಾಜ',
  en: 'king',
  cat: 'words',
  custom: true,
);

http.Response _json(Object body, int status) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    AppState.instance.loadFromJson(
      File('assets/data/words.json').readAsStringSync(),
    );
  });

  test('posts the word to <server>/suggest and marks it sent', () async {
    late http.Request sent;
    final client = SuggestClient(
      proxyUrl: 'https://ai.example.workers.dev/',
      client: MockClient((req) async {
        sent = req;
        return _json({'ok': true}, 200);
      }),
    );
    await AppState.instance.sendSuggestion(_word, client: client);
    expect(sent.url.toString(), 'https://ai.example.workers.dev/suggest');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['tulu'], 'ರಾಜೆ');
    expect(body['en'], 'king');
    expect(AppState.instance.sentSuggestions, contains('u:1'));
  });

  test('server and network errors become friendly messages', () async {
    final limited = SuggestClient(
      proxyUrl: 'https://ai.example.workers.dev',
      client: MockClient(
        (_) async => _json({
          'error': {'message': 'Too many suggestions today.'},
        }, 429),
      ),
    );
    expect(
      () => limited.send(_word),
      throwsA(
        isA<AiException>().having((e) => e.message, 'm', contains('Too many')),
      ),
    );
    final offline = SuggestClient(
      proxyUrl: 'https://ai.example.workers.dev',
      client: MockClient((_) async => throw http.ClientException('no net')),
      fallbackPost: (uri, headers, body) async =>
          throw http.ClientException('no net'),
    );
    expect(
      () => offline.send(_word),
      throwsA(
        isA<AiException>().having((e) => e.message, 'm', contains('saved')),
      ),
    );
  });
}
