import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/settings/presentation/views/settings_page.dart';
import '../ai/ai_settings_repository.dart';
import '../design_system/design_system.dart';
import '../settings/reading_preferences_cubit.dart';
import 'macos_settings_bridge.dart';

class SettingsWindowApp extends StatelessWidget {
  const SettingsWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AiSettingsRepository(
        onChanged: MacosSettingsBridge.notifyAiSettingsChanged,
      ),
      child: BlocProvider(
        create: (_) => ReadingPreferencesCubit(
          onChanged: MacosSettingsBridge.notifyReadingPreferencesChanged,
        )..load(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Settings',
          theme: HpTheme.dark(),
          home: const SettingsPage(desktop: true),
        ),
      ),
    );
  }
}
