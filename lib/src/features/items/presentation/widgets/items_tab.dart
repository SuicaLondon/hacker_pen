import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/domain/hn_item.dart';
import '../cubit/items_cubit.dart';
import '../cubit/items_state.dart';
import '../widgets/item_story_row.dart';

class ItemsTab extends StatefulWidget {
  const ItemsTab({
    required this.cubit,
    required this.isActive,
    required this.onScroll,
    this.selectedItemId,
    this.onItemSelected,
    this.wideLayout = false,
    super.key,
  });

  final ItemsCubit cubit;
  final int? selectedItemId;
  final ValueChanged<HnItem>? onItemSelected;
  final bool wideLayout;
  final bool isActive;
  final bool Function(ScrollNotification) onScroll;

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.hpColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return TickerMode(
      enabled: widget.isActive,
      child: BlocProvider.value(
        value: widget.cubit,
        child: BlocConsumer<ItemsCubit, ItemsState>(
          listenWhen: (previous, current) =>
              widget.isActive &&
              current.status == ItemsStatus.success &&
              current.errorMessage != null &&
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    widget.wideLayout
                        ? 'Could not refresh. Try refreshing again.'
                        : 'Could not refresh. Pull down to try again.',
                  ),
                ),
              );
          },
          builder: (context, state) {
            switch (state.status) {
              case ItemsStatus.initial:
              case ItemsStatus.loading:
                return const HpLoadingView(label: 'Fetching stories');
              case ItemsStatus.failure:
                return HpErrorView(
                  title: 'Failed to load items',
                  retryLabel: 'Try again',
                  message: state.errorMessage ?? 'Unknown error',
                  onRetry: () => context.read<ItemsCubit>().loadItems(),
                );
              case ItemsStatus.success:
                return NotificationListener<ScrollNotification>(
                  onNotification: widget.onScroll,
                  child: CustomScrollView(
                    key: ValueKey(state.storyType),
                    controller: _scrollController,
                    physics: widget.wideLayout
                        ? const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          )
                        : const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                    slivers: [
                      HpSliverRefreshControl(
                        onRefresh: context.read<ItemsCubit>().refreshItems,
                      ),
                      if (state.items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _ItemsEmptyView(),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.only(bottom: bottomInset + 24),
                          sliver: SliverList.separated(
                            itemCount: state.items.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              thickness: context.hpBorders.hairline,
                              indent: widget.wideLayout ? 16 : 24,
                              endIndent: widget.wideLayout ? 16 : 24,
                              color: colors.rule,
                            ),
                            itemBuilder: (context, index) {
                              final item = state.items[index];
                              return ColoredBox(
                                color: item.id == widget.selectedItemId
                                    ? colors.highlight
                                    : Colors.transparent,
                                child: ItemStoryRow(
                                  key: ValueKey(item.id),
                                  item: item,
                                  rank: index + 1,
                                  wideLayout: widget.wideLayout,
                                  isSelected: item.id == widget.selectedItemId,
                                  onTap: () {
                                    if (widget.onItemSelected
                                        case final onSelected?) {
                                      onSelected(item);
                                    } else {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.itemDetail,
                                        arguments: item.id,
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _ItemsEmptyView extends StatelessWidget {
  const _ItemsEmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'NO STORIES AVAILABLE',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.hpColors.inkMuted,
          fontFamily: context.hpText.monoFamily,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
