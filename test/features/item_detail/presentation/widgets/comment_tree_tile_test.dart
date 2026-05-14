import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/theme/app_theme.dart';
import 'package:hacker_pen/src/features/item_detail/domain/comment_node.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/widgets/comment_tree_tile.dart';

void main() {
  testWidgets('keeps deeply nested comment text readable on narrow screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const deepestText =
        'deep comment 8 should still have enough horizontal room to read';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommentTreeTile(node: _commentTree(0, deepestText)),
          ),
        ),
      ),
    );

    final deepestComment = tester.renderObject<RenderBox>(
      find.text(deepestText),
    );

    expect(deepestComment.size.width, greaterThanOrEqualTo(220));
  });
}

CommentNode _commentTree(int depth, String deepestText) {
  final isDeepest = depth == 8;

  return CommentNode(
    comment: HnItem(
      id: depth,
      type: 'comment',
      time: 1,
      by: 'user$depth',
      title: '',
      score: 0,
      descendants: 0,
      text: isDeepest ? deepestText : 'comment $depth',
    ),
    children: isDeepest ? const [] : [_commentTree(depth + 1, deepestText)],
  );
}
