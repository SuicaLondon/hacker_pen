import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Story'),
      ),
      body: BlocBuilder<ItemDetailCubit, ItemDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case ItemDetailStatus.initial:
            case ItemDetailStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ItemDetailStatus.failure:
              return ItemDetailErrorView(
                message: state.errorMessage ?? 'Unknown error',
                onRetry: () => context.read<ItemDetailCubit>().load(
                  state.requestedItemId ?? 0,
                ),
              );
            case ItemDetailStatus.success:
              final detail = state.detail!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                children: [
                  ItemDetailStoryCard(story: detail.story),
                  const SizedBox(height: 16),
                  Text(
                    'Comments ${detail.story.descendants}',
                    style: const TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (detail.comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'No comments yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...detail.comments.map(
                      (comment) => CommentTreeTile(node: comment),
                    ),
                ],
              );
          }
        },
      ),
    );
  }
}
