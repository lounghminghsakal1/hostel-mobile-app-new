import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/core/network/base_url.dart';

void main() {
  test('localhost points at the computer when running on the Android emulator', () {
    expect(resolveBaseUrl('http://localhost:2471/api/v1/', isAndroidEmulator: true), 'http://10.0.2.2:2471/api/v1/');
    expect(resolveBaseUrl('http://127.0.0.1:2471/api/v1', isAndroidEmulator: true), 'http://10.0.2.2:2471/api/v1/');
  });

  test('other devices and real hosts are left alone', () {
    expect(resolveBaseUrl('http://localhost:2471/api/v1/', isAndroidEmulator: false), 'http://localhost:2471/api/v1/');
    expect(resolveBaseUrl('http://192.168.1.20:2471/api/v1/', isAndroidEmulator: true), 'http://192.168.1.20:2471/api/v1/');
    expect(resolveBaseUrl('https://api.ourhostel.in/api/v1', isAndroidEmulator: true), 'https://api.ourhostel.in/api/v1/');
  });
}
