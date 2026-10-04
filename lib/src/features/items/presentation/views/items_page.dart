import '../widgets/news_pane_header.dart';
import '../widgets/news_category_tabs.dart';
import '../widgets/items_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/domain/story_type.dart';
import '../../../../core/domain/hn_item.dart';
import '../../data/items_repository.dart';
import '../cubit/items_cubit.dart';
import '../cubit/items_state.dart';
import '../widgets/items_header.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({
    this.onItemSelected,
    this.selectedItemId,
    this.embedded = false,
    this.wideLayout = false,
    this.onClose,
    super.key,
  });

  final ValueChanged<HnItem>? onItemSelected;
  final int? selectedItemId;
  final bool embedded;
  final bool wideLayout;
  final VoidCallback? onClose;

  @override
  State<ItemsPage> createState() => ItemsPageState();
}

class ItemsPageState extends State<ItemsPage> {
  int _selectedTab = 0;
  final _header = HpScrollHeaderController();
  final _pages = PageController();
  final _offsets = List<double>.filled(_tabStoryTypes.length, 0);
  final _cubits = <StoryType, ItemsCubit>{};

  ItemsCubit _cubitFor(StoryType type) => _cubits.putIfAbsent(
    type,
    () =>
        ItemsCubit(context.read<ItemsRepository>())..loadItems(storyType: type),
  );

  Future<void> refresh() async {
    final cubit = _cubitFor(_tabStoryTypes[_selectedTab]);
    if (cubit.state.status == ItemsStatus.failure) {
      await cubit.loadItems();
    } else {
      await cubit.refreshItems();
    }
  }

  @override
  void initState() {
    super.initState();
    _header.addListener(_updateHeader);
  }

  void _updateHeader() => setState(() {});

  @override
  void dispose() {
    for (final cubit in _cubits.values) {
      cubit.close();
    }
    _pages.dispose();
    _header.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedTab) return;
    if (widget.wideLayout ||
        MediaQuery.disableAnimationsOf(context) ||
        (index - _selectedTab).abs() > 1) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  static const List<StoryType> _tabStoryTypes = StoryTypeMetadata.homeTabs;

  @override
  Widget build(BuildContext context) {
    return _buildFeed(context);
  }

  Widget _buildFeed(BuildContext context) {
    final theme = Theme.of(context);
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
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              if (widget.wideLayout)
                NewsPaneHeader(
                  onRefresh: refresh,
                  onClose: widget.onClose,
                  onSettings: Theme.of(context).platform == TargetPlatform.macOS
                      ? null
                      : () =>
                            Navigator.of(context).pushNamed(AppRoutes.settings),
                )
              else
                ItemsHeader(
                  isLogoVisible: !widget.embedded && _header.isVisible,
                  selectedTab: _selectedTab,
                  tabs: _tabStoryTypes
                      .map((type) => type.label)
                      .toList(growable: false),
                  onTabSelected: _selectTab,
                  onSettingsPressed:
                      Theme.of(context).platform == TargetPlatform.macOS
                      ? null
                      : () {
                          Navigator.of(context).pushNamed(AppRoutes.settings);
                        },
                ),
              if (widget.wideLayout)
                NewsCategoryTabs(
                  selectedTab: _selectedTab,
                  tabs: _tabStoryTypes
                      .map((type) => type.label)
                      .toList(growable: false),
                  onTabSelected: _selectTab,
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  physics: widget.wideLayout
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: _tabStoryTypes.length,
                  onPageChanged: (index) {
                    setState(() => _selectedTab = index);
                    _header.reset(offset: _offsets[index]);
                  },
                  itemBuilder: (context, index) => ItemsTab(
                    key: ValueKey(_tabStoryTypes[index]),
                    cubit: _cubitFor(_tabStoryTypes[index]),
                    selectedItemId: widget.selectedItemId,
                    onItemSelected: widget.onItemSelected,
                    wideLayout: widget.wideLayout,
                    isActive: index == _selectedTab,
                    onScroll: (notification) {
                      if (notification.depth == 0 &&
                          notification.metrics.axis == Axis.vertical) {
                        _offsets[index] = notification.metrics.pixels.clamp(
                          0.0,
                          notification.metrics.maxScrollExtent.clamp(
                            0.0,
                            double.infinity,
                          ),
                        );
                      }
                      return index == _selectedTab
                          ? _header.handleScrollNotification(notification)
                          : false;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
