import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/platform/macos_settings_bridge.dart';

const _channel = MethodChannel('dev.suica.hackerPen/settings');

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  });

  tearDown(() {
    MacosSettingsBridge.stopListening();
    MacosSettingsBridge.workspaceActionHandler = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('opens Settings and sends change kinds without secret values', () async {
    final calls = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
      call,
    ) async {
      calls.add(call);
      return null;
    });

    await MacosSettingsBridge.openSettings();
    await MacosSettingsBridge.notifyAiSettingsChanged();
    await MacosSettingsBridge.notifyReadingPreferencesChanged();

    expect(calls.map((call) => call.method), [
      'openSettings',
      'settingsChanged',
      'settingsChanged',
    ]);
    expect(calls.map((call) => call.arguments), [null, 'ai', 'reading']);
  });

  test(
    'AI changes invalidate results while reading changes only reload preferences',
    () async {
      final originalRevision = AiSettingsRepository.revision.value;
      var readingReloads = 0;
      MacosSettingsBridge.startListening(
        reloadReadingPreferences: () async => readingReloads++,
      );

      await _sendNativeCall(
        binding,
        const MethodCall('settingsChanged', 'reading'),
      );
      expect(readingReloads, 1);
      expect(AiSettingsRepository.revision.value, originalRevision);
      await _sendNativeCall(binding, const MethodCall('settingsChanged', 'ai'));
      expect(readingReloads, 1);
      expect(AiSettingsRepository.revision.value, originalRevision + 1);
      await _sendNativeCall(
        binding,
        const MethodCall('settingsChanged', 'unknown'),
      );
      expect(readingReloads, 1);
      expect(AiSettingsRepository.revision.value, originalRevision + 1);
    },
  );

  test(
    'dispatches native workspace actions through the existing callbacks',
    () async {
      final actions = <String>[];
      MacosSettingsBridge.workspaceActionHandler = actions.add;
      MacosSettingsBridge.startListening(reloadReadingPreferences: () async {});
      for (final action in [
        'toggleNews',
        'toggleInspector',
        'refreshNews',
        'back',
      ]) {
        await _sendNativeCall(binding, MethodCall('workspaceAction', action));
      }
      await _sendNativeCall(
        binding,
        const MethodCall('workspaceAction', 'unknown'),
      );
      expect(actions, ['toggleNews', 'toggleInspector', 'refreshNews', 'back']);
    },
  );

  test(
    'a failed notification does not turn a completed save into an error',
    () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
        _,
      ) async {
        throw PlatformException(code: 'window_closed');
      });
      await MacosSettingsBridge.notifyAiSettingsChanged();
      await MacosSettingsBridge.notifyReadingPreferencesChanged();
    },
  );
}

Future<void> _sendNativeCall(
  TestWidgetsFlutterBinding binding,
  MethodCall call,
) async {
  final reply = Completer<void>();
  binding.channelBuffers.push(
    _channel.name,
    const StandardMethodCodec().encodeMethodCall(call),
    (_) => reply.complete(),
  );
  await reply.future;
}
