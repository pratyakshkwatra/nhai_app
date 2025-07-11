class APIException implements Exception {
  final String message;
  final int? code;

  APIException(this.message, [this.code]);

  @override
  String toString() => 'ApiException($code): $message';
}

class UnauthorizedException extends APIException {
  UnauthorizedException([String message = 'Unauthorized'])
      : super(message, 401);
}

class NotFoundException extends APIException {
  NotFoundException([String message = 'Not found']) : super(message, 404);
}

class ServerException extends APIException {
  ServerException([String message = 'Server error']) : super(message, 500);
}

class ValidationException extends APIException {
  ValidationException([String message = 'Validation failed'])
      : super(message, 422);
}
