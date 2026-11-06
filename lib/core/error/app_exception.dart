/// The one error type the domain and presentation layers deal with.
/// Data sources turn HTTP and parsing failures into this (see `guardApi`).
class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  /// Safe to show to the user.
  final String message;
  final int? statusCode;

  /// The backend's short `errors` string when it sends one, for example
  /// "Password setup required" or "Account is not active".
  final String? code;

  /// Per-field messages when the backend returns `errors` as an object.
  final Map<String, String> fieldErrors;

  bool get isNetworkError => code == 'network' || code == 'timeout';

  @override
  String toString() => message;
}

/// Thrown by data sources whose backend endpoint is not built yet.
/// Screens show a friendly "coming soon" state instead of an error.
/// Every place that throws this is listed in `docs/API_GAPS.md`.
class ApiPendingException extends AppException {
  const ApiPendingException(
    this.endpoint, {
    String message = "This part of the app isn't available yet. It's coming soon.",
  }) : super(message, code: 'api_pending');

  /// The endpoint the backend still needs, for example `GET /mess_fee/my_bills`.
  final String endpoint;
}

AppException toAppException(Object error) {
  if (error is AppException) return error;
  return const AppException('Something went wrong. Please try again.');
}
