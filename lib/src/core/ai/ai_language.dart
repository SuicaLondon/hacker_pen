class AiLanguage {
  const AiLanguage._();

  static const defaultLanguage = 'Chinese (Traditional)';

  static const common = <String>[
    'Chinese (Traditional)',
    'Chinese (Simplified)',
    'English',
    'Japanese',
    'Korean',
    'French',
    'German',
    'Spanish',
    'Portuguese',
    'Italian',
    'Vietnamese',
    'Thai',
  ];

  static String normalize(String? value) {
    if (value != null && common.contains(value)) return value;
    return defaultLanguage;
  }
}
