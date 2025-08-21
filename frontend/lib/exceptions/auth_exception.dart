class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

class RegisterException extends AuthException {
  const RegisterException(String message, {String? code})
      : super(message, code: code);
}

class LoginException extends AuthException {
  const LoginException(String message, {String? code})
      : super(message, code: code);
}

class NetworkException extends AuthException {
  const NetworkException(String message, {String? code})
      : super(message, code: code);
}
