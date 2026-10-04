import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../reading/presentation/widgets/reading_pane_header.dart';
import '../cubit/item_detail_cubit.dart';
import '../cubit/item_detail_state.dart';
import '../widgets/item_detail_summary_body.dart';
import 'item_detail_comments_sheet.dart';

/// The same inspector bodies become the original draggable sheets on iPad.
class ItemDetailDiscussionPane extends StatefulWidget {
  const ItemDetailDiscussionPane({
    required this.showSummary,
    this.wideLayout = false,
    this.onShowComments,
    this.onShowSummary,
    this.onClose,
    super.key,
  });

  final bool showSummary;
  final bool wideLayout;
  final VoidCallback? onShowComments;
  final VoidCallback? onShowSummary;
  final VoidCallback? onClose;

  @override
  State<ItemDetailDiscussionPane> createState() =>
      _ItemDetailDiscussionPaneState();
}

class _ItemDetailDiscussionPaneState extends State<ItemDetailDiscussionPane> {
  final _commentsSheet = DraggableScrollableController();
  final _summarySheet = DraggableScrollableController();
  final _wideCommentsScroll = ScrollController();
  final _wideSummaryScroll = ScrollController();
  double _commentsExtent = 0.94;
  double _summaryExtent = 0.55;
  bool _dismissQueued = false;

  @override
  void didUpdateWidget(covariant ItemDetailDiscussionPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wideLayout == widget.wideLayout) return;
    if (widget.wideLayout) {
      if (_commentsSheet.isAttached) _commentsExtent = _commentsSheet.size;
      if (_summarySheet.isAttached) _summaryExtent = _summarySheet.size;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.wideLayout) return;
        if (_commentsSheet.isAttached) {
          _commentsSheet.jumpTo(_commentsExtent);
        }
        if (_summarySheet.isAttached) {
          _summarySheet.jumpTo(_summaryExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _commentsSheet.dispose();
    _summarySheet.dispose();
    _wideCommentsScroll.dispose();
    _wideSummaryScroll.dispose();
    super.dispose();
  }

  bool _onExtent(DraggableScrollableNotification notification, bool summary) {
    if (!widget.wideLayout &&
        widget.showSummary == summary &&
        notification.depth == 0 &&
        notification.extent <= notification.minExtent &&
        notification.shouldCloseOnMinExtent &&
        !_dismissQueued) {
      _dismissQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dismissQueued = false;
        if (mounted && !widget.wideLayout && widget.showSummary == summary) {
          widget.onClose?.call();
        }
      });
    }
    return false;
  }

  void _dragCommentsHeader(double delta, double height) {
    if (!_commentsSheet.isAttached || height <= 0) return;
    _commentsSheet.jumpTo(
      (_commentsSheet.size - delta / height).clamp(0.55, 1),
    );
  }

  void _snapCommentsHeader() {
    if (!_commentsSheet.isAttached) return;
    final extent = _commentsSheet.size;
    final snap = extent < (0.55 + 0.94) / 2
        ? 0.55
        : extent < (0.94 + 1) / 2
        ? 0.94
        : 1.0;
    _commentsSheet.animateTo(
      snap,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: !widget.wideLayout,
      bottom: false,
      child: Column(
        children: [
          Offstage(
            offstage: !widget.wideLayout,
            child: ReadingPaneHeader(
              key: const ValueKey('wide-discussion-header'),
              child: BlocBuilder<ItemDetailCubit, ItemDetailState>(
                builder: (context, state) => Row(
                  key: const ValueKey('wide-discussion-tabs'),
                  children: [
                    Expanded(
                      child: _DiscussionTab(
                        label: 'Comments ${state.story?.descendants ?? 0}',
                        selected: !widget.showSummary,
                        onPressed: widget.onShowComments,
                      ),
                    ),
                    Expanded(
                      child: _DiscussionTab(
                        label: 'Summary',
                        selected: widget.showSummary,
                        onPressed: state.story?.url?.isNotEmpty == true
                            ? widget.onShowSummary
                            : null,
                      ),
                    ),
                    if (!widget.showSummary)
                      _DiscussionControl(
                        tooltip: 'Reload comments',
                        onPressed:
                            state.commentsStatus ==
                                ItemDetailCommentsStatus.loading
                            ? null
                            : context.read<ItemDetailCubit>().reloadComments,
                        icon: Icons.refresh,
                      ),
                    if (widget.onClose != null)
                      _DiscussionControl(
                        tooltip: 'Close discussion',
                        onPressed: widget.onClose,
                        icon: Icons.close,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: widget.showSummary ? 1 : 0,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        NotificationListener<DraggableScrollableNotification>(
                          onNotification: (notification) =>
                              _onExtent(notification, false),
                          child: DraggableScrollableSheet(
                            key: const ValueKey('comments-sheet'),
                            controller: _commentsSheet,
                            expand: false,
                            initialChildSize: widget.wideLayout ? 1 : 0.94,
                            minChildSize: widget.wideLayout ? 1 : 0.55,
                            maxChildSize: 1,
                            snap: !widget.wideLayout,
                            snapSizes: widget.wideLayout
                                ? null
                                : const [0.94, 1],
                            builder: (context, sheetScroll) =>
                                ItemDetailCommentsSheet(
                                  // Fixed extents absorb touch drags at zero.
                                  // A normal controller lets a desktop pane
                                  // scroll while Flutter carries its position
                                  // between the two controller types on resize.
                                  scrollController: widget.wideLayout
                                      ? _wideCommentsScroll
                                      : sheetScroll,
                                  showHeader: !widget.wideLayout,
                                  onClose: widget.onClose,
                                  onHeaderDragUpdate: widget.wideLayout
                                      ? null
                                      : (delta) => _dragCommentsHeader(
                                          delta,
                                          constraints.maxHeight,
                                        ),
                                  onHeaderDragEnd: widget.wideLayout
                                      ? null
                                      : _snapCommentsHeader,
                                ),
                          ),
                        ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) =>
                        _onExtent(notification, true),
                    child: DraggableScrollableSheet(
                      key: const ValueKey('summary-sheet'),
                      controller: _summarySheet,
                      expand: false,
                      initialChildSize: widget.wideLayout ? 1 : 0.55,
                      minChildSize: widget.wideLayout ? 1 : 0.35,
                      maxChildSize: widget.wideLayout ? 1 : 0.92,
                      builder: (context, sheetScroll) => ItemDetailSummaryBody(
                        scrollController: widget.wideLayout
                            ? _wideSummaryScroll
                            : sheetScroll,
                        showSheetHeader: !widget.wideLayout,
                        wideLayout: widget.wideLayout,
                        onClose: widget.onClose,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscussionTab extends StatelessWidget {
  const _DiscussionTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    return Semantics(
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colors.brand : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: selected ? colors.brand : colors.inkMuted,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: Theme.of(context).textTheme.labelMedium,
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _DiscussionControl extends StatelessWidget {
  const _DiscussionControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: context.hpColors.inkMuted,
        fixedSize: const Size.square(32),
        minimumSize: const Size.square(32),
        padding: EdgeInsets.zero,
        iconSize: 17,
      ),
      icon: Icon(icon),
    );
  }
}
