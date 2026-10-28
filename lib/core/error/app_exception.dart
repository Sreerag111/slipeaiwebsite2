class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MissingApiKeyException extends AppException {
  const MissingApiKeyException()
      : super('Set your OpenAI API key in Settings first');
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

