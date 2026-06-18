import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/core/theme/app_theme.dart';
import 'package:hacker_pen/src/features/item_detail/domain/comment_node.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/cubit/item_detail_state.dart';
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

  testWidgets('keeps original comment visible while translation is loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: _singleComment(1, 'original comment'),
            translations: const {
              1: CommentTranslationState(status: ItemDetailAiStatus.loading),
            },
            onTranslateComment: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('original comment'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('replaces original comment text after translation succeeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: _singleComment(1, 'original comment'),
            translations: const {
              1: CommentTranslationState(
                status: ItemDetailAiStatus.success,
                text: 'translated comment',
              ),
            },
            onTranslateComment: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('original comment'), findsNothing);
    expect(find.text('translated comment'), findsOneWidget);
  });

  testWidgets('can show original text after a cached translation succeeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: _singleComment(1, 'original comment'),
            translations: const {
              1: CommentTranslationState(
                status: ItemDetailAiStatus.success,
                text: 'translated comment',
              ),
            },
            onTranslateComment: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('translated comment'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: _singleComment(1, 'original comment'),
            translations: const {
              1: CommentTranslationState(
                status: ItemDetailAiStatus.success,
                text: 'translated comment',
                showOriginal: true,
              ),
            },
            onTranslateComment: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('original comment'), findsOneWidget);
    expect(find.text('translated comment'), findsNothing);
  });

  testWidgets('shows paragraph pair translation blocks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: _singleComment(1, 'original one\n\noriginal two'),
            translations: const {
              1: CommentTranslationState(
                status: ItemDetailAiStatus.success,
                text: 'translated one\n\ntranslated two',
                mode: AiTranslationMode.paragraphPairs,
              ),
            },
            onTranslateComment: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Original'), findsNothing);
    expect(find.text('Translation'), findsNothing);
    expect(find.text('original one'), findsOneWidget);
    expect(find.text('translated one'), findsOneWidget);
    expect(find.text('original two'), findsOneWidget);
    expect(find.text('translated two'), findsOneWidget);
  });

  testWidgets('falls back to full blocks when paragraph counts differ', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: _singleComment(1, 'original one\n\noriginal two'),
            translations: const {
              1: CommentTranslationState(
                status: ItemDetailAiStatus.success,
                text: 'translated all together',
                mode: AiTranslationMode.paragraphPairs,
              ),
            },
            onTranslateComment: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Original'), findsNothing);
    expect(find.text('Translation'), findsNothing);
    expect(find.text('original one\n\noriginal two'), findsOneWidget);
    expect(find.text('translated all together'), findsOneWidget);
  });

  testWidgets('decodes numeric entities in visible comment URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: _singleComment(
              1,
              'https:&#x2F;&#x2F;example.com&#47;path?x=1&amp;y=2',
            ),
          ),
        ),
      ),
    );

    expect(find.text('https://example.com/path?x=1&y=2'), findsOneWidget);
  });

  testWidgets('shows translate replies action for comments with children', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CommentTreeTile(
            node: CommentNode(
              comment: _comment(1, 'parent'),
              children: [_singleComment(2, 'child')],
            ),
            onTranslateComment: (_) {},
            onTranslateReplies: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.translate), findsWidgets);
    expect(find.text('Translate replies'), findsOneWidget);
  });
}

CommentNode _singleComment(int id, String text) {
  return CommentNode(comment: _comment(id, text), children: const []);
}

CommentNode _commentTree(int depth, String deepestText) {
  final isDeepest = depth == 8;

  return CommentNode(
    comment: _comment(depth, isDeepest ? deepestText : 'comment $depth'),
    children: isDeepest ? const [] : [_commentTree(depth + 1, deepestText)],
  );
}

HnItem _comment(int id, String text) {
  return HnItem(
    id: id,
    type: 'comment',
    time: 1,
    by: 'user$id',
    title: '',
    score: 0,
    descendants: 0,
    text: text,
  );
}
