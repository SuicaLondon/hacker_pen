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
  const ItemDetailCommentsSheet({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
        final count = state.story?.descendants ?? 0;

        return HpSheetScaffold(
          title: 'Comments $count',
          leading: HpIconButton(
            tooltip: 'Reload comments',
            onPressed: () => context.read<ItemDetailCubit>().reloadComments(),
            icon: Icons.refresh,
          ),
          trailing: HpIconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
          ),
          body: _ItemDetailCommentsSheetBody(
            scrollController: scrollController,
            state: state,
          ),
        );
      },
    );
  }
}

class _ItemDetailCommentsSheetBody extends StatelessWidget {
  const _ItemDetailCommentsSheetBody({
    required this.scrollController,
    required this.state,
  });

  final ScrollController scrollController;
  final ItemDetailState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    if (state.commentsStatus == ItemDetailCommentsStatus.loading ||
        state.commentsStatus == ItemDetailCommentsStatus.initial) {
      return const Center(child: CircularProgressIndicator());
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
          'No comments yet.',
          style: TextStyle(color: colors.inkMuted),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      // TODO: switch to scrollCacheExtent after the project pins a Flutter SDK
      // where that API accepts numeric cache extents.
      // ignore: deprecated_member_use
      cacheExtent: 600,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
      itemCount: state.comments.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: CommentTreeTile(node: state.comments[index]),
        );
      },
    );
  }
}
