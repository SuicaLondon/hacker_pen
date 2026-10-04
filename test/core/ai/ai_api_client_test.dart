import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_api_client.dart';
import 'package:hacker_pen/src/core/ai/ai_exception.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads, deduplicates and sorts provider model IDs', () async {
    final client = AiApiClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.test/v1/models');
        expect(request.headers['Authorization'], 'Bearer key');
        return http.Response(
          '{"data":[{"id":"z-model"},{"id":"a-model"},{"id":"z-model"},{"id":" "},{"id":3},{}]}',
          200,
        );
      }),
    );
    expect(await client.listModels(settings: _settings, apiKey: 'key'), [
      'a-model',
      'z-model',
    ]);
  });

  test(
    'model loading distinguishes empty, malformed and rejected responses',
    () async {
      for (final body in ['{}', 'not json', '{"data":null}']) {
        final client = AiApiClient(
          httpClient: MockClient((_) async => http.Response(body, 200)),
        );
        await expectLater(
          client.listModels(settings: _settings, apiKey: 'key'),
          throwsA(isA<AiException>()),
        );
      }
      final empty = AiApiClient(
        httpClient: MockClient((_) async => http.Response('{"data":[]}', 200)),
      );
      expect(
        await empty.listModels(settings: _settings, apiKey: 'key'),
        isEmpty,
      );
      for (final status in [401, 403, 500]) {
        final client = AiApiClient(
          httpClient: MockClient(
            (_) async => http.Response('rejected', status),
          ),
        );
        await expectLater(
          client.listModels(settings: _settings, apiKey: 'key'),
          throwsA(
            isA<AiException>().having(
              (error) => error.statusCode,
              'status',
              status,
            ),
          ),
        );
      }
    },
  );

  test('Anthropic uses native authentication and paginates models', () async {
    var calls = 0;
    final client = AiApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.host, 'api.anthropic.com');
        expect(request.url.path, '/v1/models');
        expect(request.headers['x-api-key'], 'claude-key');
        expect(request.headers['anthropic-version'], '2023-06-01');
        expect(request.headers.containsKey('Authorization'), isFalse);
        calls++;
        if (calls == 1) {
          return http.Response(
            '{"data":[{"id":"claude-a"}],"has_more":true,"last_id":"claude-a"}',
            200,
          );
        }
        expect(request.url.queryParameters['after_id'], 'claude-a');
        return http.Response(
          '{"data":[{"id":"claude-b"}],"has_more":false}',
          200,
        );
      }),
    );
    expect(
      await client.listModels(
        settings: AiSettings.defaultsFor(AiProviderId.anthropic),
        apiKey: 'claude-key',
      ),
      ['claude-a', 'claude-b'],
    );
    expect(calls, 2);
  });

  test(
    'Gemini uses native model pages and filters unsupported generation methods',
    () async {
      var calls = 0;
      final client = AiApiClient(
        httpClient: MockClient((request) async {
          expect(request.url.host, 'generativelanguage.googleapis.com');
          expect(request.url.path, '/v1beta/models');
          expect(request.headers['x-goog-api-key'], 'gemini-key');
          expect(request.url.queryParameters.containsKey('key'), isFalse);
          calls++;
          if (calls == 1) {
            return http.Response(
              jsonEncode({
                'models': [
                  {
                    'name': 'models/gemini-a',
                    'supportedGenerationMethods': ['generateContent'],
                  },
                  {
                    'name': 'models/embedding',
                    'supportedGenerationMethods': ['embedContent'],
                  },
                ],
                'nextPageToken': 'next',
              }),
              200,
            );
          }
          expect(request.url.queryParameters['pageToken'], 'next');
          return http.Response(
            '{"models":[{"name":"models/gemini-b","supportedGenerationMethods":["generateContent"]}]}',
            200,
          );
        }),
      );
      expect(
        await client.listModels(
          settings: AiSettings.defaultsFor(AiProviderId.gemini),
          apiKey: 'gemini-key',
        ),
        ['gemini-a', 'gemini-b'],
      );
      expect(calls, 2);
    },
  );

  test('Anthropic sends native messages and extracts text blocks', () async {
    final settings = AiSettings.defaultsFor(
      AiProviderId.anthropic,
    ).copyWith(model: 'claude-test');
    final client = AiApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'https://api.anthropic.com/v1/messages');
        expect(request.headers['x-api-key'], 'claude-key');
        final body = jsonDecode(request.body);
        expect(body['system'], 'system');
        expect(body['max_tokens'], 4096);
        expect(body['messages'], [
          {'role': 'user', 'content': 'user'},
        ]);
        return http.Response(
          '{"content":[{"type":"thinking","thinking":"hidden"},{"type":"text","text":"hello"},{"type":"text","text":"world"}]}',
          200,
        );
      }),
    );
    expect(
      await client.completeText(
        settings: settings,
        apiKey: 'claude-key',
        systemPrompt: 'system',
        userPrompt: 'user',
      ),
      'hello\nworld',
    );
  });

  test('Gemini sends native content and excludes thought parts', () async {
    final settings = AiSettings.defaultsFor(
      AiProviderId.gemini,
    ).copyWith(model: 'gemini-test');
    final client = AiApiClient(
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-test:generateContent',
        );
        expect(request.headers['x-goog-api-key'], 'gemini-key');
        final body = jsonDecode(request.body);
        expect(body['systemInstruction'], {
          'parts': [
            {'text': 'system'},
          ],
        });
        expect(body['contents'], [
          {
            'role': 'user',
            'parts': [
              {'text': 'user'},
            ],
          },
        ]);
        return http.Response(
          '{"candidates":[{"content":{"parts":[{"thought":true,"text":"hidden"},{"text":"hello"}]}}]}',
          200,
        );
      }),
    );
    expect(
      await client.completeText(
        settings: settings,
        apiKey: 'gemini-key',
        systemPrompt: 'system',
        userPrompt: 'user',
      ),
      'hello',
    );
  });

  test('requires model selection before sending a native request', () async {
    final client = AiApiClient(
      httpClient: MockClient(
        (_) async => throw StateError('Must not send a request'),
      ),
    );
    await expectLater(
      client.completeText(
        settings: AiSettings.defaultsFor(AiProviderId.gemini),
        apiKey: 'key',
        systemPrompt: 'system',
        userPrompt: 'user',
      ),
      throwsA(isA<AiException>()),
    );
  });

  test('posts chat completion request and returns trimmed text', () async {
    late http.Request sent;
    final client = AiApiClient(
      httpClient: MockClient((request) async {
        sent = request;
        return http.Response(
          '{"choices":[{"message":{"content":" hello "}}]}',
          200,
        );
      }),
    );

    final text = await client.completeText(
      settings: _settings,
      apiKey: 'key',
      systemPrompt: 'system',
      userPrompt: 'user',
    );

    expect(text, 'hello');
    expect(sent.url.toString(), 'https://api.test/v1/chat/completions');
    expect(sent.headers['Authorization'], 'Bearer key');
    expect(sent.body, contains('"model":"test-model"'));
    // Reasoning models can reject a custom temperature.
    expect(sent.body, isNot(contains('"temperature"')));
  });

  test('throws provider error message and empty content errors', () async {
    final errorClient = AiApiClient(
      httpClient: MockClient(
        (_) async => http.Response('{"error":{"message":"bad key"}}', 401),
      ),
    );

    await expectLater(
      errorClient.completeText(
        settings: _settings,
        apiKey: 'key',
        systemPrompt: 'system',
        userPrompt: 'user',
      ),
      throwsA(
        isA<AiException>().having((error) => error.statusCode, 'status', 401),
      ),
    );

    final emptyClient = AiApiClient(
      httpClient: MockClient((_) async => http.Response('{"choices":[]}', 200)),
    );

    await expectLater(
      emptyClient.completeText(
        settings: _settings,
        apiKey: 'key',
        systemPrompt: 'system',
        userPrompt: 'user',
      ),
      throwsA(isA<AiException>()),
    );
  });

  test('requires configured base url', () async {
    final client = AiApiClient(
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    await expectLater(
      client.completeText(
        settings: _settings.copyWith(baseUrl: ''),
        apiKey: 'key',
        systemPrompt: 'system',
        userPrompt: 'user',
      ),
      throwsA(isA<AiException>()),
    );
  });
}

const _settings = AiSettings(
  providerId: AiProviderId.openAiCompatible,
  baseUrl: 'https://api.test/v1',
  model: 'test-model',
  targetLanguage: 'English',
  translationMode: AiTranslationMode.replaceOriginal,
  hasApiKey: true,
);
