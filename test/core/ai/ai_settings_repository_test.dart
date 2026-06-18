import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_secret_store.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads OpenAI-compatible defaults without an API key', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AiSettingsRepository(
      secretStore: _FakeAiSecretStore(),
      sharedPreferences: SharedPreferences.getInstance(),
    );

    final settings = await repository.load();

    expect(settings.providerId, AiProviderId.openAiCompatible);
    expect(settings.baseUrl, 'https://api.openai.com/v1');
    expect(settings.model, 'gpt-4.1-mini');
    expect(settings.targetLanguage, 'Chinese (Traditional)');
    expect(settings.translationMode, AiTranslationMode.replaceOriginal);
    expect(settings.hasApiKey, isFalse);
  });

  test('keeps settings and API keys scoped by provider', () async {
    SharedPreferences.setMockInitialValues({});
    final secretStore = _FakeAiSecretStore();
    final repository = AiSettingsRepository(
      secretStore: secretStore,
      sharedPreferences: SharedPreferences.getInstance(),
    );

    await repository.save(
      const AiSettings(
        providerId: AiProviderId.openAiCompatible,
        baseUrl: 'https://gateway.example/v1',
        model: 'gpt-4o',
        targetLanguage: 'Japanese',
        translationMode: AiTranslationMode.paragraphPairs,
        hasApiKey: false,
      ),
      apiKeyReplacement: ' open-key ',
    );
    await repository.save(
      const AiSettings(
        providerId: AiProviderId.apiTrust,
        baseUrl: 'https://trust.example/v1',
        model: 'auto',
        targetLanguage: 'French',
        translationMode: AiTranslationMode.paragraphPairs,
        hasApiKey: false,
      ),
      apiKeyReplacement: 'trust-key',
    );

    final selectedSettings = await repository.load();
    final openAiSettings = await repository.load(
      providerId: AiProviderId.openAiCompatible,
    );

    expect(selectedSettings.providerId, AiProviderId.apiTrust);
    expect(selectedSettings.baseUrl, '');
    expect(selectedSettings.model, 'auto');
    expect(selectedSettings.translationMode, AiTranslationMode.paragraphPairs);
    expect(selectedSettings.hasApiKey, isTrue);
    expect(openAiSettings.baseUrl, 'https://api.openai.com/v1');
    expect(openAiSettings.model, 'gpt-4o');
    expect(openAiSettings.translationMode, AiTranslationMode.paragraphPairs);
    expect(openAiSettings.hasApiKey, isTrue);
    expect(
      await secretStore.readApiKey(AiProviderId.openAiCompatible),
      'open-key',
    );
    expect(await secretStore.readApiKey(AiProviderId.apiTrust), 'trust-key');
  });

  test('keeps an existing API key when replacement is blank', () async {
    SharedPreferences.setMockInitialValues({});
    final secretStore = _FakeAiSecretStore();
    final repository = AiSettingsRepository(
      secretStore: secretStore,
      sharedPreferences: SharedPreferences.getInstance(),
    );

    await repository.save(
      AiSettings.defaultsFor(AiProviderId.openAiCompatible),
      apiKeyReplacement: 'open-key',
    );
    await repository.save(
      AiSettings.defaultsFor(
        AiProviderId.openAiCompatible,
      ).copyWith(model: 'gpt-4.1'),
      apiKeyReplacement: ' ',
    );

    final settings = await repository.load();

    expect(settings.model, 'gpt-4.1');
    expect(settings.hasApiKey, isTrue);
    expect(
      await secretStore.readApiKey(AiProviderId.openAiCompatible),
      'open-key',
    );
  });

  test('clears the selected provider API key', () async {
    SharedPreferences.setMockInitialValues({});
    final secretStore = _FakeAiSecretStore();
    final repository = AiSettingsRepository(
      secretStore: secretStore,
      sharedPreferences: SharedPreferences.getInstance(),
    );

    await repository.save(
      AiSettings.defaultsFor(AiProviderId.openAiCompatible),
      apiKeyReplacement: 'open-key',
    );
    await repository.clearApiKey(AiProviderId.openAiCompatible);

    final settings = await repository.load();

    expect(settings.hasApiKey, isFalse);
    expect(await secretStore.readApiKey(AiProviderId.openAiCompatible), isNull);
  });

  test('normalizes stored model and language to app-managed options', () async {
    SharedPreferences.setMockInitialValues({
      'ai.provider.openai_compatible.model': 'unknown-model',
      'ai.provider.openai_compatible.target_language': 'Elvish',
    });
    final repository = AiSettingsRepository(
      secretStore: _FakeAiSecretStore(),
      sharedPreferences: SharedPreferences.getInstance(),
    );

    final settings = await repository.load();

    expect(settings.model, 'gpt-4.1-mini');
    expect(settings.targetLanguage, 'Chinese (Traditional)');
  });

  test(
    'normalizes unknown stored translation mode to replace original',
    () async {
      SharedPreferences.setMockInitialValues({
        'ai.translation_mode': 'unknown',
      });
      final repository = AiSettingsRepository(
        secretStore: _FakeAiSecretStore(),
        sharedPreferences: SharedPreferences.getInstance(),
      );

      final settings = await repository.load();

      expect(settings.translationMode, AiTranslationMode.replaceOriginal);
    },
  );
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
