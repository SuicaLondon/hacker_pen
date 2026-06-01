enum AiProviderId { openAiCompatible, apiTrust }

extension AiProviderIdStorage on AiProviderId {
  String get storageKey {
    return switch (this) {
      AiProviderId.openAiCompatible => 'openai_compatible',
      AiProviderId.apiTrust => 'api_trust',
    };
  }

  static AiProviderId fromStorageKey(String? value) {
    return AiProviders.all
        .map((provider) => provider.id)
        .firstWhere(
          (id) => id.storageKey == value,
          orElse: () => AiProviderId.openAiCompatible,
        );
  }
}

class AiProviderDefinition {
  const AiProviderDefinition({
    required this.id,
    required this.label,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.models,
    this.isAvailable = true,
  });

  final AiProviderId id;
  final String label;
  final String defaultBaseUrl;
  final String defaultModel;
  final List<String> models;
  final bool isAvailable;
}

class AiProviders {
  const AiProviders._();

  static const openAiCompatible = AiProviderDefinition(
    id: AiProviderId.openAiCompatible,
    label: 'OpenAI Compatible',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4.1-mini',
    models: ['gpt-4.1-mini', 'gpt-4.1', 'gpt-4o-mini', 'gpt-4o', 'o4-mini'],
  );

  static const apiTrust = AiProviderDefinition(
    id: AiProviderId.apiTrust,
    label: 'API Trust',
    defaultBaseUrl: '',
    defaultModel: 'auto',
    models: ['auto'],
    isAvailable: false,
  );

  static const all = <AiProviderDefinition>[openAiCompatible, apiTrust];

  static AiProviderDefinition definitionFor(AiProviderId id) {
    return all.firstWhere((provider) => provider.id == id);
  }
}
