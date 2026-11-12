import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../errors/exceptions.dart';

class JsonSanitizer {
  JsonSanitizer._();

  /// Strips markdown code blocks (e.g. ```json ... ```) and extracts raw JSON.
  static String extractCleanJson(String rawResponse) {
    var cleaned = rawResponse.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    cleaned = cleaned.trim();

    // Find first '{' or '[' and last '}' or ']'
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');

    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }

    return cleaned;
  }

  /// Parses JSON string safely into a Map.
  static Map<String, dynamic> decodeSafe(String rawContent) {
    final sanitized = extractCleanJson(rawContent);
    final dynamic decoded = jsonDecode(sanitized);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected JSON object at root of audit response');
  }

  /// Decodes raw LLM output and maps it via [fromJson], converting JSON syntax
  /// or schema type mismatches into [MalformedPayloadException].
  static T decodeAndParse<T>(
    String rawContent,
    T Function(Map<String, dynamic> json) fromJson, {
    String sourceLabel = 'AI engine',
  }) {
    try {
      final jsonMap = decodeSafe(rawContent);
      return fromJson(jsonMap);
    } on FormatException catch (e) {
      throw MalformedPayloadException(
        'Failed to parse $sourceLabel JSON output: ${e.message}',
        e,
      );
    } on CheckedFromJsonException catch (e) {
      throw MalformedPayloadException(
        '$sourceLabel returned an invalid schema payload: ${e.message ?? e}',
        e,
      );
    } on TypeError catch (e) {
      throw MalformedPayloadException(
        '$sourceLabel returned an unexpected schema field type.',
        e,
      );
    }
  }
}

