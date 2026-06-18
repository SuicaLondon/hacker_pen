import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/utils/text_sanitizer.dart';

void main() {
  group('TextSanitizer.stripHtml', () {
    test('returns an empty string for null or empty input', () {
      expect(TextSanitizer.stripHtml(null), isEmpty);
      expect(TextSanitizer.stripHtml(''), isEmpty);
    });

    test('decodes common entities and removes markup', () {
      final sanitized = TextSanitizer.stripHtml(
        '<p>Tom &amp; Jerry said &quot;hi&quot;</p><i>&lt;ok&gt;</i>',
      );

      expect(sanitized, 'Tom & Jerry said "hi"');
    });

    test('decodes numeric entities commonly found in comment URLs', () {
      final sanitized = TextSanitizer.stripHtml(
        '<p>https:&#x2F;&#x2F;example.com&#47;path?x=1&amp;y=2</p>',
      );

      expect(sanitized, 'https://example.com/path?x=1&y=2');
    });
  });
}
