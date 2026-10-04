enum AiProviderId { openAiCompatible, anthropic, gemini, apiTrust }

extension AiProviderIdStorage on AiProviderId {
  String get storageKey => switch (this) {
    AiProviderId.openAiCompatible => 'openai_compatible',
    AiProviderId.anthropic => 'anthropic',
    AiProviderId.gemini => 'gemini',
    AiProviderId.apiTrust => 'api_trust',
  };

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
    this.isAvailable = true,
  });

  final AiProviderId id;
  final String label;
  final String defaultBaseUrl;
  final String defaultModel;
  final bool isAvailable;
}

class AiProviders {
  const AiProviders._();

  static const openAiCompatible = AiProviderDefinition(
    id: AiProviderId.openAiCompatible,
    label: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: '',
  );

  static const anthropic = AiProviderDefinition(
    id: AiProviderId.anthropic,
    label: 'Anthropic',
    defaultBaseUrl: 'https://api.anthropic.com/v1',
    defaultModel: '',
  );

  static const gemini = AiProviderDefinition(
    id: AiProviderId.gemini,
    label: 'Gemini',
    defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    defaultModel: '',
  );

  static const apiTrust = AiProviderDefinition(
    id: AiProviderId.apiTrust,
    label: 'API Trust',
    defaultBaseUrl: '',
    defaultModel: 'auto',
    isAvailable: false,
  );

  static const all = <AiProviderDefinition>[
    openAiCompatible,
    anthropic,
    gemini,
    apiTrust,
  ];

  static List<AiProviderDefinition> get available =>
      all.where((provider) => provider.isAvailable).toList(growable: false);

  static AiProviderDefinition definitionFor(AiProviderId id) {
    return all.firstWhere((provider) => provider.id == id);
  }
}
