import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/settings/reading_preferences_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reloads a preference written by another engine', () async {
    final cached = await SharedPreferences.getInstance();
    final preferences = ReadingPreferencesCubit(
      preferences: Future.value(cached),
    );
    addTearDown(preferences.close);
    await preferences.load();
    expect(preferences.state, isTrue);

    SharedPreferences.setMockInitialValues({
      'reading.extend_page_behind_status_bar': false,
    });
    expect(cached.getBool('reading.extend_page_behind_status_bar'), isNull);
    await preferences.load();
    expect(preferences.state, isFalse);
  });

  test(
    'notifies successful saves without notifying reads or failures',
    () async {
      var changes = 0;
      final preferences = ReadingPreferencesCubit(
        onChanged: () async => changes++,
      );
      addTearDown(preferences.close);
      await preferences.load();
      expect(changes, 0);
      await preferences.setExtendPageBehindStatusBar(false);
      expect(changes, 1);

      final failing = ReadingPreferencesCubit(
        preferences: Future.error(StateError('unavailable')),
        onChanged: () async => changes++,
      );
      addTearDown(failing.close);
      await expectLater(
        failing.setExtendPageBehindStatusBar(false),
        throwsStateError,
      );
      expect(changes, 1);
    },
  );

  test('extends pages by default and restores the saved choice', () async {
    final preferences = ReadingPreferencesCubit();
    addTearDown(preferences.close);
    await preferences.load();
    expect(preferences.state, isTrue);
    await preferences.setExtendPageBehindStatusBar(false);

    final reopened = ReadingPreferencesCubit();
    addTearDown(reopened.close);
    await reopened.load();
    expect(reopened.state, isFalse);
    await reopened.setExtendPageBehindStatusBar(true);
    await preferences.load();
    expect(preferences.state, isTrue);
  });

  test('failed storage does not change the active preference', () async {
    final preferences = ReadingPreferencesCubit(
      preferences: Future.error(StateError('unavailable')),
    );
    addTearDown(preferences.close);
    await expectLater(
      preferences.setExtendPageBehindStatusBar(false),
      throwsStateError,
    );
    expect(preferences.state, isTrue);
  });
}
