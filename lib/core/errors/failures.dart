sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ApiKeyMissingFailure extends Failure {
  const ApiKeyMissingFailure([super.message = 'API key is missing. Please configure it in Settings.']);
}

class GeminiApiFailure extends Failure {
  final int? statusCode;
  const GeminiApiFailure(super.message, [this.statusCode]);
}

class DocumentParseFailure extends Failure {
  const DocumentParseFailure(super.message);
}

class MalformedPayloadFailure extends Failure {
  const MalformedPayloadFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection unavailable. Please check your internet connection.']);
}

