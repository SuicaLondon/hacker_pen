class TextSanitizer {
  const TextSanitizer._();

  static String stripHtml(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    var text = raw.replaceAll(
      RegExp(
        r'<(script|style|head|svg)\b[^>]*>[\s\S]*?</\1>',
        caseSensitive: false,
      ),
      '',
    );

    text = _decodeHtmlEntities(text)
        .replaceAll('<p>', '\n\n')
        .replaceAll('</p>', '')
        .replaceAll('<i>', '')
        .replaceAll('</i>', '')
        .replaceAll('<pre>', '\n')
        .replaceAll('</pre>', '\n')
        .replaceAll('<code>', '')
        .replaceAll('</code>', '');

    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    return text.trim();
  }

  static String _decodeHtmlEntities(String raw) {
    final namedEntities = {
      'amp': '&',
      'apos': "'",
      'gt': '>',
      'lt': '<',
      'nbsp': ' ',
      'quot': '"',
    };

    return raw.replaceAllMapped(
      RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'),
      (match) {
        final entity = match.group(1);
        if (entity == null) return match.group(0)!;

        if (entity.startsWith('#x')) {
          return _decodeCodePoint(entity.substring(2), radix: 16, match: match);
        }
        if (entity.startsWith('#')) {
          return _decodeCodePoint(entity.substring(1), radix: 10, match: match);
        }

        return namedEntities[entity] ?? match.group(0)!;
      },
    );
  }

  static String _decodeCodePoint(
    String value, {
    required int radix,
    required Match match,
  }) {
    final codePoint = int.tryParse(value, radix: radix);
    if (codePoint == null) return match.group(0)!;

    try {
      return String.fromCharCode(codePoint);
    } catch (_) {
      return match.group(0)!;
    }
  }
}
