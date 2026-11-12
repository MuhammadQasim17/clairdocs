class ClairException implements Exception {
  final String message;
  final dynamic cause;

  const ClairException(this.message, [this.cause]);

  @override
  String toString() =>
      'ClairException: $message ${cause != null ? '($cause)' : ''}';
}

class ApiKeyMissingException extends ClairException {
  const ApiKeyMissingException([
    super.message = 'Google AI Studio API key not found in secure storage.',
  ]);
}

class GeminiApiException extends ClairException {
  final int? statusCode;
  const GeminiApiException(super.message, [this.statusCode, super.cause]);
}

class GeminiRateLimitException extends GeminiApiException {
  const GeminiRateLimitException([
    String message =
        'AI Studio Free Tier Limit Reached (5 requests/min). Please wait a few seconds before trying again, or configure pay-as-you-go billing in Google AI Studio.',
    dynamic cause,
  ]) : super(message, 429, cause);
}

class GeminiServerBusyException extends GeminiApiException {
  const GeminiServerBusyException([
    String message =
        'Google AI servers are experiencing temporary high demand (503). Please wait 30 seconds and tap Retry Audit.',
    dynamic cause,
  ]) : super(message, 503, cause);
}

class GroqApiException extends ClairException {
  final int? statusCode;
  const GroqApiException(super.message, [this.statusCode, super.cause]);
}

class DualEngineAuditException extends ClairException {
  const DualEngineAuditException(super.message, [super.cause]);
}

class DocumentParseException extends ClairException {
  const DocumentParseException(super.message, [super.cause]);
}

class MalformedPayloadException extends ClairException {
  const MalformedPayloadException(super.message, [super.cause]);
}
