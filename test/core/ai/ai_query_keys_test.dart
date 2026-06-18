import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_query_keys.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';

void main() {
  test('comment translation keys include translation mode', () {
    final replaceKey = AiQueryKeys.commentTranslation(
      provider: 'openai',
      model: 'model',
      language: 'Japanese',
      mode: AiTranslationMode.replaceOriginal.storageKey,
      comment: 'comment',
    );
    final paragraphKey = AiQueryKeys.commentTranslation(
      provider: 'openai',
      model: 'model',
      language: 'Japanese',
      mode: AiTranslationMode.paragraphPairs.storageKey,
      comment: 'comment',
    );

    expect(replaceKey, isNot(paragraphKey));
    expect(replaceKey, contains(AiTranslationMode.replaceOriginal.storageKey));
    expect(paragraphKey, contains(AiTranslationMode.paragraphPairs.storageKey));
  });
}
