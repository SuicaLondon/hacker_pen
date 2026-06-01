import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_api_client.dart';
import 'package:hacker_pen/src/core/ai/ai_content_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_secret_store.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('summarizes readable text fetched from a URL', () async {
    SharedPreferences.setMockInitialValues({});
    final secretStore = _FakeAiSecretStore();
    final settingsRepository = AiSettingsRepository(
      secretStore: secretStore,
      sharedPreferences: SharedPreferences.getInstance(),
    );
    await settingsRepository.save(
      AiSettings.defaultsFor(AiProviderId.openAiCompatible),
      apiKeyReplacement: 'test-key',
    );
    final aiClient = _FakeAiApiClient('summary result');
    final repository = AiContentRepository(
      settingsRepository: settingsRepository,
      aiApiClient: aiClient,
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'https://example.com/article');
        return http.Response(
          '<html><head><title>Hidden</title></head>'
          '<body><h1>Launch</h1><p>Important article text.</p></body></html>',
          200,
        );
      }),
    );

    final summary = await repository.summarizeWebPageUrl(
      'https://example.com/article',
    );

    expect(summary, 'summary result');
    expect(aiClient.lastApiKey, 'test-key');
    expect(aiClient.lastUserPrompt, contains('Important article text.'));
    expect(aiClient.lastUserPrompt, isNot(contains('Hidden')));
  });

  test('translates one sanitized comment', () async {
    SharedPreferences.setMockInitialValues({});
    final secretStore = _FakeAiSecretStore();
    final settingsRepository = AiSettingsRepository(
      secretStore: secretStore,
      sharedPreferences: SharedPreferences.getInstance(),
    );
    await settingsRepository.save(
      AiSettings.defaultsFor(
        AiProviderId.openAiCompatible,
      ).copyWith(targetLanguage: 'Japanese'),
      apiKeyReplacement: 'test-key',
    );
    final aiClient = _FakeAiApiClient('translated comment');
    final repository = AiContentRepository(
      settingsRepository: settingsRepository,
      aiApiClient: aiClient,
      httpClient: MockClient((_) async => http.Response('', 404)),
    );

    final translation = await repository.translateComment(
      '<p>Hello &amp; welcome.</p>',
    );

    expect(translation, 'translated comment');
    expect(aiClient.lastUserPrompt, contains('Japanese'));
    expect(aiClient.lastUserPrompt, contains('Hello & welcome.'));
  });
}

class _FakeAiApiClient extends AiApiClient {
  _FakeAiApiClient(this.response);

  final String response;
  String? lastApiKey;
  String? lastUserPrompt;

  @override
  Future<String> completeText({
    required AiSettings settings,
    required String apiKey,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    lastApiKey = apiKey;
    lastUserPrompt = userPrompt;
    return response;
  }
}

class _FakeAiSecretStore extends AiSecretStore {
  _FakeAiSecretStore() : super(storage: const FlutterSecureStorage());

  final _apiKeys = <AiProviderId, String>{};

  @override
  Future<String?> readApiKey(AiProviderId providerId) async {
    return _apiKeys[providerId];
  }

  @override
  Future<void> writeApiKey(AiProviderId providerId, String apiKey) async {
    _apiKeys[providerId] = apiKey.trim();
  }

  @override
  Future<void> deleteApiKey(AiProviderId providerId) async {
    _apiKeys.remove(providerId);
  }
}
