import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_config.dart';

/// Settings read from the `.env` file bundled with the app.
///
/// `.env` keeps environment-specific values out of the code and out of git,
/// but it is not secret: it ships inside the app and anyone can unpack it.
/// Only put non-secret settings here (the API URL is visible in every
/// request anyway). Never put API keys or passwords in a mobile app.
abstract final class Env {
  static Future<void> load() => dotenv.load(fileName: '.env', isOptional: true);

  /// `--dart-define=API_BASE_URL=…` wins, then `.env`, then production.
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromFile = dotenv.isInitialized ? dotenv.maybeGet('API_BASE_URL')?.trim() : null;
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return AppConfig.productionApiBaseUrl;
  }
}
