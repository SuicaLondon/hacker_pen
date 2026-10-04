import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/item_detail/presentation/views/item_detail_page.dart';
import '../../features/item_detail/presentation/views/user_profile_page.dart';
import '../../features/items/presentation/views/items_page.dart';
import '../../features/reading/presentation/views/reading_workspace_page.dart';
import '../../features/settings/presentation/views/settings_page.dart';
import '../design_system/design_system.dart';

class AppRoutes {
  const AppRoutes._();

  static const String items = '/';
  static const String settings = '/settings';
  static const String itemDetail = '/item-detail';
  static const String userProfile = '/user-profile';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    bool? useWorkspace,
  }) {
    final workspace =
        defaultTargetPlatform == TargetPlatform.macOS || useWorkspace == true;
    switch (settings.name) {
      case items:
        return MaterialPageRoute<void>(
          builder: (_) =>
              workspace ? const ReadingWorkspacePage() : const ItemsPage(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          builder: (_) => workspace
              ? const _SecondaryPage(child: SettingsPage())
              : const SettingsPage(),
          settings: settings,
        );
      case itemDetail:
        final itemId = settings.arguments as int;
        return MaterialPageRoute<void>(
          builder: (_) => workspace
              ? ReadingWorkspacePage(initialItemId: itemId)
              : ItemDetailPage(itemId: itemId),
          settings: settings,
        );
      case userProfile:
        final userId = settings.arguments as String;
        return MaterialPageRoute<void>(
          builder: (_) => workspace
              ? _SecondaryPage(child: UserProfilePage(userId: userId))
              : UserProfilePage(userId: userId),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) =>
              workspace ? const ReadingWorkspacePage() : const ItemsPage(),
          settings: settings,
        );
    }
  }
}

/// Keeps secondary screens readable and keyboard-accessible on large windows.
class _SecondaryPage extends StatelessWidget {
  const _SecondaryPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true): () =>
            Navigator.of(context).maybePop(),
        const SingleActivator(
          LogicalKeyboardKey.bracketLeft,
          control: true,
        ): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: context.hpColors.paper,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
