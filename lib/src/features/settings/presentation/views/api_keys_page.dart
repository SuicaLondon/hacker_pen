import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/ai/ai_settings_repository.dart';

import '../widgets/settings_screen.dart';
import '../widgets/settings_group.dart';
import '../../../../core/utils/mask_api_key.dart';
import 'api_key_page.dart';

class ApiKeysPage extends StatefulWidget {
  const ApiKeysPage({
    super.key,
    required this.activeProvider,
    required this.repository,
  });

  final AiProviderId? activeProvider;
  final AiSettingsRepository repository;

  @override
  State<ApiKeysPage> createState() => _ApiKeysPageState();
}

class _ApiKeysPageState extends State<ApiKeysPage> {
  late Future<Map<AiProviderId, String?>> _keys;

  @override
  void initState() {
    super.initState();
    _keys = _loadKeys();
  }

  Future<Map<AiProviderId, String?>> _loadKeys() async {
    final entries = await Future.wait(
      AiProviders.available.map((provider) async {
        final key = await widget.repository.readApiKey(provider.id);
        // Keep only a masked identifier in presentation state.
        return MapEntry(provider.id, maskApiKey(key));
      }),
    );
    return Map.fromEntries(entries);
  }

  Future<void> _edit(AiProviderDefinition provider, String? maskedKey) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ApiKeyPage(
          provider: provider,
          maskedKey: maskedKey,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted && changed != null) {
      setState(() {
        _keys = _loadKeys();
      });
    }
  }

  Future<void> _addKey(Map<AiProviderId, String?> keys) async {
    final provider = await showModalBottomSheet<AiProviderDefinition>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.hpColors.paper,
      constraints: const BoxConstraints(maxWidth: settingsContentWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose key provider',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final provider in AiProviders.available.where(
              (provider) => keys[provider.id] == null,
            ))
              ListTile(
                title: Text(provider.label),
                subtitle: const Text('Add API key'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(provider),
              ),
          ],
        ),
      ),
    );
    if (mounted && provider != null) await _edit(provider, keys[provider.id]);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: 'Providers & keys',
      body: FutureBuilder<Map<AiProviderId, String?>>(
        future: _keys,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const HpLoadingView(label: 'Loading saved keys');
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  const Text('Could not load saved keys.'),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _keys = _loadKeys();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final keys = snapshot.data!;
          final count = keys.values.whereType<String>().length;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      '$count ${count == 1 ? 'saved key' : 'saved keys'}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'One API key per provider. Select a saved key to replace or remove it.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.hpColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (count < AiProviders.available.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: FilledButton.icon(
                    onPressed: () => _addKey(keys),
                    icon: const Icon(Icons.add),
                    label: const Text('Add API key'),
                  ),
                ),
              for (final provider in AiProviders.available.where(
                (provider) => keys[provider.id] != null,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SettingsGroup(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: Icon(
                          keys[provider.id] != null
                              ? Icons.check_circle
                              : Icons.key_outlined,
                          color: keys[provider.id] != null
                              ? context.hpColors.brand
                              : context.hpColors.inkMuted,
                        ),
                        title: Text(provider.label),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 6,
                            children: [
                              Text(
                                keys[provider.id] != null
                                    ? 'Saved · ${keys[provider.id]}'
                                    : 'Not configured',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: context.hpColors.ink,
                                    ),
                              ),
                              if (provider.id == widget.activeProvider)
                                const Text('Selected provider'),
                              if (!provider.isAvailable)
                                const Text('Provider support coming soon'),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _edit(provider, keys[provider.id]),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
