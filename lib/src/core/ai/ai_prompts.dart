import 'ai_translation_mode.dart';

class AiPrompts {
  const AiPrompts._();

  static const summaryPromptVersion = 'summary-prompt-v1';
  static const translationPromptVersion = 'translation-prompt-v2';

  static const summarySystemPrompt =
      'You summarize web pages for a Hacker News reader. '
      'Be concise, factual, and preserve important technical details.';

  static String summaryUserPrompt({
    required String targetLanguage,
    required String url,
    required String pageText,
  }) {
    return 'Summarize the following web page in $targetLanguage. '
        'Return 3-6 bullet points and one short takeaway.\n\n'
        'URL: $url\n\n'
        '$pageText';
  }

  static const commentTranslationSystemPrompt =
      'You translate Hacker News comments. Preserve code, URLs, '
      'usernames, and quoted text. Do not add commentary.';

  static String commentTranslationUserPrompt({
    required AiTranslationMode mode,
    required String targetLanguage,
    required String commentText,
  }) {
    return switch (mode) {
      AiTranslationMode.replaceOriginal =>
        'Translate this comment into $targetLanguage:\n\n'
            '$commentText',
      AiTranslationMode.paragraphPairs =>
        'Translate this comment into $targetLanguage.\n'
            'Preserve the same paragraph count and paragraph order. '
            'Return only the translated paragraphs, separated by blank lines. '
            'Do not include the original text or commentary.\n\n'
            '$commentText',
    };
  }
}
