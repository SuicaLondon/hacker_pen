import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/domain/story_type.dart';
import '../cubit/items_cubit.dart';
import '../cubit/items_state.dart';
import '../widgets/item_story_row.dart';
import '../widgets/items_error_view.dart';
import '../widgets/items_header.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  int _selectedTab = 0;

  static const List<StoryType> _tabStoryTypes = StoryTypeMetadata.homeTabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: colorScheme.surface,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              ItemsHeader(
                selectedTab: _selectedTab,
                tabs: _tabStoryTypes
                    .map((type) => type.label)
                    .toList(growable: false),
                onTabSelected: (index) {
                  setState(() => _selectedTab = index);
                  context.read<ItemsCubit>().loadItems(
                    storyType: _tabStoryTypes[index],
                  );
                },
                onSettingsPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.settings);
                },
              ),
              Expanded(
                child: BlocBuilder<ItemsCubit, ItemsState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case ItemsStatus.initial:
                      case ItemsStatus.loading:
                        return const Center(child: CircularProgressIndicator());
                      case ItemsStatus.failure:
                        return ItemsErrorView(
                          message: state.errorMessage ?? 'Unknown error',
                          onRetry: () => context.read<ItemsCubit>().loadItems(),
                        );
                      case ItemsStatus.success:
                        if (state.items.isEmpty) {
                          return const Center(
                            child: Text('No items available.'),
                          );
                        }
                        return RefreshIndicator(
                          color: colorScheme.primary,
                          onRefresh: () =>
                              context.read<ItemsCubit>().loadItems(),
                          child: ListView.separated(
                            padding: EdgeInsets.only(bottom: bottomInset + 8),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.items.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = state.items[index];
                              return ItemStoryRow(
                                item: item,
                                rank: index + 1,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.itemDetail,
                                    arguments: item.id,
                                  );
                                },
                              );
                            },
                          ),
                        );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
