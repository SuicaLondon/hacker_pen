import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/story_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../item_detail/presentation/views/item_detail_page.dart';
import '../cubit/items_cubit.dart';
import '../cubit/items_state.dart';
import '../widgets/item_story_row.dart';
import '../widgets/items_bottom_nav.dart';
import '../widgets/items_error_view.dart';
import '../widgets/items_header.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  int _selectedTab = 0;
  int _selectedBottomNav = 0;

  static const List<String> _tabs = [
    'Top',
    'New',
    'Best',
    'Ask',
    'Show',
    'Jobs',
  ];
  static const List<StoryType> _tabStoryTypes = [
    StoryType.top,
    StoryType.newStories,
    StoryType.best,
    StoryType.ask,
    StoryType.show,
    StoryType.job,
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              ItemsHeader(
                selectedTab: _selectedTab,
                tabs: _tabs,
                onTabSelected: (index) {
                  setState(() => _selectedTab = index);
                  context.read<ItemsCubit>().loadItems(
                    storyType: _tabStoryTypes[index],
                  );
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
                          color: AppColors.brandOrange,
                          onRefresh: () =>
                              context.read<ItemsCubit>().loadItems(),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.items.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: AppColors.divider,
                            ),
                            itemBuilder: (context, index) {
                              final item = state.items[index];
                              return ItemStoryRow(
                                item: item,
                                rank: index + 1,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ItemDetailPage(itemId: item.id),
                                    ),
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
        bottomNavigationBar: ItemsBottomNav(
          selectedIndex: _selectedBottomNav,
          onSelected: (index) => setState(() => _selectedBottomNav = index),
        ),
      ),
    );
  }
}
