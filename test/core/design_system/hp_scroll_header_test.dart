import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';

void main() {
  test(
    'slow scrolling hides down and reveals up without frame-sized jumps',
    () {
      final header = HpScrollHeaderController();
      addTearDown(header.dispose);
      for (double offset = 1; offset <= 100; offset++) {
        header.update(offset);
      }
      expect(header.isVisible, isFalse);
      for (double offset = 99; offset >= 80; offset--) {
        header.update(offset);
      }
      expect(header.isVisible, isTrue);
    },
  );

  test(
    'tiny reversals do not flicker, and top overscroll restores the header',
    () {
      final header = HpScrollHeaderController();
      addTearDown(header.dispose);
      header.update(150);
      for (final offset in [148.0, 151.0, 149.0, 152.0]) {
        header.update(offset);
        expect(header.isVisible, isFalse);
      }
      header.update(-30);
      expect(header.isVisible, isTrue);
      header.update(0);
      expect(header.isVisible, isTrue);
    },
  );

  test('navigation resets visibility and ignores non-finite offsets', () {
    final header = HpScrollHeaderController();
    addTearDown(header.dispose);
    header.update(200);
    header.reset();
    header.update(double.nan);
    header.update(double.infinity);
    expect(header.isVisible, isTrue);
    header.update(10);
    expect(header.isVisible, isTrue);
  });
}
