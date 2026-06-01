import 'dart:convert';

import 'package:crypto/crypto.dart';

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
      _summaryPromptVersion,
    ];
  }

  static List<Object> commentTranslation({
    required String provider,
    required String model,
    required String language,
    required String comment,
  }) {
    return [
      'ai',
      'v1',
      provider,
      model,
      'commentTranslation',
      language,
      _hash(comment),
      _translationPromptVersion,
    ];
  }

  static String _hash(String value) {
    return sha256.convert(utf8.encode(value.trim())).toString();
  }

  static const _summaryPromptVersion = 'summary-prompt-v1';
  static const _translationPromptVersion = 'translation-prompt-v1';
}
