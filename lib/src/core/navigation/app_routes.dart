import 'package:flutter/material.dart';

import '../../features/item_detail/presentation/views/item_detail_page.dart';
import '../../features/item_detail/presentation/views/user_profile_page.dart';
import '../../features/items/presentation/views/items_page.dart';
import '../../features/settings/presentation/views/settings_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String items = '/';
  static const String settings = '/settings';
  static const String itemDetail = '/item-detail';
  static const String userProfile = '/user-profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case items:
        return MaterialPageRoute<void>(
          builder: (_) => const ItemsPage(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );
      case itemDetail:
        final itemId = settings.arguments as int;
        return MaterialPageRoute<void>(
          builder: (_) => ItemDetailPage(itemId: itemId),
          settings: settings,
        );
      case userProfile:
        final userId = settings.arguments as String;
        return MaterialPageRoute<void>(
          builder: (_) => UserProfilePage(userId: userId),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const ItemsPage(),
          settings: settings,
        );
    }
  }
}
