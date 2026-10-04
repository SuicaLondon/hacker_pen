import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_api_client.dart';
import 'package:hacker_pen/src/core/ai/ai_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_secret_store.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reloads settings changed by another engine before reading', () async {
    SharedPreferences.setMockInitialValues({
      'ai.selected_provider': 'openai_compatible',
      'ai.provider.openai_compatible.model': 'old-model',
    });
    final preferences = await SharedPreferences.getInstance();
    final secrets = _FakeAiSecretStore();
    final repository = AiSettingsRepository(
      secretStore: secrets,
      sharedPreferences: Future.value(preferences),
    );
    expect((await repository.load()).model, 'old-model');

    SharedPreferences.setMockInitialValues({
      'ai.selected_provider': 'anthropic',
      'ai.provider.anthropic.model': 'new-model',
      'ai.provider.anthropic.target_language': 'Japanese',
      'ai.translation_mode': 'paragraph_pairs',
    });
    await secrets.writeApiKey(AiProviderId.anthropic, 'new-provider-key');
    expect(preferences.getString('ai.selected_provider'), 'openai_compatible');

    final latest = await repository.load();
    expect(latest.providerId, AiProviderId.anthropic);
    expect(latest.model, 'new-model');
    expect(latest.targetLanguage, 'Japanese');
    expect(latest.translationMode, AiTranslationMode.paragraphPairs);
    expect(latest.hasApiKey, isTrue);
    expect(
      await repository.readApiKey(AiProviderId.anthropic),
      'new-provider-key',
    );
  });

  test('notifies after successful settings and key writes only', () async {
    SharedPreferences.setMockInitialValues({});
    var changes = 0;
    final initialRevision = AiSettingsRepository.revision.value;
    final repository = AiSettingsRepository(
      secretStore: _FakeAiSecretStore(),
      onChanged: () async => changes++,
    );
    await repository.save(
      AiSettings.defaultsFor(AiProviderId.openAiCompatible),
    );
    expect(changes, 1);
    expect(AiSettingsRepository.revision.value, initialRevision + 1);
    await repository.saveApiKey(AiProviderId.openAiCompatible, 'new-key');
    expect(changes, 2);
    expect(AiSettingsRepository.revision.value, initialRevision + 2);
    await repository.clearApiKey(AiProviderId.openAiCompatible);
    expect(changes, 3);
    expect(AiSettingsRepository.revision.value, initialRevision + 3);

    final failing = AiSettingsRepository(
      secretStore: _FailingAiSecretStore(),
      onChanged: () async => changes++,
    );
    await expectLater(
      failing.saveApiKey(AiProviderId.openAiCompatible, 'new-key'),
      throwsStateError,
    );
    await expectLater(
      failing.save(
        AiSettings.defaultsFor(AiProviderId.openAiCompatible),
        apiKeyReplacement: 'new-key',
      ),
      throwsStateError,
    );
    expect(changes, 3);
    expect(AiSettingsRepository.revision.value, initialRevision + 3);
  });

  test(
    'loads models with the selected provider key and rejects missing keys',
    () async {
      SharedPreferences.setMockInitialValues({});
      final secrets = _FakeAiSecretStore();
      var requests = 0;
      final repository = AiSettingsRepository(
        secretStore: secrets,
        sharedPreferences: SharedPreferences.getInstance(),
        apiClient: AiApiClient(
          httpClient: MockClient((request) async {
            requests++;
            expect(request.url.toString(), 'https://api.openai.com/v1/models');
            expect(request.headers['Authorization'], 'Bearer provider-key');
            return http.Response(
              '{"data":[{"id":"gpt-4o"},{"id":"gpt-5.4-mini"},{"id":"gpt-5.6-luna"}]}',
              200,
            );
          }),
        ),
      );
      await expectLater(
        repository.loadModels(AiProviderId.openAiCompatible),
        throwsA(isA<AiException>()),
      );
      expect(requests, 0);
      await repository.saveApiKey(
        AiProviderId.openAiCompatible,
        'provider-key',
      );
      expect(await repository.loadModels(AiProviderId.openAiCompatible), [
        'gpt-5.6-luna',
        'gpt-5.4-mini',
      ]);
      await repository.save(
        AiSettings.defaultsFor(
          AiProviderId.openAiCompatible,
        ).copyWith(model: 'custom-model'),
      );
      expect((await repository.load()).model, 'custom-model');
      await repository.saveApiKey(AiProviderId.openAiCompatible, 'replacement');
      await repository.clearApiKey(AiProviderId.openAiCompatible);
      await expectLater(
        repository.loadModels(AiProviderId.openAiCompatible),
        throwsA(isA<AiException>()),
      );
      expect(requests, 1);
    },
  );

  test(
    'native provider keys remain independent from the active model',
    () async {
      SharedPreferences.setMockInitialValues({});
      final secrets = _FakeAiSecretStore();
      final repository = AiSettingsRepository(
        secretStore: secrets,
        sharedPreferences: SharedPreferences.getInstance(),
      );
      final active = AiSettings.defaultsFor(
        AiProviderId.openAiCompatible,
      ).copyWith(model: 'existing-model');
      await repository.save(active);
      for (final provider in AiProviders.available) {
        await repository.saveApiKey(
          provider.id,
          '${provider.id.storageKey}-key',
        );
      }
      expect(
        (await repository.load()).providerId,
        AiProviderId.openAiCompatible,
      );
      expect((await repository.load()).model, 'existing-model');
      final anthropic = await repository.load(
        providerId: AiProviderId.anthropic,
      );
      expect(anthropic.baseUrl, 'https://api.anthropic.com/v1');
      expect(anthropic.model, isEmpty);
      await repository.save(anthropic.copyWith(model: 'claude-test'));
      expect((await repository.load()).providerId, AiProviderId.anthropic);
      await repository.clearApiKey(AiProviderId.anthropic);
      expect(
        await repository.readApiKey(AiProviderId.openAiCompatible),
        'openai_compatible-key',
      );
      expect(await repository.readApiKey(AiProviderId.gemini), 'gemini-key');
      expect(
        (await repository.load(
          providerId: AiProviderId.openAiCompatible,
        )).model,
        'existing-model',
      );
    },
  );

  test('loads OpenAI-compatible defaults without an API key', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AiSettingsRepository(
      secretStore: _FakeAiSecretStore(),
      sharedPreferences: SharedPreferences.getInstance(),
    );

    final settings = await repository.load();

    expect(settings.providerId, AiProviderId.openAiCompatible);
    expect(settings.baseUrl, 'https://api.openai.com/v1');
    expect(settings.model, isEmpty);
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

  test(
    'saving a key preserves preferences and the selected provider',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = AiSettingsRepository(
        secretStore: _FakeAiSecretStore(),
        sharedPreferences: SharedPreferences.getInstance(),
      );
      final preferences = AiSettings.defaultsFor(
        AiProviderId.openAiCompatible,
      ).copyWith(model: 'gpt-4o', targetLanguage: 'Japanese');
      await repository.save(preferences);
      await repository.saveApiKey(AiProviderId.apiTrust, ' trust-key ');
      expect(await repository.load(), preferences);
      expect(await repository.readApiKey(AiProviderId.apiTrust), 'trust-key');
    },
  );

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

  test(
    'preserves dynamic models and normalizes unsupported language',
    () async {
      SharedPreferences.setMockInitialValues({
        'ai.provider.openai_compatible.model': 'unknown-model',
        'ai.provider.openai_compatible.target_language': 'Elvish',
      });
      final repository = AiSettingsRepository(
        secretStore: _FakeAiSecretStore(),
        sharedPreferences: SharedPreferences.getInstance(),
      );

      final settings = await repository.load();

      expect(settings.model, 'unknown-model');
      expect(settings.targetLanguage, 'Chinese (Traditional)');
    },
  );

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

class _FailingAiSecretStore extends _FakeAiSecretStore {
  @override
  Future<void> writeApiKey(AiProviderId providerId, String apiKey) async {
    throw StateError('Storage unavailable.');
  }
}
