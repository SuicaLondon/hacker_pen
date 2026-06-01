import 'package:shared_preferences/shared_preferences.dart';

import 'ai_language.dart';
import 'ai_provider.dart';
import 'ai_secret_store.dart';
import 'ai_settings.dart';

class AiSettingsRepository {
  AiSettingsRepository({
    AiSecretStore? secretStore,
    Future<SharedPreferences>? sharedPreferences,
  }) : _secretStore = secretStore ?? AiSecretStore(),
       _sharedPreferences =
           sharedPreferences ?? SharedPreferences.getInstance();

  final AiSecretStore _secretStore;
  final Future<SharedPreferences> _sharedPreferences;

  Future<AiSettings> load({AiProviderId? providerId}) async {
    final preferences = await _sharedPreferences;
    final selectedProvider =
        providerId ??
        AiProviderIdStorage.fromStorageKey(
          preferences.getString(_selectedProviderKey),
        );

    return _loadProviderSettings(preferences, selectedProvider);
  }

  Future<void> save(AiSettings settings, {String? apiKeyReplacement}) async {
    final preferences = await _sharedPreferences;
    await preferences.setString(
      _selectedProviderKey,
      settings.providerId.storageKey,
    );
    await preferences.setString(
      _providerSettingKey(settings.providerId, 'model'),
      settings.model.trim(),
    );
    await preferences.setString(
      _providerSettingKey(settings.providerId, 'target_language'),
      settings.targetLanguage.trim(),
    );

    final apiKey = apiKeyReplacement?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      await _secretStore.writeApiKey(settings.providerId, apiKey);
    }
  }

  Future<void> clearApiKey(AiProviderId providerId) {
    return _secretStore.deleteApiKey(providerId);
  }

  Future<String?> readApiKey(AiProviderId providerId) {
    return _secretStore.readApiKey(providerId);
  }

  Future<AiSettings> _loadProviderSettings(
    SharedPreferences preferences,
    AiProviderId providerId,
  ) async {
    final defaults = AiSettings.defaultsFor(providerId);
    final provider = AiProviders.definitionFor(providerId);
    final apiKey = await _secretStore.readApiKey(providerId);
    final storedModel = preferences.getString(
      _providerSettingKey(providerId, 'model'),
    );
    final storedLanguage = preferences.getString(
      _providerSettingKey(providerId, 'target_language'),
    );

    return defaults.copyWith(
      baseUrl: provider.defaultBaseUrl,
      model: provider.models.contains(storedModel)
          ? storedModel
          : provider.defaultModel,
      targetLanguage: AiLanguage.normalize(storedLanguage),
      hasApiKey: apiKey?.isNotEmpty == true,
    );
  }

  static const _selectedProviderKey = 'ai.selected_provider';

  static String _providerSettingKey(AiProviderId providerId, String name) {
    return 'ai.provider.${providerId.storageKey}.$name';
  }
}
