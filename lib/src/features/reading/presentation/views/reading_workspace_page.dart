import '../../../../core/ai/ai_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ai/ai_content_repository.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/domain/hn_item.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/platform/macos_settings_bridge.dart';
import '../../../item_detail/data/item_detail_repository.dart';
import '../../../item_detail/presentation/cubit/item_detail_cubit.dart';
import '../../../item_detail/presentation/cubit/item_detail_state.dart';
import '../../../item_detail/presentation/views/item_detail_page.dart';
import '../../../item_detail/presentation/widgets/item_detail_discussion_pane.dart';
import '../../../items/presentation/views/items_page.dart';

/// News selection owns the article and its optional inspector.
class ReadingWorkspacePage extends StatefulWidget {
  const ReadingWorkspacePage({this.initialItemId, super.key});

  final int? initialItemId;

  @override
  State<ReadingWorkspacePage> createState() => _ReadingWorkspacePageState();
}

class _ReadingWorkspacePageState extends State<ReadingWorkspacePage> {
  static const _twoPaneWidth = 840.0;
  static const _threePaneWidth = 1120.0;
  final _feedKey = GlobalKey<ItemsPageState>();
  late final ItemDetailCubit _detailCubit;
  late final _nativeWorkspaceActionHandler = _handleWorkspaceAction;
  void Function(String)? _previousWorkspaceActionHandler;
  int? _selectedItemId;
  bool _newsOpen = true;
  bool _discussionOpen = false;
  bool _showSummary = false;
  double _width = 0;

  bool get _compact => _width < _twoPaneWidth;
  bool get _hasArticle => _selectedItemId != null;

  @override
  void initState() {
    super.initState();
    _detailCubit = ItemDetailCubit(
      context.read<ItemDetailRepository>(),
      context.read<AiContentRepository>(),
    );
    AiSettingsRepository.revision.addListener(_invalidateAiResults);
    _previousWorkspaceActionHandler =
        MacosSettingsBridge.workspaceActionHandler;
    MacosSettingsBridge.workspaceActionHandler = _nativeWorkspaceActionHandler;
    if (widget.initialItemId case final itemId?) {
      _selectedItemId = itemId;
      _detailCubit.load(itemId);
    }
  }

  void _invalidateAiResults() => _detailCubit.invalidateAiResults();

  void _handleWorkspaceAction(String action) {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) {
      if (action == 'back') Navigator.of(context).maybePop();
      return;
    }
    switch (action) {
      case 'toggleNews':
        final newsVisible =
            !_hasArticle ||
            (!_compact &&
                _newsOpen &&
                (!_discussionOpen || _width >= _threePaneWidth));
        _toggleNews(newsVisible);
      case 'toggleInspector':
        _toggleDiscussion();
      case 'refreshNews':
        _feedKey.currentState?.refresh();
      case 'back':
        _back();
    }
  }

  @override
  void dispose() {
    AiSettingsRepository.revision.removeListener(_invalidateAiResults);
    if (MacosSettingsBridge.workspaceActionHandler ==
        _nativeWorkspaceActionHandler) {
      MacosSettingsBridge.workspaceActionHandler =
          _previousWorkspaceActionHandler;
    }
    _detailCubit.close();
    super.dispose();
  }

  void _selectItem(HnItem item) {
    setState(() => _selectedItemId = item.id);
    if (_detailCubit.state.requestedItemId != item.id) {
      _detailCubit.load(item.id);
    }
  }

  void _closeArticle() {
    setState(() {
      _selectedItemId = null;
      _discussionOpen = false;
      _showSummary = false;
      _newsOpen = true;
    });
  }

  void _closeDiscussion() => setState(() => _discussionOpen = false);

  void _back() {
    if (_discussionOpen && _hasArticle) {
      _closeDiscussion();
    } else if (_hasArticle) {
      _closeArticle();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _toggleNews(bool visible) {
    if (!_hasArticle) return;
    if (_compact) {
      _closeArticle();
      return;
    }
    setState(() {
      _newsOpen = !visible;
      if (!visible && _width < _threePaneWidth) {
        _discussionOpen = false;
      }
    });
  }

  void _toggleDiscussion() {
    if (!_hasArticle) return;
    setState(() => _discussionOpen = !_discussionOpen);
  }

  void _showDiscussion({bool summary = false}) {
    if (!_hasArticle) return;
    setState(() {
      _showSummary = summary;
      _discussionOpen = true;
    });
    // Only the explicit Summary command starts AI work. Selecting another
    // article or resizing leaves its idle Generate summary control available.
    if (summary &&
        _detailCubit.state.story?.url?.isNotEmpty == true &&
        _detailCubit.state.summaryStatus == ItemDetailAiStatus.idle) {
      _detailCubit.summarizeStory();
    }
  }

  Future<void> _openSettings() async {
    if (Theme.of(context).platform == TargetPlatform.macOS) {
      try {
        await MacosSettingsBridge.openSettings();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Settings.')),
          );
        }
      }
    } else {
      Navigator.of(context).pushNamed(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _detailCubit,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          final hasArticle = _hasArticle;
          final discussionVisible = hasArticle && _discussionOpen;
          final newsVisible =
              !hasArticle ||
              (!_compact &&
                  _newsOpen &&
                  (!discussionVisible || _width >= _threePaneWidth));
          final newsWidth = !hasArticle
              ? _width
              : (_width * 0.23).clamp(260.0, 340.0).toDouble();
          final discussionWidth = _compact
              ? _width
              : (_width * 0.29).clamp(320.0, 420.0).toDouble();
          final platform = Theme.of(context).platform;
          final desktopLayout = platform == TargetPlatform.macOS || !_compact;
          final apple =
              platform == TargetPlatform.macOS ||
              platform == TargetPlatform.iOS;
          SingleActivator shortcut(
            LogicalKeyboardKey key, {
            bool shift = false,
          }) =>
              SingleActivator(key, meta: apple, control: !apple, shift: shift);

          return CallbackShortcuts(
            bindings: {
              shortcut(LogicalKeyboardKey.keyR): () =>
                  _feedKey.currentState?.refresh(),
              shortcut(LogicalKeyboardKey.comma): _openSettings,
              shortcut(LogicalKeyboardKey.keyB): () => _toggleNews(newsVisible),
              shortcut(LogicalKeyboardKey.keyB, shift: true): _toggleDiscussion,
              shortcut(LogicalKeyboardKey.bracketLeft): _back,
              const SingleActivator(LogicalKeyboardKey.escape): _back,
            },
            child: Focus(
              autofocus: true,
              child: PopScope(
                canPop: !hasArticle,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop) _back();
                },
                child: Scaffold(
                  backgroundColor: context.hpColors.paper,
                  body: SafeArea(
                    top: desktopLayout,
                    bottom: desktopLayout,
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, bodyConstraints) =>
                                TweenAnimationBuilder<Offset>(
                                  tween: Tween<Offset>(
                                    end: Offset(
                                      newsVisible ? 1 : 0,
                                      discussionVisible ? 1 : 0,
                                    ),
                                  ),
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 240),
                                  curve: Curves.easeInOutCubic,
                                  builder: (context, progress, _) {
                                    final newsExtent = !hasArticle
                                        ? _width
                                        : _compact
                                        ? 0.0
                                        : progress.dx * newsWidth;
                                    final discussionExtent =
                                        progress.dy * discussionWidth;
                                    return Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ExcludeFocus(
                                            excluding:
                                                _compact && discussionVisible,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _PaneSlot(
                                                  visible: newsExtent > 0,
                                                  width: newsWidth,
                                                  viewportWidth: newsExtent,
                                                  paneKey: 'news-pane',
                                                  child: ItemsPage(
                                                    key: _feedKey,
                                                    embedded: desktopLayout,
                                                    wideLayout: desktopLayout,
                                                    onClose:
                                                        hasArticle &&
                                                            desktopLayout
                                                        ? () =>
                                                              _toggleNews(true)
                                                        : null,
                                                    selectedItemId:
                                                        _selectedItemId,
                                                    onItemSelected: _selectItem,
                                                  ),
                                                ),
                                                _PaneSlot(
                                                  visible: hasArticle,
                                                  width:
                                                      (_width -
                                                              newsExtent -
                                                              (_compact
                                                                  ? 0
                                                                  : discussionExtent))
                                                          .clamp(1.0, _width),
                                                  paneKey: 'reader-pane',
                                                  bordered: newsVisible,
                                                  child: hasArticle
                                                      ? ItemDetailReader(
                                                          key: ValueKey(
                                                            _selectedItemId,
                                                          ),
                                                          embedded:
                                                              desktopLayout,
                                                          wideLayout:
                                                              desktopLayout,
                                                          onShowNews:
                                                              !newsVisible &&
                                                                  desktopLayout
                                                              ? () =>
                                                                    _toggleNews(
                                                                      false,
                                                                    )
                                                              : null,
                                                          onClose:
                                                              _closeArticle,
                                                          onBack: _closeArticle,
                                                          onComments:
                                                              _showDiscussion,
                                                          onSummary: () =>
                                                              _showDiscussion(
                                                                summary: true,
                                                              ),
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Offstage(
                                            offstage:
                                                !_compact || !discussionVisible,
                                            child: ModalBarrier(
                                              key: const ValueKey(
                                                'inspector-scrim',
                                              ),
                                              color: Colors.black26,
                                              dismissible: true,
                                              onDismiss: _closeDiscussion,
                                              semanticsLabel:
                                                  'Close discussion',
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right:
                                              discussionExtent -
                                              discussionWidth,
                                          top: 0,
                                          bottom: 0,
                                          width: discussionWidth,
                                          child: _PaneSlot(
                                            visible: discussionExtent > 0,
                                            width: discussionWidth,
                                            paneKey: 'discussion-pane',
                                            bordered: !_compact,
                                            child: ItemDetailDiscussionPane(
                                              key: ValueKey(_selectedItemId),
                                              showSummary: _showSummary,
                                              wideLayout: desktopLayout,
                                              onShowComments: _showDiscussion,
                                              onShowSummary: () =>
                                                  _showDiscussion(
                                                    summary: true,
                                                  ),
                                              onClose: _closeDiscussion,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Stable slots preserve article and inspector state through layout changes.
class _PaneSlot extends StatelessWidget {
  const _PaneSlot({
    required this.visible,
    required this.width,
    required this.paneKey,
    required this.child,
    this.bordered = false,
    this.viewportWidth,
  });

  final bool visible;
  final double width;
  final String paneKey;
  final Widget child;
  final bool bordered;
  final double? viewportWidth;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !visible,
      child: ExcludeFocus(
        excluding: !visible,
        child: TickerMode(
          enabled: visible,
          child: SizedBox(
            width: viewportWidth ?? width,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: width,
                maxWidth: width,
                child: SizedBox(
                  key: ValueKey(paneKey),
                  width: width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      if (bordered)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: context.hpColors.rule,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
