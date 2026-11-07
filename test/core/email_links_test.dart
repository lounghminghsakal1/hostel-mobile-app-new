import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/app/router/routes.dart';
import 'package:our_hostel/core/network/api_guard.dart';

DioException _serverError(int status, Object? body) {
  final options = RequestOptions(path: '/students/activation_link');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status, data: body),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test('https email links (App Links) open the Set password screen', () {
    final token = 'a' * 64;
    expect(
      setPasswordDeepLinkTarget(Uri.parse('https://api.ourhostel.in/open/setup-password?token=$token&mode=welcome')),
      '/set-password?token=$token&mode=welcome',
    );
    expect(
      setPasswordDeepLinkTarget(Uri.parse('https://api.ourhostel.in/open/setup-password?token=$token&mode=reset')),
      '/set-password?token=$token&mode=reset',
    );
    // the landing page's button
    expect(
      setPasswordDeepLinkTarget(Uri.parse('ourhostel://setup-password?token=$token&mode=welcome')),
      '/set-password?token=$token&mode=welcome',
    );
    expect(setPasswordDeepLinkTarget(Uri.parse('https://api.ourhostel.in/api/v1/students')), isNull);
  });

  test("a server's 5xx message reaches the user (e.g. why the email failed)", () {
    final error = mapDioException(_serverError(502, {
      'message': "Couldn't send the activation email: Amazon SES is still in sandbox (test) mode.",
      'errors': 'Email not sent',
    }));
    expect(error.message, startsWith("Couldn't send the activation email"));
    expect(error.code, 'Email not sent');
  });

  test('a 5xx without a JSON message (proxy error page) stays generic', () {
    final error = mapDioException(_serverError(502, '<html>Bad Gateway</html>'));
    expect(error.message, 'Something went wrong on our side. Please try again in a moment.');
  });
}
