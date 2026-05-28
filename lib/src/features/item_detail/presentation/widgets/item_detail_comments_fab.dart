import 'package:flutter/material.dart';

class ItemDetailCommentsFab extends StatelessWidget {
  const ItemDetailCommentsFab({
    required this.count,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final int count;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: onPressed,
      tooltip: 'Comments',
      backgroundColor: isLoading ? colorScheme.surfaceContainerHighest : null,
      foregroundColor: isLoading ? colorScheme.onSurfaceVariant : null,
      icon: isLoading
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                color: colorScheme.onSurfaceVariant,
                strokeWidth: 2.4,
              ),
            )
          : const Icon(Icons.mode_comment_outlined),
      label: Text(isLoading ? 'Loading $count' : '$count'),
    );
  }
}
