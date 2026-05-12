import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api/hn_api_service.dart';
import 'core/theme/app_colors.dart';
import 'features/item_detail/data/item_detail_repository.dart';
import 'features/items/data/items_repository.dart';
import 'features/items/presentation/cubit/items_cubit.dart';
import 'features/items/presentation/views/items_page.dart';

class HackerPenApp extends StatelessWidget {
  const HackerPenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => HnApiService()),
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
          theme: ThemeData(
            fontFamily: '.SF Pro Text',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            dividerColor: AppColors.divider,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
              elevation: 0,
            ),
            colorScheme: const ColorScheme.dark(
              primary: AppColors.brandOrange,
              surface: AppColors.surface,
            ),
          ),
          home: const ItemsPage(),
        ),
      ),
    );
  }
}
