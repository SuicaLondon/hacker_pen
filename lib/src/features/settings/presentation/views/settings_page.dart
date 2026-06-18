import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/ai/ai_language.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/ai/ai_settings.dart';
import '../../../../core/ai/ai_settings_repository.dart';
import '../../../../core/ai/ai_translation_mode.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.paddingOf(context).top + 48),
        child: HpTopBar(
          title: 'Settings',
          leading: HpIconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icons.arrow_back,
          ),
        ),
      ),
      body: const _AiSettingsForm(),
    );
  }
}

class _AiSettingsForm extends StatefulWidget {
  const _AiSettingsForm();

  @override
  State<_AiSettingsForm> createState() => _AiSettingsFormState();
}

class _AiSettingsFormState extends State<_AiSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();

  late Future<AiSettings> _settingsFuture;
  AiSettings? _settings;
  var _obscureApiKey = true;
  var _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return FutureBuilder<AiSettings>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || _settings == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error?.toString() ?? 'Failed to load settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.inkMuted),
              ),
            ),
          );
        }

        final settings = _settings!;
        final provider = AiProviders.definitionFor(settings.providerId);

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: [
              HpSettingsSection(
                title: 'AI Provider',
                children: [
                  DropdownButtonFormField<AiProviderId>(
                    initialValue: settings.providerId,
                    decoration: const InputDecoration(labelText: 'Provider'),
                    items: AiProviders.all
                        .map((provider) {
                          return DropdownMenuItem<AiProviderId>(
                            value: provider.id,
                            enabled: provider.isAvailable,
                            child: Text(
                              provider.isAvailable
                                  ? provider.label
                                  : '${provider.label} (Coming soon)',
                            ),
                          );
                        })
                        .toList(growable: false),
                    onChanged: _isSaving ? null : _handleProviderChanged,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('model-${settings.providerId.storageKey}'),
                    initialValue: settings.model,
                    decoration: const InputDecoration(labelText: 'Model'),
                    items: provider.models
                        .map((model) {
                          return DropdownMenuItem<String>(
                            value: model,
                            child: Text(model),
                          );
                        })
                        .toList(growable: false),
                    onChanged: _isSaving
                        ? null
                        : (model) {
                            if (model == null || model == settings.model) {
                              return;
                            }
                            setState(() {
                              _settings = settings.copyWith(model: model);
                              _statusMessage = null;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  _SettingsActionRow(
                    title: 'Target language',
                    value: settings.targetLanguage,
                    enabled: !_isSaving,
                    onTap: () => _selectLanguage(settings),
                  ),
                  const SizedBox(height: 12),
                  _SettingsActionRow(
                    title: 'Translation display',
                    value: settings.translationMode.label,
                    subtitle: settings.translationMode.description,
                    enabled: !_isSaving,
                    onTap: () => _selectTranslationMode(settings),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              HpSettingsSection(
                title: 'API Key',
                children: [
                  TextFormField(
                    controller: _apiKeyController,
                    enabled: !_isSaving,
                    obscureText: _obscureApiKey,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: settings.hasApiKey
                          ? 'Replace saved key'
                          : 'API key',
                      suffixIcon: IconButton(
                        tooltip: _obscureApiKey ? 'Show key' : 'Hide key',
                        onPressed: () {
                          setState(() => _obscureApiKey = !_obscureApiKey);
                        },
                        icon: Icon(
                          _obscureApiKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (!settings.hasApiKey &&
                          (value?.trim() ?? '').isEmpty) {
                        return 'API key is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _ApiKeyStatusBanner(
                    hasApiKey: settings.hasApiKey,
                    isSaving: _isSaving,
                    onClear: _clearApiKey,
                  ),
                ],
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 18),
                Text(
                  _statusMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<AiSettings> _loadSettings({AiProviderId? providerId}) async {
    final settings = await context.read<AiSettingsRepository>().load(
      providerId: providerId,
    );
    _applySettings(settings);
    return settings;
  }

  void _applySettings(AiSettings settings) {
    _settings = settings;
    _apiKeyController.clear();
  }

  void _handleProviderChanged(AiProviderId? providerId) {
    if (providerId == null || providerId == _settings?.providerId) return;

    setState(() {
      _statusMessage = null;
      _settingsFuture = _loadSettings(providerId: providerId);
    });
  }

  Future<void> _selectLanguage(AiSettings settings) async {
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Material(
          color: context.hpColors.paper,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: AiLanguage.common.length,
            separatorBuilder: (_, _) => const HpDivider(),
            itemBuilder: (context, index) {
              final language = AiLanguage.common[index];
              final isSelected = language == settings.targetLanguage;
              return ListTile(
                title: Text(language),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(language),
              );
            },
          ),
        );
      },
    );

    if (!mounted ||
        selectedLanguage == null ||
        selectedLanguage == settings.targetLanguage) {
      return;
    }

    setState(() {
      _settings = settings.copyWith(targetLanguage: selectedLanguage);
      _statusMessage = null;
    });
  }

  Future<void> _selectTranslationMode(AiSettings settings) async {
    final selectedMode = await showModalBottomSheet<AiTranslationMode>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Material(
          color: context.hpColors.paper,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: AiTranslationMode.values.length,
            separatorBuilder: (_, _) => const HpDivider(),
            itemBuilder: (context, index) {
              final mode = AiTranslationMode.values[index];
              final isSelected = mode == settings.translationMode;
              return ListTile(
                title: Text(mode.label),
                subtitle: Text(mode.description),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(mode),
              );
            },
          ),
        );
      },
    );

    if (!mounted ||
        selectedMode == null ||
        selectedMode == settings.translationMode) {
      return;
    }

    setState(() {
      _settings = settings.copyWith(translationMode: selectedMode);
      _statusMessage = null;
    });
  }

  Future<void> _saveSettings() async {
    final current = _settings;
    if (current == null || _formKey.currentState?.validate() != true) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    final provider = AiProviders.definitionFor(current.providerId);
    final settings = current.copyWith(baseUrl: provider.defaultBaseUrl);
    final repository = context.read<AiSettingsRepository>();

    try {
      await repository.save(
        settings,
        apiKeyReplacement: _apiKeyController.text,
      );
      final reloaded = await repository.load(providerId: settings.providerId);
      if (!mounted) return;
      setState(() {
        _applySettings(reloaded);
        _isSaving = false;
        _statusMessage = 'Saved.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _statusMessage = error.toString();
      });
    }
  }

  Future<void> _clearApiKey() async {
    final current = _settings;
    if (current == null) return;

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });
    final repository = context.read<AiSettingsRepository>();

    try {
      await repository.clearApiKey(current.providerId);
      final reloaded = await repository.load(providerId: current.providerId);
      if (!mounted) return;
      setState(() {
        _applySettings(reloaded);
        _isSaving = false;
        _statusMessage = 'Key cleared.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _statusMessage = error.toString();
      });
    }
  }
}

class _ApiKeyStatusBanner extends StatelessWidget {
  const _ApiKeyStatusBanner({
    required this.hasApiKey,
    required this.isSaving,
    required this.onClear,
  });

  final bool hasApiKey;
  final bool isSaving;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;
    final activeColor = colors.brand;
    final statusColor = hasApiKey ? activeColor : colors.inkMuted;
    final backgroundColor = hasApiKey
        ? activeColor.withValues(alpha: 0.1)
        : colors.surfaceMuted.withValues(alpha: 0.58);
    final borderColor = hasApiKey
        ? activeColor.withValues(alpha: 0.64)
        : colors.rule;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: context.hpRadii.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: hasApiKey ? activeColor : Colors.transparent,
                border: Border.all(color: statusColor),
                borderRadius: context.hpRadii.small,
              ),
              child: SizedBox.square(
                dimension: 24,
                child: Icon(
                  hasApiKey ? Icons.lock_outline : Icons.lock_open_outlined,
                  size: 16,
                  color: hasApiKey ? colors.surface : statusColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasApiKey ? 'API key saved' : 'No API key saved',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: hasApiKey ? activeColor : colors.inkMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasApiKey
                        ? 'This provider already has an API key.'
                        : 'Add a key to enable AI actions.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
            if (hasApiKey) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: isSaving ? null : onClear,
                child: const Text('Clear'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.hpColors;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: context.hpRadii.medium,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.rule),
          borderRadius: context.hpRadii.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: enabled ? colors.ink : colors.inkSubtle,
                      ),
                    ),
                    if (subtitle case final subtitle?) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
