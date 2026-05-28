import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_fonts.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.surface,
          title: const _ItemDetailCommentsTitle(),
          leading: IconButton(
            tooltip: 'Reload comments',
            onPressed: () => context.read<ItemDetailCubit>().reloadComments(),
            icon: const Icon(Icons.refresh),
          ),
          actions: [
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: colorScheme.outlineVariant),
          ),
        ),
        body: _ItemDetailCommentsSheetBody(scrollController: scrollController),
      ),
    );
  }
}

class _ItemDetailCommentsTitle extends StatelessWidget {
  const _ItemDetailCommentsTitle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
        final count = state.story?.descendants ?? 0;
        return Text(
          'Comments $count',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: AppFonts.display,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}

class _ItemDetailCommentsSheetBody extends StatelessWidget {
  const _ItemDetailCommentsSheetBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
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
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
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
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          cacheExtent: 600,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
          itemCount: state.comments.length,
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child: CommentTreeTile(node: state.comments[index]),
            );
          },
        );
      },
    );
  }
}
