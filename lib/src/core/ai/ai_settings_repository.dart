import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_language.dart';
import 'ai_model_catalog.dart';
import 'ai_api_client.dart';
import 'ai_exception.dart';
import 'ai_provider.dart';
import 'ai_secret_store.dart';
import 'ai_settings.dart';
import 'ai_translation_mode.dart';

class AiSettingsRepository {
  /// Changes within this engine and notifications from the Mac settings engine.
  static final revision = ValueNotifier<int>(0);

  AiSettingsRepository({
    AiSecretStore? secretStore,
    AiApiClient? apiClient,
    Future<SharedPreferences>? sharedPreferences,
    Future<void> Function()? onChanged,
  }) : _apiClient = apiClient ?? AiApiClient(),
       _secretStore = secretStore ?? AiSecretStore(),
       _onChanged = onChanged,
       _sharedPreferences =
           sharedPreferences ?? SharedPreferences.getInstance();

  final AiApiClient _apiClient;
  final AiSecretStore _secretStore;
  final Future<void> Function()? _onChanged;
  final Future<SharedPreferences> _sharedPreferences;

  Future<List<AiProviderDefinition>> loadProviders() async =>
      AiProviders.available;

  Future<AiSettings> load({AiProviderId? providerId}) async {
    final preferences = await _sharedPreferences;
    // The dedicated Mac settings window runs in another Flutter engine.
    await preferences.reload();
    final selectedProvider =
        providerId ??
        AiProviderIdStorage.fromStorageKey(
          preferences.getString(_selectedProviderKey),
        );

    return _loadProviderSettings(preferences, selectedProvider);
  }

  Future<List<String>> loadModels(AiProviderId providerId) async {
    final provider = AiProviders.definitionFor(providerId);
    if (!provider.isAvailable) {
      throw const AiException('This provider is not available yet.');
    }
    final apiKey = await readApiKey(providerId);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const AiException(
        'Add an API key for this provider to load models.',
      );
    }
    final available = await _apiClient.listModels(
      settings: await load(providerId: providerId),
      apiKey: apiKey,
    );
    return AiModelCatalog.recommendedFor(providerId, available);
  }

  Future<void> save(AiSettings settings, {String? apiKeyReplacement}) async {
    final preferences = await _sharedPreferences;
    final saved = <bool>[
      await preferences.setString(
        _selectedProviderKey,
        settings.providerId.storageKey,
      ),
      await preferences.setString(
        _providerSettingKey(settings.providerId, 'model'),
        settings.model.trim(),
      ),
      await preferences.setString(
        _providerSettingKey(settings.providerId, 'target_language'),
        settings.targetLanguage.trim(),
      ),
      await preferences.setString(
        _translationModeKey,
        settings.translationMode.storageKey,
      ),
    ];
    if (saved.contains(false)) {
      throw StateError('Could not save AI settings.');
    }

    final apiKey = apiKeyReplacement?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      await _secretStore.writeApiKey(settings.providerId, apiKey);
    }
    revision.value++;
    await _onChanged?.call();
  }

  Future<void> saveApiKey(AiProviderId providerId, String apiKey) async {
    await _secretStore.writeApiKey(providerId, apiKey.trim());
    revision.value++;
    await _onChanged?.call();
  }

  Future<void> clearApiKey(AiProviderId providerId) async {
    await _secretStore.deleteApiKey(providerId);
    revision.value++;
    await _onChanged?.call();
  }

  Future<String?> readApiKey(AiProviderId providerId) {
    return _secretStore.readApiKey(providerId);
  }

  Future<AiSettings> _loadProviderSettings(
    SharedPreferences preferences,
    AiProviderId providerId,
  ) async {
    final provider = AiProviders.definitionFor(providerId);
    final apiKey = await _secretStore.readApiKey(providerId);
    final storedModel = preferences.getString(
      _providerSettingKey(providerId, 'model'),
    );
    final storedLanguage = preferences.getString(
      _providerSettingKey(providerId, 'target_language'),
    );
    final storedTranslationMode = preferences.getString(_translationModeKey);

    return AiSettings(
      providerId: providerId,
      baseUrl: provider.defaultBaseUrl,
      model: storedModel != null && storedModel.trim().isNotEmpty
          ? storedModel.trim()
          : provider.defaultModel,
      targetLanguage: AiLanguage.normalize(storedLanguage),
      translationMode: AiTranslationModeStorage.fromStorageKey(
        storedTranslationMode,
      ),
      hasApiKey: apiKey?.isNotEmpty == true,
    );
  }

  static const _selectedProviderKey = 'ai.selected_provider';
  static const _translationModeKey = 'ai.translation_mode';

  static String _providerSettingKey(AiProviderId providerId, String name) {
    return 'ai.provider.${providerId.storageKey}.$name';
  }
}
