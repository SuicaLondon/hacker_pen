class TextSanitizer {
  const TextSanitizer._();

  static String stripHtml(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    var text = raw
        .replaceAll('&#x27;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
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
}
