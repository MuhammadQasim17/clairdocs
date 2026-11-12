import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/security/credential_resolver.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/utils/json_sanitizer.dart';
import '../models/audit_models.dart';

class GroqTextCompletionResult {
  final String text;
  final String engineLabel;

  const GroqTextCompletionResult({
    required this.text,
    required this.engineLabel,
  });
}

class GroqAuditService {
  final http.Client? httpClient;
  final SecureStorageService _secureStorage;
  final String? Function()? inAppKeyReader;

  static const String _compileTimeGroqKey =
      String.fromEnvironment('GROQ_API_KEY');

  static const String _systemPrompt = '''
Expert enterprise contract auditor. Compare vendor invoice vs governing contract (rates, expenses, caps, terms) and extract exact header parties.
Skip verbose chain-of-thought explanations and output ONLY a raw valid JSON object matching this exact schema (no markdown fences, no extra fields):
{
  "currency": "USD",
  "vendorName": "<exact legal vendor company name from invoice header, NOT filename>",
  "vendorEmail": "<vendor billing/AR email from invoice header, or null>",
  "clientName": "<billed client/payor company name from invoice/contract, or null>",
  "invoiceNumber": "<invoice identifier/number e.g. INV-2026-889, or null>",
  "contractReference": "<contract/MSA/SOW identifier, or null>",
  "totalVarianceAmount": <number: invoicedTotal - verifiedContractBase>,
  "invoicedTotal": <number>,
  "verifiedContractBase": <number>,
  "variancePercentage": <number>,
  "findings": [
    {
      "id": "<e.g. finding-01>",
      "title": "<short title>",
      "category": "<rate_breach | unapproved_expense | hour_cap_exceeded | term_mismatch>",
      "description": "<concise explanation citing amounts and contract clauses>",
      "clauseReference": "<e.g. Section 4.2>",
      "invoiceLineReference": "<e.g. Line Item #01>",
      "searchKeyword": "<exact short searchable role/item keyword from contract or invoice, e.g. Senior DevOps Engineer>",
      "agreedRate": <number or null>,
      "billedRate": <number or null>,
      "varianceAmount": <number>,
      "severity": "<high | medium | low>"
    }
  ]
}
''';

  static String truncatePromptText(
    String text, {
    int maxChars = ApiConstants.maxPromptDocumentChars,
  }) {
    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }

  GroqAuditService({
    this.httpClient,
    SecureStorageService? secureStorage,
    this.inAppKeyReader,
  }) : _secureStorage = secureStorage ?? const SecureStorageService();

  Future<String> resolveApiKey() async {
    final key = await CredentialResolver.resolveApiKey(
      envKeyName: 'GROQ_API_KEY',
      readSecureStorage: _secureStorage.getGroqApiKey,
      compileTimeKey: _compileTimeGroqKey,
      inAppKeyReader: inAppKeyReader,
    );
    if (key != null && key.isNotEmpty) {
      return key;
    }

    throw const ApiKeyMissingException(
      'Groq API key not configured. Open Settings & Credential Store to save GROQ_API_KEY or pass --dart-define=GROQ_API_KEY.',
    );
  }

  Future<bool> hasConfiguredApiKey() async {
    try {
      final key = await resolveApiKey();
      return key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.saveGroqApiKey(apiKey);
  }

  bool _isRecoverableModelError(int statusCode) {
    return statusCode == 404 || statusCode == 429 || statusCode == 503;
  }

  String _engineLabelForModel(String modelId) {
    if (modelId == ApiConstants.groqFallbackModel) {
      return ApiConstants.groqFallbackEngineLabel;
    }
    return ApiConstants.groqEngineLabel;
  }

  Future<GroqTextCompletionResult> _postWithFallback({
    required List<Map<String, String>> messages,
    required double temperature,
    required int maxTokens,
    required bool jsonObjectFormat,
    required Duration timeout,
    List<String> modelChain = ApiConstants.groqModelFallbackChain,
  }) async {
    final apiKey = await resolveApiKey();
    final client = httpClient ?? http.Client();
    final shouldCloseClient = httpClient == null;

    try {
      GroqApiException? lastModelError;

      for (var i = 0; i < modelChain.length; i++) {
        final modelId = modelChain[i];
        final hasSecondaryFallback = i < modelChain.length - 1;

        final payloadMap = <String, dynamic>{
          'model': modelId,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'messages': messages,
        };
        if (jsonObjectFormat) {
          payloadMap['response_format'] = {'type': 'json_object'};
        }

        final response = await client
            .post(
              Uri.parse(ApiConstants.groqEndpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payloadMap),
            )
            .timeout(timeout);

        if (response.statusCode != 200) {
          String errorDetail = response.body;
          try {
            final parsedErr = jsonDecode(response.body);
            if (parsedErr is Map<String, dynamic>) {
              final errObj = parsedErr['error'];
              if (errObj is Map<String, dynamic>) {
                final errMsg = errObj['message'];
                if (errMsg is String && errMsg.trim().isNotEmpty) {
                  errorDetail = errMsg;
                }
              }
            }
          } catch (_) {}

          final err = GroqApiException(
            'Groq API error (${response.statusCode}) on $modelId: $errorDetail',
            response.statusCode,
          );
          lastModelError = err;

          if (hasSecondaryFallback &&
              _isRecoverableModelError(response.statusCode)) {
            continue;
          }
          throw err;
        }

        final dynamic decodedResponse;
        try {
          decodedResponse = jsonDecode(response.body);
        } on FormatException catch (e) {
          throw MalformedPayloadException(
            'Failed to decode Groq API JSON response: ${e.message}',
            e,
          );
        }
        if (decodedResponse is! Map<String, dynamic>) {
          throw const MalformedPayloadException(
            'Groq API returned an unexpected non-object response.',
          );
        }

        final choices = decodedResponse['choices'];
        if (choices is! List || choices.isEmpty) {
          throw const MalformedPayloadException(
            'Groq API returned no completion choices.',
          );
        }

        final firstChoice = choices.first;
        String? messageContent;
        if (firstChoice is Map<String, dynamic>) {
          final message = firstChoice['message'];
          if (message is Map<String, dynamic>) {
            final rawContent = message['content'];
            if (rawContent is String) {
              messageContent = rawContent;
            } else if (rawContent != null) {
              throw const MalformedPayloadException(
                'Groq API returned unexpected non-string message content.',
              );
            }
          }
        }

        if (messageContent == null || messageContent.trim().isEmpty) {
          throw const MalformedPayloadException(
            'Groq API returned an empty message content.',
          );
        }

        return GroqTextCompletionResult(
          text: messageContent,
          engineLabel: _engineLabelForModel(modelId),
        );
      }

      throw lastModelError ??
          const GroqApiException(
            'All Groq fallback models failed to complete the request.',
          );
    } on TimeoutException catch (e) {
      throw GroqApiException(
        'Groq request timed out after ${timeout.inSeconds}s.',
        408,
        e,
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Future<GroqTextCompletionResult> generateDisputeDraft({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.25,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    return _postWithFallback(
      messages: [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': userPrompt,
        },
      ],
      temperature: temperature,
      maxTokens: ApiConstants.groqMaxTokens,
      jsonObjectFormat: false,
      timeout: timeout,
      modelChain: ApiConstants.groqDraftModelChain,
    );
  }

  Future<AuditResult> auditDocuments({
    required String contractText,
    required String invoiceText,
    bool isContractSpreadsheet = false,
    bool isInvoiceSpreadsheet = false,
  }) async {
    if (contractText.trim().isEmpty || invoiceText.trim().isEmpty) {
      throw const DocumentParseException(
        'Extracted document text is empty. Cannot send empty payload to Groq.',
      );
    }

    final clippedContract = truncatePromptText(contractText);
    final clippedInvoice = truncatePromptText(invoiceText);

    final contractSection = isContractSpreadsheet
        ? 'Contract Spreadsheet Data:\n$clippedContract'
        : 'Contract Document Text:\n$clippedContract';
    final invoiceSection = isInvoiceSpreadsheet
        ? 'Invoice Spreadsheet Data:\n$clippedInvoice'
        : 'Vendor Invoice Text:\n$clippedInvoice';
    final userPrompt =
        '$contractSection\n\n$invoiceSection\n\nReturn ONLY raw AuditResult JSON.';

    try {
      final completion = await _postWithFallback(
        messages: [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content': userPrompt,
          },
        ],
        temperature: 0.1,
        maxTokens: ApiConstants.groqAuditMaxTokens,
        jsonObjectFormat: true,
        timeout: ApiConstants.groqAuditTimeout,
        modelChain: ApiConstants.groqModelFallbackChain,
      );

      final parsedResult = JsonSanitizer.decodeAndParse(
        completion.text,
        AuditResult.fromJson,
        sourceLabel: 'Groq',
      );
      return parsedResult.copyWith(
        auditEngine: completion.engineLabel,
      );
    } on FormatException catch (e) {
      throw MalformedPayloadException(
        'Failed to parse Groq JSON output: ${e.message}',
        e,
      );
    }
  }
}
