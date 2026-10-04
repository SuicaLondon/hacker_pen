import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_pen/src/core/ai/ai_provider.dart';
import 'package:hacker_pen/src/core/ai/ai_settings.dart';
import 'package:hacker_pen/src/core/ai/ai_settings_repository.dart';
import 'package:hacker_pen/src/core/ai/ai_translation_mode.dart';
import 'package:hacker_pen/src/core/design_system/design_system.dart';
import 'package:hacker_pen/src/features/settings/presentation/views/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openSettings(
    WidgetTester tester,
    _SettingsRepository repository,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepositoryProvider<AiSettingsRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: HpTheme.dark(),
          home: const SettingsPage(desktop: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desktop translation choices save inline within the window', (
    tester,
  ) async {
    final repository = _SettingsRepository();
    await openSettings(tester, repository);

    expect(find.byTooltip('Back'), findsNothing);
    expect(find.text('Extend page to top'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('settings-category-translation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japanese').last);
    await tester.pumpAndSettle();

    expect(repository.settings.targetLanguage, 'Japanese');
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<AiTranslationMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AiTranslationMode.paragraphPairs.label).last);
    await tester.pumpAndSettle();
    expect(
      repository.settings.translationMode,
      AiTranslationMode.paragraphPairs,
    );
    expect(find.byTooltip('Back'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop keys are added and removed in a centered dialog', (
    tester,
  ) async {
    final repository = _SettingsRepository();
    await openSettings(tester, repository);
    final keyButton = find.byKey(
      const ValueKey('settings-key-openai_compatible'),
    );
    await tester.tap(keyButton);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('OpenAI API key'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'desktop-secret-key');
    await tester.ensureVisible(find.text('Save API key'));
    await tester.tap(find.text('Save API key'));
    await tester.pumpAndSettle();

    expect(
      repository.keys[AiProviderId.openAiCompatible],
      'desktop-secret-key',
    );
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('•••• -key'), findsOneWidget);
    expect(find.text('desktop-secret-key'), findsNothing);
    await tester.tap(keyButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Replace API key'));
    await tester.tap(find.text('Replace API key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'replacement-secret');
    await tester.ensureVisible(find.text('Replace API key'));
    await tester.tap(find.text('Replace API key'));
    await tester.pumpAndSettle();

    expect(
      repository.keys[AiProviderId.openAiCompatible],
      'replacement-secret',
    );
    expect(find.text('•••• cret'), findsOneWidget);
    await tester.tap(keyButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Remove API key'));
    await tester.tap(find.text('Remove API key'));
    await tester.pumpAndSettle();

    expect(repository.keys[AiProviderId.openAiCompatible], isNull);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('•••• -key'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop model choices remain inside Settings dialogs', (
    tester,
  ) async {
    final repository = _SettingsRepository()
      ..keys[AiProviderId.openAiCompatible] = 'provider-key';
    await openSettings(tester, repository);
    await tester.tap(find.text('Choose model…'));
    await tester.pumpAndSettle();
    expect(find.text('Choose provider'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'OpenAI'));
    await tester.pumpAndSettle();
    expect(find.text('Choose model'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'test-model'));
    await tester.pumpAndSettle();

    expect(repository.settings.model, 'test-model');
    expect(find.text('OpenAI · test-model'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('privacy stays in the selected Settings category', (
    tester,
  ) async {
    await openSettings(tester, _SettingsRepository());
    await tester.tap(find.byKey(const ValueKey('settings-category-privacy')));
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-category-ai')));
    await tester.pumpAndSettle();
    expect(find.text('Providers & keys'), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Settings remains usable at the native minimum window size', (
    tester,
  ) async {
    await openSettings(tester, _SettingsRepository());
    tester.view.physicalSize = const Size(640, 480);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('settings-key-openai_compatible')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-category-translation')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SettingsRepository extends AiSettingsRepository {
  AiSettings settings = AiSettings.defaultsFor(AiProviderId.openAiCompatible);
  final keys = <AiProviderId, String>{};

  @override
  Future<AiSettings> load({AiProviderId? providerId}) async =>
      settings.copyWith(
        providerId: providerId,
        hasApiKey: keys[providerId ?? settings.providerId]?.isNotEmpty == true,
      );

  @override
  Future<void> save(AiSettings next, {String? apiKeyReplacement}) async {
    settings = next;
  }

  @override
  Future<String?> readApiKey(AiProviderId providerId) async => keys[providerId];

  @override
  Future<void> saveApiKey(AiProviderId providerId, String apiKey) async {
    keys[providerId] = apiKey.trim();
  }

  @override
  Future<void> clearApiKey(AiProviderId providerId) async {
    keys.remove(providerId);
  }

  @override
  Future<List<String>> loadModels(AiProviderId providerId) async => [
    'test-model',
  ];
}
