import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/ai/ai_exception.dart';

import 'settings_group.dart';

class SettingsChoices<T> extends StatefulWidget {
  const SettingsChoices({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    this.description,
    this.enabled,
    this.loadValues,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final String Function(T)? description;
  final bool Function(T)? enabled;
  final Future<List<T>> Function()? loadValues;

  @override
  State<SettingsChoices<T>> createState() => _SettingsChoicesState<T>();
}

class _SettingsChoicesState<T> extends State<SettingsChoices<T>> {
  Future<List<T>>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadValues?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _future,
      initialData: widget.loadValues == null ? widget.values : null,
      builder: (context, snapshot) {
        if (_future != null &&
            snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: SizedBox(
              height: 80,
              child: HpLoadingView(label: 'Loading models'),
            ),
          );
        }
        final values = snapshot.data ?? <T>[];
        if (snapshot.hasError || values.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                Text(
                  snapshot.hasError
                      ? (snapshot.error is AiException
                            ? (snapshot.error as AiException).message
                            : 'Could not load models. Check your connection and try again.')
                      : 'No recommended lightweight models are available for this key.',
                  textAlign: TextAlign.center,
                ),
                if (widget.loadValues != null)
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _future = widget.loadValues!();
                    }),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          );
        }
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            if (widget.loadValues != null &&
                widget.label(widget.selected).isNotEmpty &&
                !values.contains(widget.selected))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Current model: ${widget.label(widget.selected)}. '
                  'Outside the recommended list. Your selection is unchanged.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            SettingsGroup(
              children: [
                for (final value in values)
                  ListTile(
                    title: Text(widget.label(value)),
                    subtitle: widget.description == null
                        ? null
                        : Text(widget.description!(value)),
                    enabled: widget.enabled?.call(value) ?? true,
                    trailing: value == widget.selected
                        ? Icon(Icons.check, color: context.hpColors.brand)
                        : null,
                    selected: value == widget.selected,
                    onTap: () => Navigator.of(context).pop(value),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
