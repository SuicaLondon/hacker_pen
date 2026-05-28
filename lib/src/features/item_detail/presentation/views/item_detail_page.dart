import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/domain/hn_item.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../data/item_detail_repository.dart';
import '../cubit/item_detail_cubit.dart';
import '../cubit/item_detail_state.dart';
import '../widgets/item_detail_comments_fab.dart';
import '../widgets/item_detail_comments_sheet.dart';
import '../widgets/item_detail_error_view.dart';

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

class _ItemDetailView extends StatefulWidget {
  const _ItemDetailView();

  @override
  State<_ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<_ItemDetailView> {
  var _isHeaderVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ItemDetailCubit, ItemDetailState>(
      builder: (context, state) {
        final story = state.story;
        final usesOverlayHeader =
            story?.url?.isNotEmpty == true && _supportsInlineWebView;

        return Scaffold(
          extendBodyBehindAppBar: usesOverlayHeader,
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: story == null
              ? AppBar(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  centerTitle: true,
                  title: const Text('Story'),
                )
              : PreferredSize(
                  preferredSize: const Size.fromHeight(76),
                  child: _AnimatedStoryHeader(
                    isVisible: _isHeaderVisible,
                    story: story,
                  ),
                ),
          floatingActionButton: story == null
              ? null
              : ItemDetailCommentsFab(
                  count: story.descendants,
                  isLoading:
                      state.commentsStatus ==
                          ItemDetailCommentsStatus.loading ||
                      state.commentsStatus == ItemDetailCommentsStatus.initial,
                  onPressed:
                      state.commentsStatus ==
                              ItemDetailCommentsStatus.loading ||
                          state.commentsStatus ==
                              ItemDetailCommentsStatus.initial
                      ? null
                      : () => showItemDetailCommentsSheet(context),
                ),
          body: Builder(
            builder: (context) {
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

              final loadedStory = state.story!;
              final storyUrl = loadedStory.url;

              if (storyUrl == null || storyUrl.isEmpty) {
                return _SelfPostBody(story: loadedStory);
              }

              if (!_supportsInlineWebView) {
                return _UnsupportedWebViewBody(url: storyUrl);
              }

              return _StoryWebView(
                url: storyUrl,
                headerHeight: 76,
                isHeaderVisible: _isHeaderVisible,
                onHeaderVisibilityChanged: _setHeaderVisible,
              );
            },
          ),
        );
      },
    );
  }

  void _setHeaderVisible(bool isVisible) {
    if (_isHeaderVisible == isVisible || !mounted) return;
    setState(() => _isHeaderVisible = isVisible);
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

class _StoryAppBarTitle extends StatelessWidget {
  const _StoryAppBarTitle({required this.story});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          story.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'by ${story.by} | ${TimeFormatter.relativeFromUnixSeconds(story.time)} | ${story.score} points',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFamily: AppFonts.text,
          ),
        ),
      ],
    );
  }
}

class _AnimatedStoryHeader extends StatelessWidget {
  const _AnimatedStoryHeader({required this.isVisible, required this.story});

  final bool isVisible;
  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, -0.18),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          opacity: isVisible ? 1 : 0,
          child: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.96,
            ),
            centerTitle: true,
            toolbarHeight: 76,
            title: _StoryAppBarTitle(story: story),
          ),
        ),
      ),
    );
  }
}

class _StoryWebView extends StatefulWidget {
  const _StoryWebView({
    required this.url,
    required this.headerHeight,
    required this.isHeaderVisible,
    required this.onHeaderVisibilityChanged,
  });

  final String url;
  final double headerHeight;
  final bool isHeaderVisible;
  final ValueChanged<bool> onHeaderVisibilityChanged;

  @override
  State<_StoryWebView> createState() => _StoryWebViewState();
}

class _StoryWebViewState extends State<_StoryWebView> {
  WebViewController? _controller;
  var _progress = 0;
  var _hasLoadedFirstPage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant _StoryWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = _controller;

    if (controller == null) {
      return _UnsupportedWebViewBody(url: widget.url);
    }

    return Stack(
      children: [
        AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            top: widget.isHeaderVisible ? widget.headerHeight : 0,
          ),
          child: WebViewWidget(controller: controller),
        ),
        if (!_hasLoadedFirstPage)
          Positioned.fill(
            child: ColoredBox(
              color: colorScheme.surface,
              child: Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        if (_progress < 100)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                value: _progress == 0 ? null : _progress / 100,
              ),
            ),
          ),
        if (_errorMessage != null)
          Positioned.fill(
            child: ColoredBox(
              color: colorScheme.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load this page.\n$_errorMessage',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: AppFonts.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _initializeController() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _progress = progress);
            },
            onPageStarted: (_) {
              if (!mounted) return;
              widget.onHeaderVisibilityChanged(true);
              setState(() {
                _errorMessage = null;
                _hasLoadedFirstPage = false;
              });
            },
            onPageFinished: (_) {
              if (!mounted) return;
              _installScrollBridge();
              setState(() => _hasLoadedFirstPage = true);
            },
            onWebResourceError: (error) {
              if (!mounted || error.isForMainFrame != true) return;
              widget.onHeaderVisibilityChanged(true);
              setState(() => _errorMessage = error.description);
            },
          ),
        )
        ..addJavaScriptChannel(
          'HeaderBridge',
          onMessageReceived: (message) {
            if (message.message == 'hide') {
              widget.onHeaderVisibilityChanged(false);
            } else if (message.message == 'show') {
              widget.onHeaderVisibilityChanged(true);
            }
          },
        );
      _load(widget.url);
    } catch (_) {
      _controller = null;
    }
  }

  void _load(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      setState(() => _errorMessage = 'Invalid URL');
      return;
    }

    final normalizedUri = uri.hasScheme ? uri : Uri.parse('https://$url');
    _controller?.loadRequest(normalizedUri);
  }

  Future<void> _installScrollBridge() async {
    try {
      await _controller?.runJavaScript('''
      (function() {
        if (window.__hackerPenHeaderBridgeInstalled) return;
        window.__hackerPenHeaderBridgeInstalled = true;
        var lastY = window.scrollY || document.documentElement.scrollTop || 0;
        var ticking = false;

        function currentY() {
          return window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0;
        }

        function update() {
          var y = currentY();
          var delta = y - lastY;
          if (y < 12 || delta < -8) {
            HeaderBridge.postMessage('show');
          } else if (delta > 6 && y > 10) {
            HeaderBridge.postMessage('hide');
          }
          lastY = y;
          ticking = false;
        }

        window.addEventListener('scroll', function() {
          if (ticking) return;
          ticking = true;
          window.requestAnimationFrame(update);
        }, { passive: true });
      })();
    ''');
    } catch (_) {
      widget.onHeaderVisibilityChanged(true);
    }
  }
}

class _SelfPostBody extends StatelessWidget {
  const _SelfPostBody({required this.story});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodyText = TextSanitizer.stripHtml(story.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        Text(
          bodyText.isEmpty ? 'No story text available.' : bodyText,
          style: TextStyle(
            color: bodyText.isEmpty
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
            fontFamily: AppFonts.text,
            fontSize: 17,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _UnsupportedWebViewBody extends StatelessWidget {
  const _UnsupportedWebViewBody({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SelectableText(
          url,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.primary,
            fontFamily: AppFonts.text,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
