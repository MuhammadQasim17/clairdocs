import 'dart:async';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/security/credential_resolver.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/utils/document_file_helper.dart';
import '../../../core/utils/json_sanitizer.dart';
import '../models/audit_models.dart';
import 'groq_audit_service.dart';
import 'pdf_extraction_service.dart';

class GeminiAuditService {
  final SecureStorageService _secureStorage;
  final PdfExtractionService _pdfExtractor;
  final GroqAuditService _groqService;
  final String? Function()? inAppKeyReader;
  final Future<void> Function(Duration delay) _delayFn;
  final Duration geminiRequestTimeout;
  final Duration geminiSlowStatusDelay;

  static const String modelName = ApiConstants.defaultGeminiModel;
  static const String fallbackModelName = ApiConstants.fallbackGeminiModel;
  static const String modelDisplayName =
      ApiConstants.defaultGeminiModelDisplayName;
  static const int maxRateLimitRetries = ApiConstants.maxRetryAttempts;

  String get activeModelName => modelName;
  String get activeModelDisplayName => modelDisplayName;

  static const String _compileTimeApiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static const String _systemInstructionText =
      'Expert enterprise contract auditor. Compare vendor invoice vs governing contract (rates, expenses, caps, terms) '
      'and extract the exact legal vendorName, clientName, invoiceNumber, and contractReference from document headers (never filenames). '
      'Skip verbose chain-of-thought explanations. Return ONLY the raw JSON object conforming to the AuditResult schema.';

  static final Schema _auditResultSchema = Schema.object(
    properties: {
      'currency': Schema.string(
        description:
            '3-letter ISO currency code (e.g. USD, EUR, GBP). Default USD.',
      ),
      'vendorName': Schema.string(
        description:
            'Actual legal vendor/supplier company name from invoice header (e.g. CloudScale Solutions LLC), never filename.',
        nullable: true,
      ),
      'vendorEmail': Schema.string(
        description:
            'Vendor billing or Accounts Receivable email extracted from invoice header if present.',
        nullable: true,
      ),
      'clientName': Schema.string(
        description: 'Client / payor company name from Bill To or contract header.',
        nullable: true,
      ),
      'invoiceNumber': Schema.string(
        description: 'Invoice number or reference ID extracted from the invoice header.',
        nullable: true,
      ),
      'contractReference': Schema.string(
        description: 'Contract/MSA/SOW reference ID extracted from the contract header.',
        nullable: true,
      ),
      'totalVarianceAmount': Schema.number(
        description:
            'Total monetary overcharge or disputed variance (invoicedTotal - verifiedContractBase).',
      ),
      'invoicedTotal': Schema.number(
        description: 'Total monetary amount billed on the invoice.',
      ),
      'verifiedContractBase': Schema.number(
        description:
            'Total monetary amount that should have been billed according to the contract.',
      ),
      'variancePercentage': Schema.number(
        description:
            'Percentage overcharge ((totalVarianceAmount / verifiedContractBase) * 100).',
      ),
      'findings': Schema.array(
        description:
            'List of all detected contractual breaches, overcharges, and billing discrepancies.',
        items: Schema.object(
          properties: {
            'id': Schema.string(
              description: 'Unique finding identifier (e.g. finding-01).',
            ),
            'title': Schema.string(
              description: 'Short, clear title of the discrepancy.',
            ),
            'category': Schema.enumString(
              enumValues: [
                'rate_breach',
                'unapproved_expense',
                'hour_cap_exceeded',
                'term_mismatch',
              ],
              description: 'Classification of the discrepancy.',
            ),
            'description': Schema.string(
              description:
                  'Detailed explanation citing exact numbers and contract terms.',
            ),
            'clauseReference': Schema.string(
              description:
                  'Specific contract clause, section, or exhibit cited (e.g. Section 4.2, Exhibit B).',
            ),
            'invoiceLineReference': Schema.string(
              description:
                  'Specific invoice line item number or section (e.g. Line Item #01).',
            ),
            'searchKeyword': Schema.string(
              description:
                  'Short exact searchable role, service description, or keyword present in the document (e.g. "Senior DevOps Engineer", "Section 3.1").',
              nullable: true,
            ),
            'agreedRate': Schema.number(
              description:
                  'Contractually agreed unit or hourly rate if applicable.',
              nullable: true,
            ),
            'billedRate': Schema.number(
              description: 'Actual rate billed on the invoice if applicable.',
              nullable: true,
            ),
            'varianceAmount': Schema.number(
              description: 'Net dollar discrepancy for this specific finding.',
            ),
            'severity': Schema.enumString(
              enumValues: ['high', 'medium', 'low'],
              description: 'Risk severity of the finding.',
            ),
          },
          requiredProperties: [
            'id',
            'title',
            'category',
            'description',
            'clauseReference',
            'invoiceLineReference',
            'varianceAmount',
            'severity',
          ],
        ),
      ),
    },
    requiredProperties: [
      'currency',
      'totalVarianceAmount',
      'invoicedTotal',
      'verifiedContractBase',
      'variancePercentage',
      'findings',
    ],
  );

  GeminiAuditService({
    SecureStorageService? secureStorage,
    PdfExtractionService? pdfExtractor,
    GroqAuditService? groqService,
    this.inAppKeyReader,
    Future<void> Function(Duration delay)? delayFn,
    this.geminiRequestTimeout = ApiConstants.geminiAuditTimeout,
    this.geminiSlowStatusDelay = ApiConstants.geminiSlowStatusDelay,
  })  : _secureStorage = secureStorage ?? const SecureStorageService(),
        _pdfExtractor = pdfExtractor ?? const PdfExtractionService(),
        _groqService = groqService ?? GroqAuditService(),
        _delayFn = delayFn ?? Future<void>.delayed;

  Future<String> resolveApiKey() async {
    final key = await CredentialResolver.resolveApiKey(
      envKeyName: 'GEMINI_API_KEY',
      readSecureStorage: _secureStorage.getApiKey,
      compileTimeKey: _compileTimeApiKey,
      inAppKeyReader: inAppKeyReader,
    );
    if (key != null && key.isNotEmpty) {
      return key;
    }

    throw const ApiKeyMissingException(
      'Gemini API key not configured. Open Settings & Credential Store to save your key or pass --dart-define=GEMINI_API_KEY.',
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
    await _secureStorage.saveApiKey(apiKey);
  }

  bool isRateLimitError(Object error) {
    if (error is GeminiRateLimitException) return true;
    final msg = error.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('quota exceeded') ||
        msg.contains('resource_exhausted') ||
        msg.contains('rate limit') ||
        msg.contains('rate-limit') ||
        msg.contains('too many requests');
  }

  bool isServerBusyError(Object error) {
    if (error is GeminiServerBusyException) return true;
    final msg = error.toString().toLowerCase();
    return msg.contains('503') ||
        msg.contains('unavailable') ||
        msg.contains('high demand') ||
        msg.contains('spikes in demand') ||
        msg.contains('overloaded') ||
        msg.contains('service unavailable');
  }

  bool isModelNotFoundOrRetiredError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('404') ||
        msg.contains('not found') ||
        msg.contains('retired') ||
        msg.contains('deprecated') ||
        msg.contains('no longer supported');
  }

  bool _isNonRetryableError(Object error) {
    if (error is ApiKeyMissingException ||
        error is DocumentParseException ||
        error is MalformedPayloadException ||
        error is FormatException) {
      return true;
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('api_key_invalid') ||
        msg.contains('api key not valid') ||
        msg.contains('permission_denied') ||
        msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('invalid argument');
  }

  int extractRetryDelaySeconds(Object error, int retryAttempt) {
    final msg = error.toString();

    final retryInMatch = RegExp(
      r'retry\s+(?:in|after)[:\s]+(\d+(?:\.\d+)?)\s*s',
      caseSensitive: false,
    ).firstMatch(msg);
    if (retryInMatch != null) {
      final parsed = double.tryParse(retryInMatch.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        return parsed.ceil().clamp(4, 60);
      }
    }

    final headerMatch = RegExp(
      r'retry[-_]after[:\s=]+(\d+)',
      caseSensitive: false,
    ).firstMatch(msg);
    if (headerMatch != null) {
      final parsed = int.tryParse(headerMatch.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        return parsed.clamp(4, 60);
      }
    }

    // Exponential backoff starting at 4s (4s -> 8s)
    return (4 * (1 << retryAttempt)).clamp(4, 60);
  }

  /// Executes [requestFn] with up to [maxRateLimitRetries] retries on 429
  /// rate-limit, 503 high-demand, or transient failures, reporting status via [onRetryStatus].
  Future<String?> executeWithRateLimitRetry(
    Future<String?> Function() requestFn, {
    void Function(String statusMessage)? onRetryStatus,
  }) async {
    int retryCount = 0;

    while (true) {
      try {
        return await requestFn();
      } catch (error) {
        final isRateLimit = isRateLimitError(error);
        final isServerBusy = isServerBusyError(error);
        final isModelMissing = isModelNotFoundOrRetiredError(error);

        if (_isNonRetryableError(error) ||
            (isModelMissing && !isRateLimit && !isServerBusy)) {
          rethrow;
        }

        if (retryCount >= maxRateLimitRetries) {
          if (isRateLimit) {
            throw GeminiRateLimitException(
              'AI Studio Free Tier Limit Reached (5 requests/min). '
              'Please wait a few seconds before trying again, or configure pay-as-you-go billing in Google AI Studio.',
              error,
            );
          }
          if (isServerBusy) {
            throw GeminiServerBusyException(
              'Google AI servers are experiencing temporary high demand (503). '
              'Please wait 30 seconds and tap Retry Audit.',
              error,
            );
          }
          if (error is GenerativeAIException) {
            throw GeminiApiException(
              'Gemini API error: ${error.message}',
              null,
              error,
            );
          }
          if (error is TimeoutException) {
            throw GeminiApiException(
              'Audit request timed out after ${ApiConstants.requestTimeout.inSeconds}s.',
              408,
              error,
            );
          }
          rethrow;
        }

        final delaySeconds = isRateLimit
            ? extractRetryDelaySeconds(error, retryCount)
            : (2 * (1 << retryCount)); // 2s -> 4s exponential backoff

        final statusMsg = isRateLimit
            ? 'Rate limit reached. Retrying automatically in $delaySeconds seconds...'
            : isServerBusy
                ? 'Google AI servers busy, retrying in ${delaySeconds}s...'
                : 'Transient connection issue. Retrying in ${delaySeconds}s...';
        onRetryStatus?.call(statusMsg);

        await _delayFn(Duration(seconds: delaySeconds));
        retryCount++;
      }
    }
  }

  /// Attempts [requestForModel] across [models] (defaulting to [ApiConstants.geminiModelFallbackChain]).
  /// Returns the response text or falls back across Gemini models on 503/404.
  Future<String?> executeWithModelFallback(
    Future<String?> Function(String modelId) requestForModel, {
    List<String> models = ApiConstants.geminiModelFallbackChain,
    void Function(String statusMessage)? onRetryStatus,
  }) async {
    final result = await executeWithModelFallbackDetailed(
      requestForModel,
      models: models,
      onRetryStatus: onRetryStatus,
    );
    return result.text;
  }

  Future<({String? text, String modelId})> executeWithModelFallbackDetailed(
    Future<String?> Function(String modelId) requestForModel, {
    List<String> models = ApiConstants.geminiModelFallbackChain,
    void Function(String statusMessage)? onRetryStatus,
  }) async {
    Object? lastBusyOrCapacityError;

    for (var i = 0; i < models.length; i++) {
      final candidateModel = models[i];
      final hasFallbackRemaining = i < models.length - 1;

      try {
        final text = await executeWithRateLimitRetry(
          () => requestForModel(candidateModel),
          onRetryStatus: onRetryStatus,
        );
        return (text: text, modelId: candidateModel);
      } on GeminiServerBusyException catch (e) {
        lastBusyOrCapacityError = e;
        if (hasFallbackRemaining) {
          final nextModel = models[i + 1];
          onRetryStatus?.call(
            'Servers busy on $candidateModel. Switching to fallback $nextModel...',
          );
          continue;
        }
        rethrow;
      } catch (e) {
        if (isModelNotFoundOrRetiredError(e) && hasFallbackRemaining) {
          lastBusyOrCapacityError = e;
          final nextModel = models[i + 1];
          onRetryStatus?.call(
            'Model $candidateModel unavailable. Switching to fallback $nextModel...',
          );
          continue;
        }
        rethrow;
      }
    }

    throw GeminiServerBusyException(
      'Google AI servers are experiencing temporary high demand (503). '
      'Please wait 30 seconds and tap Retry Audit.',
      lastBusyOrCapacityError,
    );
  }

  String _engineLabelForModel(String modelId) {
    if (modelId == ApiConstants.defaultGeminiModel) {
      return 'Gemini 3.8';
    }
    if (modelId == ApiConstants.fallbackGeminiModel) {
      return 'Gemini 3.5 Lite';
    }
    return modelId;
  }

  AuditResult _mergePartyMetadata(
    AuditResult result, {
    required String contractText,
    required String invoiceText,
  }) {
    final headerMeta = PdfExtractionService.extractPartyMetadata(
      contractText: contractText,
      invoiceText: invoiceText,
    );

    String? pickClean(String? llmVal, String? headerVal, {bool rejectExt = false}) {
      final cleaned = llmVal?.trim();
      final isFileEcho = rejectExt &&
          cleaned != null &&
          RegExp(r'\.(pdf|docx|doc|csv|xlsx|xls)$', caseSensitive: false)
              .hasMatch(cleaned);
      final validLlm = cleaned != null &&
          cleaned.isNotEmpty &&
          !isFileEcho &&
          cleaned.toLowerCase() != 'null' &&
          cleaned.toLowerCase() != 'unknown' &&
          cleaned.toLowerCase() != 'n/a';
      if (validLlm) return cleaned;
      return headerVal;
    }

    return result.copyWith(
      vendorName: pickClean(
        result.vendorName,
        headerMeta.vendorName,
        rejectExt: true,
      ),
      vendorEmail: pickClean(result.vendorEmail, headerMeta.vendorEmail),
      clientName: pickClean(result.clientName, headerMeta.clientName),
      invoiceNumber: pickClean(
        result.invoiceNumber,
        headerMeta.invoiceNumber,
        rejectExt: true,
      ),
      contractReference: pickClean(
        result.contractReference,
        headerMeta.contractReference,
        rejectExt: true,
      ),
    );
  }

  /// Hybrid orchestration: runs single-shot fast Gemini phase (strict 8s timeout),
  /// updates status after 4s, and on timeout/429/503/quota/key/network errors
  /// immediately routes to [GroqAuditService] (`openai/gpt-oss-20b` primary).
  Future<AuditResult> executeHybridAudit({
    required String contractText,
    required String invoiceText,
    required Future<({String? text, String modelId})> Function() geminiPhaseFn,
    void Function(String statusMessage)? onRetryStatus,
    bool isContractSpreadsheet = false,
    bool isInvoiceSpreadsheet = false,
  }) async {
    var geminiSettled = false;
    Timer? slowTimer;
    if (onRetryStatus != null) {
      slowTimer = Timer(geminiSlowStatusDelay, () {
        if (!geminiSettled) {
          onRetryStatus('Routing to Groq ultra-fast engine...');
        }
      });
    }

    try {
      final geminiResponse =
          await geminiPhaseFn().timeout(geminiRequestTimeout);
      geminiSettled = true;
      slowTimer?.cancel();

      final rawText = geminiResponse.text;
      if (rawText == null || rawText.trim().isEmpty) {
        throw const MalformedPayloadException(
          'Gemini returned an empty response payload.',
        );
      }

      final jsonMap = JsonSanitizer.decodeSafe(rawText);
      final AuditResult parsed;
      try {
        parsed = AuditResult.fromJson(jsonMap);
      } on CheckedFromJsonException catch (e) {
        throw MalformedPayloadException(
          'Gemini returned an invalid schema payload: ${e.message ?? e}',
          e,
        );
      } on TypeError catch (e) {
        throw MalformedPayloadException(
          'Gemini returned an unexpected schema field type.',
          e,
        );
      }
      return _mergePartyMetadata(
        parsed.copyWith(
          auditEngine: _engineLabelForModel(geminiResponse.modelId),
        ),
        contractText: contractText,
        invoiceText: invoiceText,
      );
    } on FormatException catch (formatError, stackTrace) {
      geminiSettled = true;
      slowTimer?.cancel();
      final wrapped = MalformedPayloadException(
        'Failed to parse Gemini JSON output: ${formatError.message}',
        formatError,
      );
      return _handleGeminiFailureOrFailover(
        wrapped,
        stackTrace,
        contractText: contractText,
        invoiceText: invoiceText,
        onRetryStatus: onRetryStatus,
        isContractSpreadsheet: isContractSpreadsheet,
        isInvoiceSpreadsheet: isInvoiceSpreadsheet,
      );
    } catch (geminiError, stackTrace) {
      geminiSettled = true;
      slowTimer?.cancel();
      return _handleGeminiFailureOrFailover(
        geminiError,
        stackTrace,
        contractText: contractText,
        invoiceText: invoiceText,
        onRetryStatus: onRetryStatus,
        isContractSpreadsheet: isContractSpreadsheet,
        isInvoiceSpreadsheet: isInvoiceSpreadsheet,
      );
    } finally {
      geminiSettled = true;
      slowTimer?.cancel();
    }
  }

  Future<AuditResult> _handleGeminiFailureOrFailover(
    Object geminiError,
    StackTrace geminiStackTrace, {
    required String contractText,
    required String invoiceText,
    required void Function(String statusMessage)? onRetryStatus,
    required bool isContractSpreadsheet,
    required bool isInvoiceSpreadsheet,
  }) async {
    final isTimeout = geminiError is TimeoutException ||
        geminiError.toString().toLowerCase().contains('timed out');
    final shouldFailoverToGroq = isTimeout ||
        isRateLimitError(geminiError) ||
        isServerBusyError(geminiError) ||
        isModelNotFoundOrRetiredError(geminiError) ||
        geminiError is ApiKeyMissingException ||
        geminiError is GenerativeAIException ||
        geminiError is SocketException ||
        geminiError is MalformedPayloadException;

    if (!shouldFailoverToGroq ||
        contractText.trim().isEmpty ||
        invoiceText.trim().isEmpty) {
      Error.throwWithStackTrace(geminiError, geminiStackTrace);
    }

    // Seamless Failover to Groq ultra-fast engine using extracted/truncated plain text
    onRetryStatus?.call('Routing to Groq ultra-fast engine...');

    try {
      final groqResult = await _groqService.auditDocuments(
        contractText: contractText,
        invoiceText: invoiceText,
        isContractSpreadsheet: isContractSpreadsheet,
        isInvoiceSpreadsheet: isInvoiceSpreadsheet,
      );
      return _mergePartyMetadata(
        groqResult,
        contractText: contractText,
        invoiceText: invoiceText,
      );
    } catch (groqError) {
      final geminiReason = geminiError is ClairException
          ? geminiError.message
          : geminiError.toString();
      final groqReason = groqError is ClairException
          ? groqError.message
          : groqError.toString();
      throw DualEngineAuditException(
        'Both AI audit engines failed to complete the request.\n'
        '• Gemini ($modelName): $geminiReason\n'
        '• Groq (${ApiConstants.groqModel}): $groqReason\n'
        'Please verify your API keys in Settings & Credential Store or retry shortly.',
        groqError,
      );
    }
  }

  Future<String> _buildDocumentDescriptor(
    File file,
    String? extractionResult,
  ) async {
    int sizeBytes = 0;
    try {
      if (await file.exists()) {
        sizeBytes = await file.length();
      }
    } catch (_) {}

    final ext = DocumentFileHelper.extensionOf(file.path).toUpperCase();
    final reason = (extractionResult != null && extractionResult.trim().isNotEmpty)
        ? extractionResult.trim()
        : 'Empty or scanned image-only document';
    final fileName =
        file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : file.path;

    return '[Document Descriptor Fallback]\n'
        'File Name: $fileName\n'
        'Format: ${ext.isEmpty ? "UNKNOWN" : ext}\n'
        'Size: $sizeBytes bytes\n'
        'Extraction Note: $reason';
  }

  Future<AuditResult> auditDocuments({
    required File contractFile,
    required File invoiceFile,
    void Function(String statusMessage)? onRetryStatus,
    String? preExtractedContractText,
    String? preExtractedInvoiceText,
  }) async {
    final isContractSheet =
        DocumentFileHelper.isSpreadsheetPath(contractFile.path);
    final isInvoiceSheet =
        DocumentFileHelper.isSpreadsheetPath(invoiceFile.path);

    String rawContractText = preExtractedContractText ?? '';
    String rawInvoiceText = preExtractedInvoiceText ?? '';

    if (preExtractedContractText == null || preExtractedInvoiceText == null) {
      onRetryStatus?.call('Extracting text locally from documents...');
      try {
        final extracted = await Future.wait<String>([
          preExtractedContractText != null
              ? Future.value(preExtractedContractText)
              : _pdfExtractor.extractDocumentText(contractFile),
          preExtractedInvoiceText != null
              ? Future.value(preExtractedInvoiceText)
              : _pdfExtractor.extractDocumentText(invoiceFile),
        ]);
        rawContractText = extracted[0];
        rawInvoiceText = extracted[1];
      } catch (e) {
        if (rawContractText.isEmpty) {
          rawContractText = 'Extraction failed: $e';
        }
        if (rawInvoiceText.isEmpty) {
          rawInvoiceText = 'Extraction failed: $e';
        }
      }
    }

    onRetryStatus?.call('Auditing with Gemini 3.8 / Groq...');

    final contractUsable =
        !PdfExtractionService.isExtractionFailureOrEmpty(rawContractText);
    final invoiceUsable =
        !PdfExtractionService.isExtractionFailureOrEmpty(rawInvoiceText);

    final effectiveContractText = GroqAuditService.truncatePromptText(
      contractUsable
          ? rawContractText
          : await _buildDocumentDescriptor(contractFile, rawContractText),
    );
    final effectiveInvoiceText = GroqAuditService.truncatePromptText(
      invoiceUsable
          ? rawInvoiceText
          : await _buildDocumentDescriptor(invoiceFile, rawInvoiceText),
    );

    final Content prompt;
    if (contractUsable && invoiceUsable) {
      final contractBlock = isContractSheet
          ? 'Contract Spreadsheet Data:\n$effectiveContractText'
          : 'Document 1 — Governing Contract Text:\n$effectiveContractText';
      final invoiceBlock = isInvoiceSheet
          ? 'Invoice Spreadsheet Data:\n$effectiveInvoiceText'
          : 'Document 2 — Target Vendor Invoice Text:\n$effectiveInvoiceText';

      // Concise, low-latency prompt skipping verbose CoT reasoning
      prompt = Content.text('''
$contractBlock

---
$invoiceBlock

Compare invoice vs contract (rates, expenses, caps, discounts). Skip chain-of-thought reasoning. Return ONLY the raw JSON object conforming to the AuditResult schema.
''');
    } else if (DocumentFileHelper.isPdfPath(contractFile.path) ||
        DocumentFileHelper.isPdfPath(invoiceFile.path)) {
      // Multimodal direct PDF fallback when local extraction timed out or returned empty
      final parts = <Part>[];
      if (!contractUsable && DocumentFileHelper.isPdfPath(contractFile.path)) {
        parts.add(
          TextPart('Document 1 — Governing Contract / Statement of Work (PDF):'),
        );
        parts.add(DataPart('application/pdf', await contractFile.readAsBytes()));
      } else {
        parts.add(
          TextPart(
            '${isContractSheet ? "Contract Spreadsheet Data:" : "Document 1 — Governing Contract Text:"}\n$effectiveContractText',
          ),
        );
      }

      if (!invoiceUsable && DocumentFileHelper.isPdfPath(invoiceFile.path)) {
        parts.add(TextPart('Document 2 — Target Vendor Invoice (PDF):'));
        parts.add(DataPart('application/pdf', await invoiceFile.readAsBytes()));
      } else {
        parts.add(
          TextPart(
            '${isInvoiceSheet ? "Invoice Spreadsheet Data:" : "Document 2 — Target Vendor Invoice Text:"}\n$effectiveInvoiceText',
          ),
        );
      }

      parts.add(
        TextPart(
          'Compare invoice vs contract. Skip chain-of-thought reasoning. Return ONLY raw JSON conforming to the AuditResult schema.',
        ),
      );
      prompt = Content.multi(parts);
    } else {
      prompt = Content.text('''
${isContractSheet ? "Contract Spreadsheet Data:" : "Document 1 — Governing Contract Text:"}
$effectiveContractText

---
${isInvoiceSheet ? "Invoice Spreadsheet Data:" : "Document 2 — Target Vendor Invoice Text:"}
$effectiveInvoiceText

Compare invoice vs contract. Skip chain-of-thought reasoning. Return ONLY raw JSON conforming to the AuditResult schema.
''');
    }

    return executeHybridAudit(
      contractText: effectiveContractText,
      invoiceText: effectiveInvoiceText,
      onRetryStatus: onRetryStatus,
      isContractSpreadsheet: isContractSheet,
      isInvoiceSpreadsheet: isInvoiceSheet,
      geminiPhaseFn: () async {
        final apiKey = await resolveApiKey();
        final model = GenerativeModel(
          model: ApiConstants.defaultGeminiModel,
          apiKey: apiKey,
          systemInstruction: Content.system(_systemInstructionText),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: _auditResultSchema,
            temperature: 0.1,
          ),
        );
        // Single-shot fast 8s timeout; no Gemini retries so failover to Groq is immediate
        final response = await model
            .generateContent([prompt])
            .timeout(geminiRequestTimeout);
        return (
          text: response.text,
          modelId: ApiConstants.defaultGeminiModel,
        );
      },
    );
  }
}
