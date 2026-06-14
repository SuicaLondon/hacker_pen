import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/ai/ai_content_repository.dart';
import 'core/ai/ai_settings_repository.dart';
import 'core/api/api_client.dart';
import 'core/api/hn_api_service.dart';
import 'core/navigation/app_routes.dart';
import 'core/design_system/design_system.dart';
import 'features/item_detail/data/item_detail_repository.dart';
import 'features/items/data/items_repository.dart';
import 'features/items/presentation/cubit/items_cubit.dart';

class HackerPenApp extends StatelessWidget {
  const HackerPenApp({super.key});

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
      child: BlocProvider(
        create: (context) =>
            ItemsCubit(context.read<ItemsRepository>())..loadItems(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HackerPen',
          theme: HpTheme.light(),
          initialRoute: AppRoutes.items,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}
