import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../data/item_detail_repository.dart';
import '../cubit/item_detail_cubit.dart';
import '../cubit/item_detail_state.dart';
import '../widgets/comment_tree_tile.dart';
import '../widgets/item_detail_error_view.dart';
import '../widgets/item_detail_story_card.dart';

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({required this.itemId, super.key});

  final int itemId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ItemDetailCubit(context.read<ItemDetailRepository>())..load(itemId),
      child: const _ItemDetailView(),
    );
  }
}

class _ItemDetailView extends StatelessWidget {
  const _ItemDetailView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Story'),
      ),
      body: BlocBuilder<ItemDetailCubit, ItemDetailState>(
        builder: (context, state) {
          if (state.storyStatus == ItemDetailStoryStatus.initial ||
              state.storyStatus == ItemDetailStoryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.storyStatus == ItemDetailStoryStatus.failure) {
            return ItemDetailErrorView(
              message: state.storyErrorMessage ?? 'Unknown error',
              onRetry: () => context.read<ItemDetailCubit>().load(
                state.requestedItemId ?? 0,
              ),
            );
          }

          final story = state.story!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            children: [
              ItemDetailStoryCard(story: story),
              const SizedBox(height: 16),
              Text(
                'Comments ${story.descendants}',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (state.commentsStatus == ItemDetailCommentsStatus.loading ||
                  state.commentsStatus == ItemDetailCommentsStatus.initial)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.commentsStatus == ItemDetailCommentsStatus.failure)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.commentsErrorMessage ?? 'Failed to load comments.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.read<ItemDetailCubit>().reloadComments(),
                        child: const Text('Retry comments'),
                      ),
                    ],
                  ),
                )
              else if (state.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'No comments yet.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                ...state.comments.map(
                  (comment) => CommentTreeTile(node: comment),
                ),
            ],
          );
        },
      ),
    );
  }
}
