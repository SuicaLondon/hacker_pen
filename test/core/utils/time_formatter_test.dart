import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/utils/time_formatter.dart';

void main() {
  test('formats compact relative times for feed metadata', () {
    final now = DateTime.utc(2026, 8, 24, 12);

    expect(
      TimeFormatter.compactRelativeFromUnixSeconds(
        _seconds(now.subtract(const Duration(seconds: 30))),
        relativeTo: now,
      ),
      'NOW',
    );
    expect(
      TimeFormatter.compactRelativeFromUnixSeconds(
        _seconds(now.subtract(const Duration(minutes: 15))),
        relativeTo: now,
      ),
      '15M',
    );
    expect(
      TimeFormatter.compactRelativeFromUnixSeconds(
        _seconds(now.subtract(const Duration(hours: 2))),
        relativeTo: now,
      ),
      '2H',
    );
    expect(
      TimeFormatter.compactRelativeFromUnixSeconds(
        _seconds(now.subtract(const Duration(days: 3))),
        relativeTo: now,
      ),
      '3D',
    );
  });
}

int _seconds(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
