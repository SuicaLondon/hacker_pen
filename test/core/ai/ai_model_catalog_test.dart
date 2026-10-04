import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_model_catalog.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';

void main() {
  test('prioritizes Luna and excludes large and specialized OpenAI models', () {
    expect(
      AiModelCatalog.recommendedFor(AiProviderId.openAiCompatible, [
        'gpt-4o',
        'gpt-4o-mini-tts',
        'gpt-5.4-mini',
        'gpt-4o-mini',
        'gpt-5.6-luna',
        'gpt-5.6-luna',
        'gpt-5.4-nano',
        'gpt-6-astra',
        'gpt-4o-mini-2024-07-18',
        'gpt-5.6-luna-2026-01-01',
      ]),
      ['gpt-5.6-luna', 'gpt-5.4-mini', 'gpt-5.4-nano', 'gpt-4o-mini'],
    );
  });

  test('keeps one available Haiku snapshot and never invents availability', () {
    expect(
      AiModelCatalog.recommendedFor(AiProviderId.anthropic, [
        'claude-opus-5',
        'claude-sonnet-5',
        'claude-haiku-4-5-20251001',
        'claude-haiku-4-5-20250901',
      ]),
      ['claude-haiku-4-5-20251001'],
    );
    expect(
      AiModelCatalog.recommendedFor(AiProviderId.anthropic, [
        'claude-haiku-4-5',
        'claude-haiku-4-5-20251001',
      ]),
      ['claude-haiku-4-5'],
    );
    expect(
      AiModelCatalog.recommendedFor(AiProviderId.openAiCompatible, [
        'gpt-6-astra',
      ]),
      isEmpty,
    );
  });

  test(
    'orders Gemini text Flash models without image audio or preview variants',
    () {
      expect(
        AiModelCatalog.recommendedFor(AiProviderId.gemini, [
          'gemini-2.5-flash',
          'gemini-3.5-flash-lite',
          'gemini-3.8-flash',
          'gemini-3.1-flash-image',
          'gemini-2.5-flash-native-audio-preview-12-2025',
          'gemini-3.1-pro-preview',
          'gemini-3.1-flash-tts-preview',
          'gemini-3-flash-preview',
        ]),
        ['gemini-3.8-flash', 'gemini-3.5-flash-lite', 'gemini-2.5-flash'],
      );
    },
  );
}
