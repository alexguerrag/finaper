class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

class BootstrapException extends AppException {
  const BootstrapException(super.message, {super.code});
}

class LocalDataException extends AppException {
  const LocalDataException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}
