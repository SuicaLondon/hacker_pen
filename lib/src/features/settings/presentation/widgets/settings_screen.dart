import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

const settingsContentWidth = 720.0;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.title,
    required this.body,
    this.desktop = false,
    this.onClose,
  });

  final String title;
  final Widget body;
  final bool desktop;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (desktop) {
      return Material(
        color: context.hpColors.paper,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  HpIconButton(
                    tooltip: 'Close',
                    icon: Icons.close,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 52),
        child: HpTopBar(
          title: title,
          leading: HpIconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icons.chevron_left,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: settingsContentWidth),
            child: SizedBox.expand(child: body),
          ),
        ),
      ),
    );
  }
}
