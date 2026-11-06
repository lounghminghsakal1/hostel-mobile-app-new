import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret, synchronous key/value storage (theme choice and similar).
/// Overridden in `main.dart` once the instance has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

abstract final class PrefKeys {
  static const palette = 'theme.palette';
}
