import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/ai/ai_content_repository.dart';
import 'core/ai/ai_settings_repository.dart';
import 'core/api/api_client.dart';
import 'core/api/hn_api_service.dart';
import 'core/navigation/app_routes.dart';
import 'core/design_system/design_system.dart';
import 'core/platform/macos_settings_bridge.dart';
import 'core/settings/reading_preferences_cubit.dart';
import 'features/item_detail/data/item_detail_repository.dart';
import 'features/items/data/items_repository.dart';

class HackerPenApp extends StatefulWidget {
  const HackerPenApp({this.useWorkspace, super.key});

  final bool? useWorkspace;

  @override
  State<HackerPenApp> createState() => _HackerPenAppState();
}

class _HackerPenAppState extends State<HackerPenApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final ReadingPreferencesCubit _readingPreferences;

  @override
  void initState() {
    super.initState();
    _readingPreferences = ReadingPreferencesCubit()..load();
    MacosSettingsBridge.startListening(
      reloadReadingPreferences: _readingPreferences.load,
    );
  }

  @override
  void dispose() {
    MacosSettingsBridge.stopListening();
    _readingPreferences.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) =>
              ApiClient(baseUrl: 'https://hacker-news.firebaseio.com/v0/'),
        ),
        RepositoryProvider(create: (_) => AiSettingsRepository()),
        RepositoryProvider(
          create: (context) => AiContentRepository(
            settingsRepository: context.read<AiSettingsRepository>(),
          ),
        ),
        RepositoryProvider(
          create: (context) =>
              HnApiService(apiClient: context.read<ApiClient>()),
        ),
        RepositoryProvider(
          create: (context) => ItemsRepository(context.read<HnApiService>()),
        ),
        RepositoryProvider(
          create: (context) =>
              ItemDetailRepository(context.read<HnApiService>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [BlocProvider.value(value: _readingPreferences)],
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'HackerPen',
          theme: HpTheme.dark(),
          builder: (context, child) {
            final colors = context.hpColors;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: colors.paper,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: colors.paper,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarDividerColor: colors.paper,
              ),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      _navigatorKey.currentState?.maybePop(),
                  const SingleActivator(
                    LogicalKeyboardKey.bracketLeft,
                    meta: true,
                  ): () =>
                      _navigatorKey.currentState?.maybePop(),
                  const SingleActivator(
                    LogicalKeyboardKey.bracketLeft,
                    control: true,
                  ): () =>
                      _navigatorKey.currentState?.maybePop(),
                },
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          initialRoute: AppRoutes.items,
          onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
            settings,
            useWorkspace: widget.useWorkspace,
          ),
        ),
      ),
    );
  }
}
