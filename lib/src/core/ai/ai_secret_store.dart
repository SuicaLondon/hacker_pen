import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_provider.dart';

class AiSecretStore {
  AiSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readApiKey(AiProviderId providerId) {
    return _storage.read(key: _apiKeyStorageKey(providerId));
  }

  Future<void> writeApiKey(AiProviderId providerId, String apiKey) {
    return _storage.write(
      key: _apiKeyStorageKey(providerId),
      value: apiKey.trim(),
    );
  }

  Future<void> deleteApiKey(AiProviderId providerId) {
    return _storage.delete(key: _apiKeyStorageKey(providerId));
  }

  String _apiKeyStorageKey(AiProviderId providerId) {
    return 'ai.api_key.${providerId.storageKey}';
  }
}
