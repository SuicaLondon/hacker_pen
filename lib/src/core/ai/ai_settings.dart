import 'package:equatable/equatable.dart';

import 'ai_language.dart';
import 'ai_provider.dart';

class AiSettings extends Equatable {
  const AiSettings({
    required this.providerId,
    required this.baseUrl,
    required this.model,
    required this.targetLanguage,
    required this.hasApiKey,
  });

  factory AiSettings.defaultsFor(AiProviderId providerId) {
    final provider = AiProviders.definitionFor(providerId);
    return AiSettings(
      providerId: providerId,
      baseUrl: provider.defaultBaseUrl,
      model: provider.defaultModel,
      targetLanguage: AiLanguage.defaultLanguage,
      hasApiKey: false,
    );
  }

  final AiProviderId providerId;
  final String baseUrl;
  final String model;
  final String targetLanguage;
  final bool hasApiKey;

  AiSettings copyWith({
    AiProviderId? providerId,
    String? baseUrl,
    String? model,
    String? targetLanguage,
    bool? hasApiKey,
  }) {
    return AiSettings(
      providerId: providerId ?? this.providerId,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }

  @override
  List<Object?> get props => [
    providerId,
    baseUrl,
    model,
    targetLanguage,
    hasApiKey,
  ];
}
