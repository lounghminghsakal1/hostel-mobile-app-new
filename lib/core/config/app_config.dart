/// App-wide constants. The API URL itself comes from `.env` (see `env.dart`).
abstract final class AppConfig {
  static const String appName = 'Our Hostel';

  /// Used when `.env` has no API_BASE_URL.
  static const String productionApiBaseUrl = 'https://api.ourhostel.in/api/v1/';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// The backend defaults to 10 per page; the app always asks for 20.
  static const int pageSize = 20;
}
