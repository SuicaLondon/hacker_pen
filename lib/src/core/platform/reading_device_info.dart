import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReadingDeviceInfo {
  ReadingDeviceInfo._();

  static const _channel = MethodChannel('dev.suica.hackerPen/device');

  /// Device identity is resolved once; window width only changes pane layout.
  static Future<bool> useWorkspace() async {
    if (defaultTargetPlatform == TargetPlatform.macOS) return true;
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isIpad') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
