import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/design_system.dart';
import '../cubit/item_detail_cubit.dart';
import '../cubit/item_detail_state.dart';

void showStorySummarySheet(BuildContext context) {
  final cubit = context.read<ItemDetailCubit>();
  if (cubit.state.summaryStatus == ItemDetailAiStatus.idle) {
    cubit.summarizeStory();
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return BlocProvider.value(
        value: cubit,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ItemDetailSummaryBody(
              scrollController: scrollController,
              showSheetHeader: true,
            );
          },
        ),
      );
    },
  );
}

class ItemDetailSummaryBody extends StatelessWidget {
  const ItemDetailSummaryBody({
    this.scrollController,
    this.showSheetHeader = false,
    this.wideLayout = false,
    this.onClose,
    super.key,
  });

  final ScrollController? scrollController;
  final bool showSheetHeader;
  final bool wideLayout;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final text = Theme.of(context).textTheme;

    return Material(
      color: colors.paper,
      borderRadius: showSheetHeader
          ? const BorderRadius.vertical(top: Radius.circular(24))
          : BorderRadius.zero,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: BlocBuilder<ItemDetailCubit, ItemDetailState>(
          builder: (context, state) {
            return ListView(
              controller: scrollController,
              primary: false,
              padding: wideLayout
                  ? const EdgeInsets.fromLTRB(16, 16, 16, 24)
                  : const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                if (showSheetHeader)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.ruleStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                if (showSheetHeader)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          color: colors.brand,
                          size: 20,
                        ),
                        Expanded(
                          child: Text(
                            'Summary',
                            style: text.titleLarge?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        HpIconButton(
                          tooltip: 'Close',
                          onPressed:
                              onClose ?? () => Navigator.of(context).pop(),
                          icon: Icons.close,
                        ),
                      ],
                    ),
                  ),
                if (!wideLayout && state.story != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      state.story!.title,
                      style: text.titleMedium?.copyWith(
                        color: colors.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (!wideLayout) const HpDivider(),
                Padding(
                  padding: EdgeInsets.only(top: wideLayout ? 0 : 24),
                  child: switch (state.summaryStatus) {
                    ItemDetailAiStatus.idle => Center(
                      child: OutlinedButton.icon(
                        onPressed: state.story?.url?.isNotEmpty == true
                            ? () => context
                                  .read<ItemDetailCubit>()
                                  .summarizeStory()
                            : null,
                        icon: const Icon(Icons.summarize_outlined),
                        label: const Text('Generate summary'),
                      ),
                    ),
                    ItemDetailAiStatus.loading => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        spacing: 16,
                        children: [
                          const HpActivityIndicator(size: 20),
                          Expanded(
                            child: Text(
                              'Writing your summary…',
                              style: text.bodyMedium?.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ItemDetailAiStatus.failure => _SummaryErrorView(
                      message:
                          state.summaryErrorMessage ?? 'Failed to summarize.',
                    ),
                    ItemDetailAiStatus.success => SelectableText(
                      state.summaryText ?? '',
                      style: (wideLayout ? text.bodyMedium : text.bodyLarge)
                          ?.copyWith(color: colors.ink, height: 1.65),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryErrorView extends StatelessWidget {
  const _SummaryErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.inkMuted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.read<ItemDetailCubit>().summarizeStory(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry summary'),
            ),
          ],
        ),
      ),
    );
  }
}
