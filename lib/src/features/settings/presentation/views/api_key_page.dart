import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/ai/ai_settings_repository.dart';

import '../widgets/settings_screen.dart';
import '../widgets/settings_group.dart';

class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({
    super.key,
    required this.provider,
    required this.maskedKey,
    required this.repository,
    this.desktop = false,
  });

  final AiProviderDefinition provider;
  final String? maskedKey;
  final AiSettingsRepository repository;
  final bool desktop;

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save({bool remove = false}) async {
    if (_isSaving) return;
    if (!remove && _formKey.currentState?.validate() != true) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (remove) {
        await widget.repository.clearApiKey(widget.provider.id);
      } else {
        await widget.repository.saveApiKey(
          widget.provider.id,
          _controller.text,
        );
      }
      if (!mounted) return;
      setState(() => _isSaving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop(!remove);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save changes. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = PopScope(
      canPop: !_isSaving,
      child: SettingsScreen(
        title: widget.desktop ? '${widget.provider.label} API key' : 'API key',
        desktop: widget.desktop,
        onClose: _isSaving ? null : () => Navigator.of(context).pop(),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              SettingsGroup(
                title: 'Current key',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Icon(
                          (widget.maskedKey != null)
                              ? Icons.lock_outline
                              : Icons.key_outlined,
                          color: context.hpColors.brand,
                          size: 28,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Text(
                                (widget.maskedKey != null)
                                    ? 'API key saved'
                                    : 'No API key saved',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (widget.maskedKey != null)
                                Text(
                                  widget.maskedKey!,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              Text(
                                widget.provider.label,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                (widget.maskedKey != null)
                                    ? 'This key is saved and will be used when this provider is selected.'
                                    : 'Add a key to load models and use summaries and translation.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.hpColors.inkMuted,
                                      height: 1.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.maskedKey != null && !_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Replace API key'),
                  ),
                ),
              if (widget.maskedKey == null || _isEditing) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: TextFormField(
                    controller: _controller,
                    enabled: !_isSaving,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      labelText: (widget.maskedKey != null)
                          ? 'Replace saved key'
                          : 'API key',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show key' : 'Hide key',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'API key is required.'
                        : null,
                  ),
                ),
                FilledButton(
                  onPressed: _isSaving ? null : () => _save(),
                  child: Text(
                    _isSaving
                        ? 'Saving…'
                        : (widget.maskedKey != null)
                        ? 'Replace API key'
                        : 'Save API key',
                  ),
                ),
                if (widget.maskedKey != null)
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() {
                            _isEditing = false;
                            _controller.clear();
                            _error = null;
                          }),
                    child: const Text('Cancel replacement'),
                  ),
              ],
              if (widget.maskedKey != null)
                TextButton(
                  onPressed: _isSaving ? null : () => _save(remove: true),
                  child: const Text('Remove API key'),
                ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
    );
    if (!widget.desktop) return screen;
    return Dialog(
      backgroundColor: context.hpColors.paper,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 520,
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: screen,
      ),
    );
  }
}
