import 'ai_provider.dart';

class AiModelCatalog {
  const AiModelCatalog._();

  // Reading-focused choices, in preference order. Availability still comes
  // from the provider API; a missing model is never added to the picker.
  static List<String> recommendedFor(
    AiProviderId provider,
    Iterable<String> available,
  ) {
    final preferred = switch (provider) {
      AiProviderId.openAiCompatible => const [
        'gpt-5.6-luna',
        'gpt-5.4-mini',
        'gpt-5.4-nano',
        'gpt-4.1-mini',
        'gpt-4o-mini',
      ],
      AiProviderId.anthropic => const ['claude-haiku-4-5'],
      AiProviderId.gemini => const [
        'gemini-3.8-flash',
        'gemini-3.5-flash-lite',
        'gemini-3.1-flash-lite',
        'gemini-2.5-flash',
        'gemini-2.5-flash-lite',
      ],
      AiProviderId.apiTrust => const <String>[],
    };
    final ids = available.toSet();
    final result = <String>[];
    for (final model in preferred) {
      if (ids.contains(model)) {
        result.add(model);
        continue;
      }
      // Show one dated snapshot only when its stable alias is unavailable.
      final snapshotPattern = RegExp(
        '^${RegExp.escape(model)}-(?:[0-9]{8}|[0-9]{4}-[0-9]{2}-[0-9]{2})\$',
      );
      final snapshots = ids.where(snapshotPattern.hasMatch).toList()..sort();
      if (snapshots.isNotEmpty) result.add(snapshots.last);
    }
    return result;
  }
}
