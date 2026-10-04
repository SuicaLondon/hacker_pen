import '../ai/ai_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MacosSettingsBridge {
  MacosSettingsBridge._();

  static const _channel = MethodChannel('dev.suica.hackerPen/settings');

  static void Function(String)? workspaceActionHandler;

  static Future<void> openSettings() =>
      _channel.invokeMethod<void>('openSettings');

  static void startListening({
    required Future<void> Function() reloadReadingPreferences,
  }) {
    if (defaultTargetPlatform != TargetPlatform.macOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'workspaceAction') {
        switch (call.arguments) {
          case 'toggleNews' || 'toggleInspector' || 'refreshNews' || 'back':
            workspaceActionHandler?.call(call.arguments as String);
        }
        return;
      }
      if (call.method != 'settingsChanged') return;
      switch (call.arguments) {
        case 'ai':
          AiSettingsRepository.revision.value++;
        case 'reading':
          await reloadReadingPreferences();
      }
    });
  }

  static void stopListening() {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      _channel.setMethodCallHandler(null);
    }
  }

  static Future<void> notifyAiSettingsChanged() => _notifyChanged('ai');

  static Future<void> notifyReadingPreferencesChanged() =>
      _notifyChanged('reading');

  static Future<void> _notifyChanged(String kind) async {
    try {
      await _channel.invokeMethod<void>('settingsChanged', kind);
    } on MissingPluginException {
      // Saving remains valid when the native window has already closed.
    } on PlatformException {
      // A notification failure must not report a successful save as failed.
    }
  }
}
