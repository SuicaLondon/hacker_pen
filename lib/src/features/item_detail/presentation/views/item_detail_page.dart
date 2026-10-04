import '../widgets/item_detail_wide_header.dart';
import '../widgets/item_detail_header.dart';
import '../widgets/story_web_view.dart';
import '../widgets/item_detail_summary_fab.dart';
import '../widgets/item_detail_summary_body.dart';
import '../widgets/item_detail_text_body.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ai/ai_content_repository.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/settings/reading_preferences_cubit.dart';
import '../../data/item_detail_repository.dart';
import '../cubit/item_detail_cubit.dart';
import '../cubit/item_detail_state.dart';
import '../widgets/item_detail_actions_dock.dart';
import '../widgets/item_detail_comments_fab.dart';
import '../widgets/item_detail_comments_sheet.dart';

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({required this.itemId, super.key});

  final int itemId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItemDetailCubit(
        context.read<ItemDetailRepository>(),
        context.read<AiContentRepository>(),
      )..load(itemId),
      child: const ItemDetailReader(),
    );
  }
}

class ItemDetailReader extends StatefulWidget {
  const ItemDetailReader({
    this.embedded = false,
    this.wideLayout = false,
    this.onBack,
    this.onClose,
    this.onComments,
    this.onSummary,
    this.onShowNews,
    super.key,
  });

  final bool embedded;
  final bool wideLayout;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final VoidCallback? onComments;
  final VoidCallback? onSummary;
  final VoidCallback? onShowNews;

  @override
  State<ItemDetailReader> createState() => _ItemDetailReaderState();
}

class _ItemDetailReaderState extends State<ItemDetailReader> {
  final _header = HpScrollHeaderController();
  final _scrollActivity = ValueNotifier(0);
  double _lastWebOffset = 0;
  bool _isSavingReading = false;

  @override
  void initState() {
    super.initState();
    _header.addListener(_updateHeader);
  }

  void _updateHeader() {
    if (mounted) setState(() {});
  }

  void _onWebScroll(double offset) {
    if (!offset.isFinite) return;
    if (offset != _lastWebOffset) _scrollActivity.value++;
    _lastWebOffset = offset;
    _header.update(offset);
  }

  void _onUserScroll(double delta) {
    if (delta.isFinite && delta != 0) _scrollActivity.value++;
    _header.recordUserScroll(delta);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical &&
        (notification is ScrollStartNotification ||
            notification is ScrollUpdateNotification ||
            notification is OverscrollNotification)) {
      _scrollActivity.value++;
    }
    return _header.handleScrollNotification(notification);
  }

  Future<void> _toggleTopSafeArea() async {
    if (_isSavingReading) return;
    setState(() => _isSavingReading = true);
    try {
      final preferences = context.read<ReadingPreferencesCubit>();
      await preferences.setExtendPageBehindStatusBar(!preferences.state);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save reading preferences.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingReading = false);
    }
  }

  @override
  void dispose() {
    _scrollActivity.dispose();
    _header.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extendPage = context.watch<ReadingPreferencesCubit>().state;
    final topInset = MediaQuery.paddingOf(context).top;
    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
        final story = state.story;
        final extendsWebPage =
            !widget.embedded &&
            !widget.wideLayout &&
            extendPage &&
            story?.url?.isNotEmpty == true &&
            _supportsInlineWebView;
        final isImmersive = extendsWebPage && !_header.isVisible;
        final onBack = widget.onBack ?? () => Navigator.of(context).maybePop();
        final onComments =
            widget.onComments ?? () => showItemDetailCommentsSheet(context);
        final onSummary =
            widget.onSummary ?? () => showStorySummarySheet(context);
        final storyHeader = widget.wideLayout
            ? ItemDetailWideHeader(
                story: story,
                onComments: story == null ? null : onComments,
                onSummary: story?.url?.isNotEmpty == true ? onSummary : null,
                onClose: widget.onClose,
                onShowNews: widget.onShowNews,
              )
            : story == null
            ? null
            : ItemDetailHeader(
                story: story,
                extendsPage: extendPage,
                showSafeAreaToggle:
                    !widget.embedded &&
                    story.url?.isNotEmpty == true &&
                    _supportsInlineWebView,
                onToggleSafeArea: _isSavingReading ? null : _toggleTopSafeArea,
                onBack: onBack,
                onComments: widget.embedded ? onComments : null,
                onSummaryPressed: story.url?.isNotEmpty == true
                    ? onSummary
                    : null,
              );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: isImmersive
                ? Colors.transparent
                : context.hpColors.paper,
            statusBarIconBrightness: isImmersive
                ? Brightness.dark
                : Brightness.light,
            statusBarBrightness: isImmersive
                ? Brightness.light
                : Brightness.dark,
            systemStatusBarContrastEnforced: !isImmersive,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            floatingActionButtonLocation: ItemDetailActionsDock.location,
            floatingActionButtonAnimator:
                FloatingActionButtonAnimator.noAnimation,
            floatingActionButton:
                story == null || widget.embedded || widget.wideLayout
                ? null
                : ItemDetailActionsDock(
                    scrollActivity: _scrollActivity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 10,
                      children: [
                        if (story.url?.isNotEmpty == true)
                          ItemDetailSummaryFab(
                            isLoading:
                                state.summaryStatus ==
                                ItemDetailAiStatus.loading,
                            onPressed: onSummary,
                          ),
                        ItemDetailCommentsFab(
                          count: story.descendants,
                          isLoading:
                              state.commentsStatus ==
                                  ItemDetailCommentsStatus.loading ||
                              state.commentsStatus ==
                                  ItemDetailCommentsStatus.initial,
                          onPressed:
                              state.commentsStatus ==
                                      ItemDetailCommentsStatus.loading ||
                                  state.commentsStatus ==
                                      ItemDetailCommentsStatus.initial
                              ? null
                              : onComments,
                        ),
                      ],
                    ),
                  ),
            body: SafeArea(
              top: !extendsWebPage,
              bottom: false,
              child: Column(
                children: [
                  if (widget.wideLayout)
                    storyHeader!
                  else if (story == null)
                    HpTopBar(
                      title: 'Story',
                      leading: HpIconButton(
                        tooltip: 'Back',
                        onPressed: onBack,
                        icon: Icons.arrow_back,
                      ),
                    )
                  else if (widget.embedded)
                    storyHeader!
                  else
                    HpCollapsibleHeader(
                      isVisible: _header.isVisible,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: extendsWebPage ? topInset : 0,
                        ),
                        child: storyHeader!,
                      ),
                    ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: Builder(
                        builder: (context) {
                          if (state.storyStatus ==
                                  ItemDetailStoryStatus.initial ||
                              state.storyStatus ==
                                  ItemDetailStoryStatus.loading) {
                            return const HpLoadingView(label: 'Loading story');
                          }

                          if (state.storyStatus ==
                              ItemDetailStoryStatus.failure) {
                            return HpErrorView(
                              title: 'Failed to load detail',
                              retryLabel: 'Retry',
                              message:
                                  state.storyErrorMessage ?? 'Unknown error',
                              onRetry: () => context
                                  .read<ItemDetailCubit>()
                                  .load(state.requestedItemId ?? 0),
                            );
                          }

                          final loadedStory = state.story!;
                          final storyUrl = loadedStory.url;

                          if (storyUrl == null || storyUrl.isEmpty) {
                            return SelfPostBody(story: loadedStory);
                          }

                          if (!_supportsInlineWebView) {
                            return UnsupportedWebViewBody(url: storyUrl);
                          }

                          return StoryWebView(
                            url: storyUrl,
                            onScroll: _onWebScroll,
                            onUserScroll: _onUserScroll,
                            onNavigationStarted: () {
                              _lastWebOffset = 0;
                              _header.reset();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

bool get _supportsInlineWebView {
  if (kIsWeb) return false;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => false,
  };
}
