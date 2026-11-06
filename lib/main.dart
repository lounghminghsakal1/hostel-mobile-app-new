import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/network/base_url.dart';
import 'core/storage/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final preferences = await SharedPreferences.getInstance();
  final baseUrl = resolveBaseUrl(Env.apiBaseUrl, isAndroidEmulator: await isAndroidEmulator());
  if (kDebugMode) debugPrint('API base URL: $baseUrl');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        apiBaseUrlProvider.overrideWithValue(baseUrl),
      ],
      child: const HostelApp(),
    ),
  );
}
