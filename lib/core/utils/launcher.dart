import 'package:url_launcher/url_launcher.dart';

abstract final class Launcher {
  static Future<bool> call(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return launchUrl(Uri(scheme: 'tel', path: digits));
  }

  static Future<bool> openLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return Future.value(false);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
