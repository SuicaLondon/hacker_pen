enum AiTranslationMode {
  replaceOriginal(
    storageKey: 'replace_original',
    label: 'Replace original',
    description: 'Show either the original comment or its translation.',
  ),
  paragraphPairs(
    storageKey: 'paragraph_pairs',
    label: 'Paragraph pairs',
    description: 'Show each original paragraph followed by its translation.',
  );

  const AiTranslationMode({
    required this.storageKey,
    required this.label,
    required this.description,
  });

  final String storageKey;
  final String label;
  final String description;
}

class AiTranslationModeStorage {
  const AiTranslationModeStorage._();

  static AiTranslationMode fromStorageKey(String? storageKey) {
    return AiTranslationMode.values.firstWhere(
      (mode) => mode.storageKey == storageKey,
      orElse: () => AiTranslationMode.replaceOriginal,
    );
  }
}
