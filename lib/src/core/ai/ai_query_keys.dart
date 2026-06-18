import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'ai_prompts.dart';

class AiQueryKeys {
  const AiQueryKeys._();

  static List<Object> webPageSummary({
    required String provider,
    required String model,
    required String language,
    required String url,
    required String content,
  }) {
    return [
      'ai',
      'v1',
      provider,
      model,
      'webPageSummary',
      language,
      _hash(url.trim()),
      _hash(content),
      AiPrompts.summaryPromptVersion,
    ];
  }

  static List<Object> commentTranslation({
    required String provider,
    required String model,
    required String language,
    required String mode,
    required String comment,
  }) {
    return [
      'ai',
      'v1',
      provider,
      model,
      'commentTranslation',
      language,
      mode,
      _hash(comment),
      AiPrompts.translationPromptVersion,
    ];
  }

  static String _hash(String value) {
    return sha256.convert(utf8.encode(value.trim())).toString();
  }
}
