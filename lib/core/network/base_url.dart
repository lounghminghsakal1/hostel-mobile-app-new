import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The API base URL the app talks to. Overridden in `main.dart` once `.env`
/// has loaded and the device is known.
final apiBaseUrlProvider = Provider<String>(
  (ref) => throw UnimplementedError('apiBaseUrlProvider must be overridden in main()'),
);

/// Makes a configured URL usable on this device:
/// * adds the trailing slash Dio needs to join paths;
/// * on the Android emulator, `localhost` / `127.0.0.1` mean the emulator
///   itself, so they are swapped for `10.0.2.2`, the emulator's alias for
///   the computer it runs on.
String resolveBaseUrl(String raw, {required bool isAndroidEmulator}) {
  var url = raw.trim();
  if (!url.endsWith('/')) url = '$url/';
  final uri = Uri.tryParse(url);
  if (uri == null || !isAndroidEmulator) return url;
  if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
    return uri.replace(host: '10.0.2.2').toString();
  }
  return url;
}

Future<bool> isAndroidEmulator() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  final info = await DeviceInfoPlugin().androidInfo;
  return !info.isPhysicalDevice;
}
