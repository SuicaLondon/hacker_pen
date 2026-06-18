import 'package:equatable/equatable.dart';

import 'ai_language.dart';
import 'ai_provider.dart';
import 'ai_translation_mode.dart';

class AiSettings extends Equatable {
  const AiSettings({
    required this.providerId,
    required this.baseUrl,
    required this.model,
    required this.targetLanguage,
    required this.translationMode,
    required this.hasApiKey,
  });

  factory AiSettings.defaultsFor(AiProviderId providerId) {
    final provider = AiProviders.definitionFor(providerId);
    return AiSettings(
      providerId: providerId,
      baseUrl: provider.defaultBaseUrl,
      model: provider.defaultModel,
      targetLanguage: AiLanguage.defaultLanguage,
      translationMode: AiTranslationMode.replaceOriginal,
      hasApiKey: false,
    );
  }

  final AiProviderId providerId;
  final String baseUrl;
  final String model;
  final String targetLanguage;
  final AiTranslationMode translationMode;
  final bool hasApiKey;

  AiSettings copyWith({
    AiProviderId? providerId,
    String? baseUrl,
    String? model,
    String? targetLanguage,
    AiTranslationMode? translationMode,
    bool? hasApiKey,
  }) {
    return AiSettings(
      providerId: providerId ?? this.providerId,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      translationMode: translationMode ?? this.translationMode,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }

  @override
  List<Object?> get props => [
    providerId,
    baseUrl,
    model,
    targetLanguage,
    translationMode,
    hasApiKey,
  ];
}
