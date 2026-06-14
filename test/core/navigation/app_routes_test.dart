import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/navigation/app_routes.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/item_detail_page.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/user_profile_page.dart';
import 'package:hacker_pen/src/features/items/presentation/views/items_page.dart';
import 'package:hacker_pen/src/features/settings/presentation/views/settings_page.dart';

void main() {
  test('generates routes for app screens', () {
    expect(
      _routeChild(const RouteSettings(name: AppRoutes.items)),
      isA<ItemsPage>(),
    );
    expect(
      _routeChild(const RouteSettings(name: AppRoutes.settings)),
      isA<SettingsPage>(),
    );
    expect(
      _routeChild(
        const RouteSettings(name: AppRoutes.itemDetail, arguments: 1),
      ),
      isA<ItemDetailPage>(),
    );
    expect(
      _routeChild(
        const RouteSettings(name: AppRoutes.userProfile, arguments: 'pg'),
      ),
      isA<UserProfilePage>(),
    );
    expect(
      _routeChild(const RouteSettings(name: '/missing')),
      isA<ItemsPage>(),
    );
  });
}

Widget _routeChild(RouteSettings settings) {
  final route = AppRoutes.onGenerateRoute(settings) as MaterialPageRoute<void>;
  return route.builder(MockBuildContext());
}

class MockBuildContext extends Fake implements BuildContext {}
