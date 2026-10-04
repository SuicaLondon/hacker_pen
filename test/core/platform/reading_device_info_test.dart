import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/platform/reading_device_info.dart';

const _channel = MethodChannel('dev.suica.hackerPen/device');

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS uses the exact native iPad idiom result', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var isIpad = false;
    var calls = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
      call,
    ) async {
      calls++;
      expect(call.method, 'isIpad');
      expect(call.arguments, isNull);
      return isIpad;
    });
    expect(await ReadingDeviceInfo.useWorkspace(), isFalse);
    isIpad = true;
    expect(await ReadingDeviceInfo.useWorkspace(), isTrue);
    expect(calls, 2);
  });

  test('Mac and Android do not require an iOS device channel', () async {
    var calls = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
      _,
    ) async {
      calls++;
      throw PlatformException(code: 'not_ios');
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(await ReadingDeviceInfo.useWorkspace(), isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(await ReadingDeviceInfo.useWorkspace(), isFalse);
    expect(calls, 0);
  });

  test(
    'unavailable native device info preserves the mobile experience',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _channel,
        (_) async => null,
      );
      expect(await ReadingDeviceInfo.useWorkspace(), isFalse);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
        _,
      ) async {
        throw PlatformException(code: 'device_info_unavailable');
      });
      expect(await ReadingDeviceInfo.useWorkspace(), isFalse);
    },
  );
}
