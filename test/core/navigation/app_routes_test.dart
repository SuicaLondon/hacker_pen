import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/navigation/app_routes.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/item_detail_page.dart';
import 'package:hacker_pen/src/features/item_detail/presentation/views/user_profile_page.dart';
import 'package:hacker_pen/src/features/items/presentation/views/items_page.dart';
import 'package:hacker_pen/src/features/reading/presentation/views/reading_workspace_page.dart';
import 'package:hacker_pen/src/features/settings/presentation/views/settings_page.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('phone home and unknown routes keep the original feed page', () {
    expect(
      _routeChild(const RouteSettings(name: AppRoutes.items)),
      isA<ItemsPage>(),
    );
    expect(
      _routeChild(const RouteSettings(name: '/missing')),
      isA<ItemsPage>(),
    );
  });

  test('phone story links keep the original detail page and requested ID', () {
    final page =
        _routeChild(
              const RouteSettings(name: AppRoutes.itemDetail, arguments: 42),
            )
            as ItemDetailPage;
    expect(page.itemId, 42);
  });

  test(
    'iPhone and Android routes do not depend on window orientation or size',
    () {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        debugDefaultTargetPlatformOverride = platform;
        // This context has no MediaQuery: route selection cannot use window size.
        expect(
          _routeChild(const RouteSettings(name: AppRoutes.items)),
          isA<ItemsPage>(),
        );
        expect(
          _routeChild(
            const RouteSettings(name: AppRoutes.itemDetail, arguments: 42),
          ),
          isA<ItemDetailPage>(),
        );
        expect(
          _routeChild(const RouteSettings(name: AppRoutes.settings)),
          isA<SettingsPage>(),
        );
        final profile =
            _routeChild(
                  const RouteSettings(
                    name: AppRoutes.userProfile,
                    arguments: 'pg',
                  ),
                )
                as UserProfilePage;
        expect(profile.userId, 'pg');
      }
    },
  );

  test('Mac always uses the workspace without querying window size', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(
      _routeChild(const RouteSettings(name: AppRoutes.items)),
      isA<ReadingWorkspacePage>(),
    );
    expect(
      _routeChild(const RouteSettings(name: '/missing'), useWorkspace: false),
      isA<ReadingWorkspacePage>(),
    );
    final page =
        _routeChild(
              const RouteSettings(name: AppRoutes.itemDetail, arguments: 42),
            )
            as ReadingWorkspacePage;
    expect(page.initialItemId, 42);
  });

  test('an explicitly identified iPad uses the responsive workspace', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      _routeChild(
        const RouteSettings(name: AppRoutes.items),
        useWorkspace: true,
      ),
      isA<ReadingWorkspacePage>(),
    );
    final page =
        _routeChild(
              const RouteSettings(name: AppRoutes.itemDetail, arguments: 42),
              useWorkspace: true,
            )
            as ReadingWorkspacePage;
    expect(page.initialItemId, 42);
  });

  test('named routes preserve their navigation identity and arguments', () {
    for (final useWorkspace in [false, true]) {
      for (final settings in [
        const RouteSettings(name: AppRoutes.items),
        const RouteSettings(name: AppRoutes.settings),
        const RouteSettings(name: AppRoutes.itemDetail, arguments: 42),
        const RouteSettings(name: AppRoutes.userProfile, arguments: 'pg'),
      ]) {
        expect(
          AppRoutes.onGenerateRoute(
            settings,
            useWorkspace: useWorkspace,
          ).settings,
          same(settings),
        );
      }
    }
  });
}

Widget _routeChild(RouteSettings settings, {bool? useWorkspace}) {
  final route =
      AppRoutes.onGenerateRoute(settings, useWorkspace: useWorkspace)
          as MaterialPageRoute<void>;
  return route.builder(MockBuildContext());
}

class MockBuildContext extends Fake implements BuildContext {}
