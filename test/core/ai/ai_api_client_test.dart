import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_api_client.dart';
import 'package:hacker_pen/src/core/ai/ai_exception.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
