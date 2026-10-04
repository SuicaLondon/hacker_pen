import '../widgets/settings_choices.dart';
import '../widgets/settings_screen.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_cell.dart';
import '../../../../core/utils/mask_api_key.dart';
import 'api_keys_page.dart';
import 'api_key_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/settings/reading_preferences_cubit.dart';
import '../../../../core/ai/ai_language.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/ai/ai_settings.dart';
import '../../../../core/ai/ai_settings_repository.dart';
import '../../../../core/ai/ai_translation_mode.dart';
import 'privacy_policy_page.dart';

enum _SettingsCategory { ai, translation, privacy }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.desktop = false});

  final bool desktop;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<AiSettings> _initialSettings;
  AiSettings? _settings;
  List<AiProviderDefinition> _providers = [];
  bool _isSaving = false;
  bool _isSavingReading = false;
  int _keyCount = 0;
  Map<AiProviderId, String?> _maskedKeys = {};
  _SettingsCategory _category = _SettingsCategory.ai;

  @override
  void initState() {
    super.initState();
    _initialSettings = _loadSettings();
  }

  Future<AiSettings> _loadSettings() async {
    final repository = context.read<AiSettingsRepository>();
    _providers = await repository.loadProviders();
    final keys = await Future.wait(
      _providers.map(
        (provider) async => MapEntry(
          provider.id,
          maskApiKey(await repository.readApiKey(provider.id)),
        ),
      ),
    );
    _maskedKeys = Map.fromEntries(keys);
    _keyCount = _maskedKeys.values.whereType<String>().length;
    return repository.load();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.desktop) return _buildDesktop(context);
    return SettingsScreen(
      title: 'Settings',
      body: FutureBuilder<AiSettings>(
        future: _initialSettings,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const HpLoadingView(label: 'Loading settings');
          }
          final settings = _settings ?? snapshot.data;
          if (settings == null) {
            return Center(child: Text('Failed to load settings.'));
          }
          final provider = _providers.firstWhere(
            (provider) => provider.id == settings.providerId,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
            children: [
              SettingsGroup(
                title: 'AI',
                children: [
                  SettingsCell(
                    title: 'Providers & keys',
                    value: _keyCount == 0
                        ? 'No keys added'
                        : '$_keyCount ${_keyCount == 1 ? 'key saved' : 'keys saved'}',
                    onTap: _isSaving ? null : () => _editApiKey(settings),
                  ),
                  SettingsCell(
                    title: 'Active model',
                    value: settings.hasApiKey && settings.model.isNotEmpty
                        ? '${provider.label} · ${settings.model}'
                        : 'Not selected',
                    onTap: _isSaving ? null : () => _selectModel(settings),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: SettingsGroup(
                  title: 'Translation',
                  children: [
                    SettingsCell(
                      title: 'Language',
                      value: settings.targetLanguage,
                      onTap: _isSaving
                          ? null
                          : () async {
                              final language = await _choose(
                                title: 'Language',
                                selected: settings.targetLanguage,
                                values: AiLanguage.common,
                                label: (language) => language,
                              );
                              if (language != null &&
                                  language != settings.targetLanguage) {
                                await _save(
                                  settings.copyWith(targetLanguage: language),
                                );
                              }
                            },
                    ),
                    SettingsCell(
                      title: 'Display',
                      value: settings.translationMode.label,
                      onTap: _isSaving
                          ? null
                          : () async {
                              final mode = await _choose(
                                title: 'Translation display',
                                selected: settings.translationMode,
                                values: AiTranslationMode.values,
                                label: (mode) => mode.label,
                                description: (mode) => mode.description,
                              );
                              if (mode != null &&
                                  mode != settings.translationMode) {
                                await _save(
                                  settings.copyWith(translationMode: mode),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: SettingsGroup(
                  title: 'Reading',
                  children: [
                    BlocBuilder<ReadingPreferencesCubit, bool>(
                      builder: (context, enabled) => SwitchListTile.adaptive(
                        title: const Text('Extend page to top'),
                        subtitle: const Text(
                          'Show web content behind the status bar when the header hides.',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        activeTrackColor: context.hpColors.brand,
                        value: enabled,
                        onChanged: _isSavingReading
                            ? null
                            : _saveReadingPreference,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: SettingsGroup(
                  title: 'Privacy',
                  children: [
                    SettingsCell(
                      title: 'Privacy Policy',
                      value: 'Local storage and third-party services',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  _isSaving ? 'Saving…' : 'Changes are saved automatically.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.hpColors.inkMuted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final colors = context.hpColors;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 176,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(right: BorderSide(color: colors.rule)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    child: Text('Settings', style: text.titleMedium),
                  ),
                  for (final category in _SettingsCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        key: ValueKey('settings-category-${category.name}'),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        minLeadingWidth: 20,
                        horizontalTitleGap: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        selected: _category == category,
                        selectedTileColor: colors.brand.withValues(alpha: 0.12),
                        selectedColor: colors.brand,
                        leading: Icon(switch (category) {
                          _SettingsCategory.ai => Icons.auto_awesome_outlined,
                          _SettingsCategory.translation => Icons.translate,
                          _SettingsCategory.privacy => Icons.shield_outlined,
                        }, size: 18),
                        title: Text(_categoryTitle(category)),
                        onTap: () => setState(() => _category = category),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      _categoryTitle(_category),
                      style: text.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: _category == _SettingsCategory.privacy
                        ? const PrivacyPolicyBody()
                        : FutureBuilder<AiSettings>(
                            future: _initialSettings,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const HpLoadingView(
                                  label: 'Loading settings',
                                );
                              }
                              final settings = _settings ?? snapshot.data;
                              if (settings == null) {
                                return const Center(
                                  child: Text('Failed to load settings.'),
                                );
                              }
                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  24,
                                ),
                                children: [
                                  if (_category == _SettingsCategory.ai)
                                    ..._desktopAiControls(settings)
                                  else
                                    ..._desktopTranslationControls(settings),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: Text(
                                      _isSaving
                                          ? 'Saving…'
                                          : 'Changes are saved automatically.',
                                      style: text.bodySmall?.copyWith(
                                        color: colors.inkMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _desktopAiControls(AiSettings settings) {
    final provider = _providers.firstWhere(
      (provider) => provider.id == settings.providerId,
      orElse: () => AiProviders.definitionFor(settings.providerId),
    );
    return [
      Text('Active model', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 10),
      Row(
        spacing: 12,
        children: [
          Expanded(
            child: Text(
              settings.hasApiKey && settings.model.isNotEmpty
                  ? '${provider.label} · ${settings.model}'
                  : 'Not selected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          OutlinedButton(
            onPressed: _isSaving ? null : () => _selectModel(settings),
            child: const Text('Choose model…'),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: HpDivider(),
      ),
      Text('Providers & keys', style: Theme.of(context).textTheme.titleSmall),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Text(
          'One API key per provider. Keys are stored locally.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.hpColors.inkMuted),
        ),
      ),
      for (final provider in _providers)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(provider.label),
                    Text(
                      _maskedKeys[provider.id] ?? 'No key saved',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.hpColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                key: ValueKey('settings-key-${provider.id.storageKey}'),
                onPressed: _isSaving ? null : () => _editDesktopKey(provider),
                child: Text(
                  _maskedKeys[provider.id] == null ? 'Add key…' : 'Edit key…',
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _desktopTranslationControls(AiSettings settings) => [
    DropdownButtonFormField<String>(
      key: ValueKey('settings-language-${settings.targetLanguage}'),
      initialValue: settings.targetLanguage,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Language'),
      items: [
        for (final language in AiLanguage.common)
          DropdownMenuItem(value: language, child: Text(language)),
      ],
      onChanged: _isSaving
          ? null
          : (language) {
              if (language != null && language != settings.targetLanguage) {
                _save(settings.copyWith(targetLanguage: language));
              }
            },
    ),
    const SizedBox(height: 24),
    DropdownButtonFormField<AiTranslationMode>(
      key: ValueKey('settings-display-${settings.translationMode.name}'),
      initialValue: settings.translationMode,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Translation display'),
      items: [
        for (final mode in AiTranslationMode.values)
          DropdownMenuItem(value: mode, child: Text(mode.label)),
      ],
      onChanged: _isSaving
          ? null
          : (mode) {
              if (mode != null && mode != settings.translationMode) {
                _save(settings.copyWith(translationMode: mode));
              }
            },
    ),
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        settings.translationMode.description,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.hpColors.inkMuted),
      ),
    ),
  ];

  Future<void> _editDesktopKey(AiProviderDefinition provider) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ApiKeyPage(
        provider: provider,
        maskedKey: _maskedKeys[provider.id],
        repository: context.read<AiSettingsRepository>(),
        desktop: true,
      ),
    );
    try {
      final updated = await _loadSettings();
      if (mounted) setState(() => _settings = updated);
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  static String _categoryTitle(_SettingsCategory category) =>
      switch (category) {
        _SettingsCategory.ai => 'AI',
        _SettingsCategory.translation => 'Translation',
        _SettingsCategory.privacy => 'Privacy',
      };

  Future<void> _saveReadingPreference(bool enabled) async {
    setState(() => _isSavingReading = true);
    try {
      await context
          .read<ReadingPreferencesCubit>()
          .setExtendPageBehindStatusBar(enabled);
    } catch (_) {
      if (mounted) _showSaveError();
    } finally {
      if (mounted) setState(() => _isSavingReading = false);
    }
  }

  Future<T?> _choose<T>({
    required String title,
    required T selected,
    required List<T> values,
    required String Function(T) label,
    String Function(T)? description,
    bool Function(T)? enabled,
    Future<List<T>> Function()? loadValues,
  }) {
    if (widget.desktop) {
      return showDialog<T>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.hpColors.paper,
          title: Text(title),
          contentPadding: const EdgeInsets.fromLTRB(6, 20, 6, 0),
          content: SizedBox(
            width: 440,
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: SettingsChoices<T>(
              values: values,
              selected: selected,
              label: label,
              description: description,
              enabled: enabled,
              loadValues: loadValues,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.hpColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(
        maxWidth: settingsContentWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  HpIconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icons.close,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SettingsChoices<T>(
                values: values,
                selected: selected,
                label: label,
                description: description,
                enabled: enabled,
                loadValues: loadValues,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectModel(AiSettings settings) async {
    final repository = context.read<AiSettingsRepository>();
    setState(() => _isSaving = true);
    try {
      final providers = await repository.loadProviders();
      final configured = <AiProviderDefinition>[];
      for (final provider in providers) {
        if ((await repository.readApiKey(provider.id))?.isNotEmpty == true) {
          configured.add(provider);
        }
      }
      if (!mounted) return;
      if (configured.isEmpty) {
        await _editApiKey(settings);
        return;
      }
      final selected = await _choose<AiProviderId>(
        title: 'Choose provider',
        selected: settings.providerId,
        values: configured.map((provider) => provider.id).toList(),
        label: (id) =>
            configured.firstWhere((provider) => provider.id == id).label,
        description: (_) => 'API key saved',
      );
      if (!mounted || selected == null) return;
      final next = await repository.load(providerId: selected);
      if (!mounted) return;
      final model = await _choose<String>(
        title: 'Choose model',
        selected: next.model,
        values: const [],
        loadValues: () => repository.loadModels(selected),
        label: (model) => model,
      );
      if (!mounted || model == null) return;
      _providers = providers;
      await _save(
        next.copyWith(
          model: model,
          targetLanguage: settings.targetLanguage,
          translationMode: settings.translationMode,
        ),
      );
    } catch (_) {
      if (mounted) _showSaveError();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save(AiSettings settings) async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      await context.read<AiSettingsRepository>().save(settings);
      if (mounted) setState(() => _settings = settings);
    } catch (_) {
      if (mounted) _showSaveError();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not save changes. Please try again.'),
      ),
    );
  }

  Future<void> _editApiKey(AiSettings settings) async {
    if (widget.desktop) {
      final selected = await _choose<AiProviderId>(
        title: 'Choose key provider',
        selected: settings.providerId,
        values: _providers.map((provider) => provider.id).toList(),
        label: (id) =>
            _providers.firstWhere((provider) => provider.id == id).label,
      );
      if (mounted && selected != null) {
        await _editDesktopKey(
          _providers.firstWhere((provider) => provider.id == selected),
        );
      }
      return;
    }
    final repository = context.read<AiSettingsRepository>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ApiKeysPage(
          activeProvider: settings.hasApiKey && settings.model.isNotEmpty
              ? settings.providerId
              : null,
          repository: repository,
        ),
      ),
    );
    try {
      final updated = await _loadSettings();
      if (mounted) setState(() => _settings = updated);
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }
}
