import 'package:cached_query/cached_query.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/platform/reading_device_info.dart';
import 'src/core/platform/settings_window_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final useWorkspace = await ReadingDeviceInfo.useWorkspace();
  CachedQuery.instance.config(
    config: const GlobalQueryConfig(
      staleDuration: Duration(minutes: 1),
      cacheDuration: Duration(minutes: 30),
      shouldRethrow: true,
    ),
  );

  runApp(HackerPenApp(useWorkspace: useWorkspace));
}

@pragma('vm:entry-point')
void settingsMain() {
  runApp(const SettingsWindowApp());
}
