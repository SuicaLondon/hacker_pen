import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingPreferencesCubit extends Cubit<bool> {
  ReadingPreferencesCubit({
    Future<SharedPreferences>? preferences,
    Future<void> Function()? onChanged,
  }) : _preferences = preferences ?? SharedPreferences.getInstance(),
       _onChanged = onChanged,
       super(true);

  final Future<SharedPreferences> _preferences;
  final Future<void> Function()? _onChanged;
  static const _extendPageKey = 'reading.extend_page_behind_status_bar';

  Future<void> load() async {
    try {
      final preferences = await _preferences;
      await preferences.reload();
      if (!isClosed) emit(preferences.getBool(_extendPageKey) ?? true);
    } catch (_) {
      // Keep the default if local preferences are unavailable.
    }
  }

  Future<void> setExtendPageBehindStatusBar(bool enabled) async {
    final preferences = await _preferences;
    final saved = await preferences.setBool(_extendPageKey, enabled);
    if (!saved) throw StateError('Could not save reading preferences.');
    if (!isClosed) emit(enabled);
    await _onChanged?.call();
  }
}
