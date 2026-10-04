import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/domain/hn_item.dart';
import '../../../../core/utils/text_sanitizer.dart';

class SelfPostBody extends StatelessWidget {
  const SelfPostBody({super.key, required this.story});

  final HnItem story;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final bodyText = TextSanitizer.stripHtml(story.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.42),
            border: Border(
              left: BorderSide(color: colors.brand, width: 2),
              top: BorderSide(color: colors.rule),
              right: BorderSide(color: colors.rule),
              bottom: BorderSide(color: colors.rule),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
            child: SelectableText(
              bodyText.isEmpty ? 'No story text available.' : bodyText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: bodyText.isEmpty ? colors.inkMuted : colors.ink,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UnsupportedWebViewBody extends StatelessWidget {
  const UnsupportedWebViewBody({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SelectableText(
          url,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.brand,
            fontFamily: context.hpText.monoFamily,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
