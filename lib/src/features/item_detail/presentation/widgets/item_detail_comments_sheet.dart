import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../cubit/item_detail_cubit.dart';
import '../cubit/item_detail_state.dart';
import 'comment_tree_tile.dart';

void showItemDetailCommentsSheet(BuildContext context) {
  final cubit = context.read<ItemDetailCubit>();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return BlocProvider.value(
        value: cubit,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.94,
          minChildSize: 0.55,
          maxChildSize: 1,
          snap: true,
          snapSizes: const [0.94, 1],
          builder: (context, scrollController) {
            return ItemDetailCommentsSheet(scrollController: scrollController);
          },
        ),
      );
    },
  );
}

class ItemDetailCommentsSheet extends StatelessWidget {
  const ItemDetailCommentsSheet({
    required this.scrollController,
    this.onClose,
    this.showHeader = true,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
    super.key,
  });

  final ScrollController scrollController;
  final VoidCallback? onClose;
  final bool showHeader;
  final ValueChanged<double>? onHeaderDragUpdate;
  final VoidCallback? onHeaderDragEnd;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
        final count = state.story?.descendants ?? 0;

        return ClipRRect(
          borderRadius: showHeader
              ? const BorderRadius.vertical(top: Radius.circular(4))
              : BorderRadius.zero,
          child: ColoredBox(
            color: context.hpColors.paper,
            child: Column(
              children: [
                Offstage(
                  offstage: !showHeader,
                  child: GestureDetector(
                    onVerticalDragUpdate: onHeaderDragUpdate == null
                        ? null
                        : (details) => onHeaderDragUpdate!(details.delta.dy),
                    onVerticalDragEnd: onHeaderDragEnd == null
                        ? null
                        : (_) => onHeaderDragEnd!(),
                    child: HpTopBar(
                      title: 'Comments $count',
                      leading: HpIconButton(
                        tooltip: 'Reload comments',
                        onPressed: () =>
                            context.read<ItemDetailCubit>().reloadComments(),
                        icon: Icons.refresh,
                      ),
                      trailing: HpIconButton(
                        tooltip: 'Close',
                        onPressed: onClose ?? () => Navigator.of(context).pop(),
                        icon: Icons.close,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ItemDetailCommentsBody(
                    scrollController: scrollController,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ItemDetailCommentsBody extends StatelessWidget {
  const ItemDetailCommentsBody({this.scrollController, super.key});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) => _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ItemDetailState state) {
    final colors = context.hpColors;

    if (state.commentsStatus == ItemDetailCommentsStatus.loading ||
        state.commentsStatus == ItemDetailCommentsStatus.initial) {
      return const HpLoadingView(label: 'Loading comments');
    }

    if (state.commentsStatus == ItemDetailCommentsStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.commentsErrorMessage ?? 'Failed to load comments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.inkMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    context.read<ItemDetailCubit>().reloadComments(),
                child: const Text('Retry comments'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.comments.isEmpty) {
      return Center(
        child: Text(
          'NO COMMENTS YET',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.inkMuted,
            fontFamily: context.hpText.monoFamily,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      primary: false,
      // TODO: switch to scrollCacheExtent after the project pins a Flutter SDK
      // where that API accepts numeric cache extents.
      // ignore: deprecated_member_use
      cacheExtent: 600,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
      itemCount: state.comments.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: CommentTreeTile(
            key: ValueKey(state.comments[index].comment.id),
            node: state.comments[index],
            translations: state.commentTranslations,
            translatingThreadRootIds: state.threadTranslationLoadingIds,
            onTranslateComment: (comment) =>
                context.read<ItemDetailCubit>().translateComment(comment),
            onTranslateReplies: (node) =>
                context.read<ItemDetailCubit>().translateCommentChildren(node),
          ),
        );
      },
    );
  }
}
