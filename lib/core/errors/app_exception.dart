/// An error whose [message] is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Raised by the products API layer (network, timeout, non-2xx responses).
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});

  final int? statusCode;
}
