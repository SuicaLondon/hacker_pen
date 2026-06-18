import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_content_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:hacker_pen/src/core/api/models/hn_user.dart';
import 'package:hacker_pen/src/core/domain/hn_item.dart';
import 'package:hacker_pen/src/features/item_detail/data/item_detail_repository.dart';
import 'package:hacker_pen/src/features/item_detail/domain/comment_node.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/cubit/item_detail_cubit.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/cubit/item_detail_state.dart';

void main() {
  test('load emits story and comments success states', () async {
    final cubit = ItemDetailCubit(
      _FakeItemDetailRepository(),
      _FakeAiContentRepository(),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ItemDetailState>().having(
          (state) => state.storyStatus,
          'story status',
          ItemDetailStoryStatus.loading,
        ),
        isA<ItemDetailState>()
            .having(
              (state) => state.storyStatus,
              'story status',
              ItemDetailStoryStatus.success,
            )
            .having(
              (state) => state.commentsStatus,
              'comments status',
              ItemDetailCommentsStatus.loading,
            ),
        isA<ItemDetailState>()
            .having(
              (state) => state.commentsStatus,
              'comments status',
              ItemDetailCommentsStatus.success,
            )
            .having((state) => state.comments.single.comment.id, 'comment', 2),
      ]),
    );

    await cubit.load(1);
    await expectation;
  });

  test('load and reload expose failure states', () async {
    final repository = _FakeItemDetailRepository();
    final cubit = ItemDetailCubit(repository, _FakeAiContentRepository());

    repository.storyError = StateError('story failed');
    await cubit.load(1);
    expect(cubit.state.storyStatus, ItemDetailStoryStatus.failure);
    expect(cubit.state.storyErrorMessage, contains('story failed'));

    repository.storyError = null;
    repository.commentsError = StateError('comments failed');
    await cubit.load(1);
    expect(cubit.state.commentsStatus, ItemDetailCommentsStatus.failure);

    repository.commentsError = null;
    await cubit.reloadComments();
    expect(cubit.state.commentsStatus, ItemDetailCommentsStatus.success);
  });

  test(
    'summarizeStory exposes success, failure, and missing URL states',
    () async {
      final aiRepository = _FakeAiContentRepository(summary: 'summary result');
      final repository = _FakeItemDetailRepository(
        storyUrl: 'https://example.com',
      );
      final cubit = ItemDetailCubit(repository, aiRepository);

      await cubit.load(1);
      await cubit.summarizeStory();
      expect(cubit.state.summaryStatus, ItemDetailAiStatus.success);
      expect(cubit.state.summaryText, 'summary result');
      expect(aiRepository.summarizedUrls, ['https://example.com']);

      aiRepository.summaryError = StateError('summary failed');
      await cubit.summarizeStory();
      expect(cubit.state.summaryStatus, ItemDetailAiStatus.failure);
      expect(cubit.state.summaryErrorMessage, contains('summary failed'));

      final noUrlCubit = ItemDetailCubit(
        _FakeItemDetailRepository(),
        _FakeAiContentRepository(),
      );
      await noUrlCubit.load(1);
      await noUrlCubit.summarizeStory();
      expect(noUrlCubit.state.summaryStatus, ItemDetailAiStatus.failure);
      expect(noUrlCubit.state.summaryErrorMessage, contains('URL'));
    },
  );

  test('translates one comment into state map', () async {
    final aiRepository = _FakeAiContentRepository(translation: 'translated');
    final cubit = ItemDetailCubit(_FakeItemDetailRepository(), aiRepository);

    await cubit.translateComment(_comment(2));

    final translation = cubit.state.commentTranslations[2];
    expect(translation?.status, ItemDetailAiStatus.success);
    expect(translation?.text, 'translated');
    expect(translation?.showOriginal, isFalse);
    expect(aiRepository.translatedComments, ['comment']);
  });

  test('toggles cached translation without another AI request', () async {
    final aiRepository = _FakeAiContentRepository(translation: 'translated');
    final cubit = ItemDetailCubit(_FakeItemDetailRepository(), aiRepository);

    await cubit.translateComment(_comment(2));
    await cubit.translateComment(_comment(2));
    expect(cubit.state.commentTranslations[2]?.showOriginal, isTrue);
    await cubit.translateComment(_comment(2));
    expect(cubit.state.commentTranslations[2]?.showOriginal, isFalse);

    expect(aiRepository.translatedComments, ['comment']);
  });

  test('requests a new translation when translation mode changes', () async {
    final aiRepository = _FakeAiContentRepository(translation: 'translated');
    final cubit = ItemDetailCubit(_FakeItemDetailRepository(), aiRepository);

    await cubit.translateComment(_comment(2));
    aiRepository.mode = AiTranslationMode.paragraphPairs;
    await cubit.translateComment(_comment(2));

    expect(aiRepository.translatedComments, ['comment', 'comment']);
    expect(
      cubit.state.commentTranslations[2]?.mode,
      AiTranslationMode.paragraphPairs,
    );
  });

  test('translates descendants without translating the root comment', () async {
    final aiRepository = _FakeAiContentRepository(translation: 'translated');
    final cubit = ItemDetailCubit(_FakeItemDetailRepository(), aiRepository);
    final node = CommentNode(
      comment: _comment(1, text: 'root'),
      children: [
        CommentNode(
          comment: _comment(2, text: 'child'),
          children: [
            CommentNode(
              comment: _comment(3, text: 'grandchild'),
              children: const [],
            ),
          ],
        ),
      ],
    );

    await cubit.translateCommentChildren(node);

    expect(aiRepository.translatedComments, ['child', 'grandchild']);
    expect(cubit.state.commentTranslations.containsKey(1), isFalse);
    expect(
      cubit.state.commentTranslations[2]?.status,
      ItemDetailAiStatus.success,
    );
    expect(
      cubit.state.commentTranslations[3]?.status,
      ItemDetailAiStatus.success,
    );
    expect(cubit.state.threadTranslationLoadingIds, isEmpty);
  });

  test(
    'batch translation keeps translating descendants after one failure',
    () async {
      final aiRepository = _FakeAiContentRepository(translation: 'translated')
        ..translationErrors['child'] = StateError('child failed');
      final cubit = ItemDetailCubit(_FakeItemDetailRepository(), aiRepository);
      final node = CommentNode(
        comment: _comment(1, text: 'root'),
        children: [
          CommentNode(
            comment: _comment(2, text: 'child'),
            children: const [],
          ),
          CommentNode(
            comment: _comment(3, text: 'sibling'),
            children: const [],
          ),
        ],
      );

      await cubit.translateCommentChildren(node);

      expect(
        cubit.state.commentTranslations[2]?.status,
        ItemDetailAiStatus.failure,
      );
      expect(
        cubit.state.commentTranslations[3]?.status,
        ItemDetailAiStatus.success,
      );
      expect(cubit.state.threadTranslationLoadingIds, isEmpty);
    },
  );
}

class _FakeItemDetailRepository implements ItemDetailRepository {
  _FakeItemDetailRepository({this.storyUrl});

  final String? storyUrl;
  Object? storyError;
  Object? commentsError;

  @override
  Future<List<CommentNode>> fetchCommentsForStory(HnItem story) async {
    if (commentsError != null) throw commentsError!;
    return [CommentNode(comment: _comment(2), children: const [])];
  }

  @override
  Future<HnItem> fetchStory(int itemId) async {
    if (storyError != null) throw storyError!;
    return HnItem(
      id: itemId,
      type: 'story',
      time: 1,
      by: 'pg',
      title: 'story',
      score: 1,
      descendants: 1,
      url: storyUrl,
    );
  }

  @override
  Future<HnUser> fetchUser(String id) async {
    return HnUser(id: id, created: 1, karma: 1);
  }

  @override
  Future<HnItem> fetchUserPreviewItem(int id) => fetchStory(id);
}

class _FakeAiContentRepository extends AiContentRepository {
  _FakeAiContentRepository({
    this.summary = 'summary',
    this.translation = 'translation',
  }) : super(settingsRepository: _UnusedAiSettingsRepository());

  final String summary;
  final String translation;
  final summarizedUrls = <String>[];
  final translatedComments = <String>[];
  final translationErrors = <String, Object>{};
  var mode = AiTranslationMode.replaceOriginal;
  Object? summaryError;

  @override
  Future<String> summarizeWebPageUrl(String url) async {
    summarizedUrls.add(url);
    if (summaryError != null) throw summaryError!;
    return summary;
  }

  @override
  Future<String> translateComment(String rawCommentText) async {
    translatedComments.add(rawCommentText);
    final error = translationErrors[rawCommentText];
    if (error != null) throw error;
    return translation;
  }

  @override
  Future<AiTranslationMode> loadTranslationMode() async => mode;
}

class _UnusedAiSettingsRepository implements AiSettingsRepository {
  @override
  Future<void> clearApiKey(AiProviderId providerId) async {}

  @override
  Future<AiSettings> load({AiProviderId? providerId}) async {
    return AiSettings.defaultsFor(providerId ?? AiProviderId.openAiCompatible);
  }

  @override
  Future<String?> readApiKey(AiProviderId providerId) async => null;

  @override
  Future<void> save(AiSettings settings, {String? apiKeyReplacement}) async {}
}

HnItem _comment(int id, {String text = 'comment'}) {
  return HnItem(
    id: id,
    type: 'comment',
    time: 1,
    by: 'commenter',
    title: '',
    score: 0,
    descendants: 0,
    text: text,
  );
}
