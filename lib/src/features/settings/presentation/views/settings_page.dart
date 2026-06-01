import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ai/ai_language.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/ai/ai_settings.dart';
import '../../../../core/ai/ai_settings_repository.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings')),
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
    final colorScheme = Theme.of(context).colorScheme;

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
                style: TextStyle(color: colorScheme.onSurfaceVariant),
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
              Text(
                'AI Provider',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 14),
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
                        if (model == null || model == settings.model) return;
                        setState(() {
                          _settings = settings.copyWith(model: model);
                          _statusMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !_isSaving,
                title: const Text('Target language'),
                subtitle: Text(settings.targetLanguage),
                trailing: const Icon(Icons.expand_more),
                onTap: _isSaving ? null : () => _selectLanguage(settings),
              ),
              const SizedBox(height: 26),
              Text(
                'API Key',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
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
                  if (!settings.hasApiKey && (value?.trim() ?? '').isEmpty) {
                    return 'API key is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    settings.hasApiKey
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                    size: 17,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      settings.hasApiKey
                          ? 'Saved in secure storage.'
                          : 'No key saved.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (settings.hasApiKey)
                    TextButton(
                      onPressed: _isSaving ? null : _clearApiKey,
                      child: const Text('Clear'),
                    ),
                ],
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 18),
                Text(
                  _statusMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
        return ListView.separated(
          shrinkWrap: true,
          itemCount: AiLanguage.common.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final language = AiLanguage.common[index];
            final isSelected = language == settings.targetLanguage;
            return ListTile(
              title: Text(language),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(language),
            );
          },
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
