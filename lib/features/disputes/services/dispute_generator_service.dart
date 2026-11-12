import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../audit/models/audit_models.dart';
import '../../audit/services/gemini_audit_service.dart';
import '../../audit/services/groq_audit_service.dart';
import '../../contracts/models/contract_document.dart';
import '../../invoices/models/invoice_document.dart';
import '../models/dispute_models.dart';

typedef GeminiDraftGeneratorFn = Future<String?> Function(
  String modelId,
  String systemPrompt,
  String promptText,
);

class DisputeGenerationResult {
  final String letterText;
  final bool usedFallback;
  final String engineLabel;

  const DisputeGenerationResult({
    required this.letterText,
    required this.usedFallback,
    this.engineLabel = 'GEMINI 3.8 LEGAL DRAFT',
  });
}

class DisputeGeneratorService {
  static const Duration defaultLlmTimeout = Duration(seconds: 8);

  final GeminiAuditService _auditService;
  final GroqAuditService _groqService;
  final Duration llmTimeout;
  final GeminiDraftGeneratorFn? geminiDraftOverride;

  DisputeGeneratorService({
    GeminiAuditService? auditService,
    GroqAuditService? groqService,
    this.llmTimeout = defaultLlmTimeout,
    this.geminiDraftOverride,
  })  : _auditService = auditService ?? GeminiAuditService(),
        _groqService = groqService ?? GroqAuditService();

  Future<String?> _generateWithGemini({
    required String apiKey,
    required String systemPrompt,
    required String promptText,
  }) async {
    final model = GenerativeModel(
      model: ApiConstants.defaultGeminiModel,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.25,
      ),
    );

    final response = await model
        .generateContent([Content.text(promptText)])
        .timeout(llmTimeout);
    return response.text;
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  Future<DisputeGenerationResult> generateDisputeNotice({
    required AuditResult auditResult,
    ContractDocument? contractDoc,
    InvoiceDocument? invoiceDoc,
    required DisputeTone tone,
    String? vendorNameOverride,
    String? clientNameOverride,
  }) async {
    final contractRef = _nonEmpty(auditResult.contractReference) ??
        contractDoc?.fileName ??
        'Master_Services_Agreement_2026.pdf';
    final invoiceRef = _nonEmpty(auditResult.invoiceNumber) ??
        invoiceDoc?.fileName ??
        'INV-2026-889';
    final vendorName = _nonEmpty(vendorNameOverride) ??
        _nonEmpty(auditResult.vendorName) ??
        (invoiceDoc != null
            ? _inferVendorFromFileName(invoiceDoc.fileName)
            : 'Apex Technologies Inc.');
    final clientName = _nonEmpty(clientNameOverride) ??
        _nonEmpty(auditResult.clientName) ??
        'Enterprise Finance & Procurement';
    final todayDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

    final systemPrompt =
        'You are Senior Corporate Procurement & Legal Counsel for $clientName drafting a formal, '
        'audit-backed Notice of Billing Discrepancy & Remittance Withholding addressed to $vendorName. '
        '${tone.promptDirective} '
        'Output cleanly formatted plain text / markdown ready for corporate correspondence and PDF export. '
        'Do not wrap the response in code fences.';

    final structuredJson = const JsonEncoder.withIndent('  ').convert(
      auditResult.toJson(),
    );

    final promptText = '''
Draft a formal enterprise billing dispute notice using the verified audit telemetry below:

- Date: $todayDate
- Target Vendor: $vendorName
- Client / Payor: $clientName
- Governing Contract Reference: $contractRef
- Target Invoice Reference: $invoiceRef
- Requested Tone: ${tone.label}
- Currency: ${auditResult.currency}
- Invoiced Amount: ${CurrencyFormatter.formatAmount(auditResult.invoicedTotal, currency: auditResult.currency)}
- Contract Base (Approved Payment): ${CurrencyFormatter.formatAmount(auditResult.verifiedContractBase, currency: auditResult.currency)}
- Withheld Variance: ${CurrencyFormatter.formatAmount(auditResult.totalVarianceAmount, currency: auditResult.currency)} (${auditResult.variancePercentage.toStringAsFixed(1)}%)

Audit Findings Payload:
$structuredJson

Required Sections:
1. Formal Header: Formal Notice of Billing Discrepancy & Remittance Withholding (Date, Vendor, Client, Reference Invoice #, Reference Contract/SOW #).
2. Financial Summary comparing Invoiced Amount vs Contract Base and exact Withheld Variance.
3. Itemized table/list of flagged items detailing Breach Title, Clause Reference, Invoiced Rate vs Contract Rate (if applicable), and Disputed Amount.
4. Adjusted Remittance & Tone-appropriate closing demand with mandatory 14 Business Days rectification deadline.
5. Formal Signature Block for $clientName Finance Operations & Procurement.
''';

    // Phase 1: Gemini generation with strict 8-second timeout
    try {
      final String? rawText;
      if (geminiDraftOverride != null) {
        rawText = await geminiDraftOverride!(
          ApiConstants.defaultGeminiModel,
          systemPrompt,
          promptText,
        ).timeout(llmTimeout);
      } else {
        final apiKey = await _auditService.resolveApiKey();
        rawText = await _generateWithGemini(
          apiKey: apiKey,
          systemPrompt: systemPrompt,
          promptText: promptText,
        ).timeout(llmTimeout);
      }

      final text = rawText?.trim();
      if (text != null && text.isNotEmpty) {
        return DisputeGenerationResult(
          letterText: text,
          usedFallback: false,
          engineLabel: '${ApiConstants.defaultGeminiModelShortBadge} LEGAL DRAFT',
        );
      }
    } catch (_) {
      // Timed out after 8s, API key missing, 429/503, or network error -> fall back to Groq
    }

    // Phase 2: Fast fallback generation via Groq (openai/gpt-oss-120b)
    try {
      final groqResult = await _groqService
          .generateDisputeDraft(
            systemPrompt: systemPrompt,
            userPrompt: promptText,
            temperature: 0.25,
            timeout: llmTimeout,
          )
          .timeout(llmTimeout);

      final groqText = groqResult.text.trim();
      if (groqText.isNotEmpty) {
        return DisputeGenerationResult(
          letterText: groqText,
          usedFallback: false,
          engineLabel: groqResult.engineLabel,
        );
      }
    } catch (_) {
      // Groq unavailable, unconfigured, or timed out -> fall back to deterministic template
    }

    // Phase 3: Instant deterministic template generator
    return DisputeGenerationResult(
      letterText: generateFallbackNotice(
        auditResult,
        tone,
        contractReference: contractRef,
        invoiceReference: invoiceRef,
        vendorName: vendorName,
        clientName: clientName,
      ),
      usedFallback: true,
      engineLabel: 'INSTANT TEMPLATE DRAFT',
    );
  }

  String generateFallbackNotice(
    AuditResult result,
    DisputeTone tone, {
    String? contractReference,
    String? invoiceReference,
    String? vendorName,
    String? clientName,
  }) {
    final effectiveContract = _nonEmpty(contractReference) ??
        _nonEmpty(result.contractReference) ??
        'Master_Services_Agreement_2026.pdf';
    final effectiveInvoice = _nonEmpty(invoiceReference) ??
        _nonEmpty(result.invoiceNumber) ??
        'INV-2026-889';
    final effectiveVendor = _nonEmpty(vendorName) ??
        _nonEmpty(result.vendorName) ??
        'Apex Technologies Inc.';
    final effectiveClient = _nonEmpty(clientName) ??
        _nonEmpty(result.clientName) ??
        'Enterprise Finance & Procurement';

    final todayDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final deadlineDate = DateFormat('MMMM d, yyyy').format(
      DateTime.now().add(const Duration(days: 20)),
    );
    final currency = result.currency;

    final totalInvoiced = CurrencyFormatter.formatAmount(
      result.invoicedTotal,
      currency: currency,
    );
    final approvedPayment = CurrencyFormatter.formatAmount(
      result.verifiedContractBase,
      currency: currency,
    );
    final totalWithheld = CurrencyFormatter.formatAmount(
      result.totalVarianceAmount,
      currency: currency,
    );

    final openingTone = switch (tone) {
      DisputeTone.firmLegal =>
        'Pursuant to the audit, invoicing, and compliance provisions of $effectiveContract, '
            'please accept this Formal Notice of Billing Discrepancy & Remittance Withholding '
            'regarding $effectiveInvoice. Following a contractual audit reconciliation, $effectiveClient '
            'has identified material variances requiring adjustment prior to full settlement.',
      DisputeTone.collaborativePartner =>
        'Thank you for your continued partnership under $effectiveContract. During our routine '
            'reconciliation of $effectiveInvoice, our Finance Operations team noted billing '
            'variances against our agreed commercial schedule. To ensure prompt release of the '
            'undisputed balance, we have itemized the items requiring joint clarification below.',
      DisputeTone.strictBreach =>
        'NOTICE OF MATERIAL BILLING BREACH & PAYMENT HOLD. A comprehensive compliance audit of '
            '$effectiveInvoice against $effectiveContract has uncovered unauthorized rate overcharges '
            'and direct policy violations. Payment settlement is strictly withheld for all non-compliant '
            'line items under our contractual reservation of rights.',
    };

    final closingDemand = switch (tone) {
      DisputeTone.firmLegal =>
        'Please issue a formal Credit Memo for $totalWithheld or submit a revised compliant '
            'invoice within fourteen (14) business days (Rectification Deadline: 14 Business Days - '
            'no later than $deadlineDate). If written contract amendments authorize these charges, '
            'signed documentation must be delivered prior to that deadline.\n\n'
            'All rights, audit privileges, set-offs, and contractual remedies under $effectiveContract '
            'remain expressly reserved.',
      DisputeTone.collaborativePartner =>
        'To keep our commercial account in good standing and expedite settlement, please review the '
            'schedule above and confirm the adjustments or issue an offsetting Credit Memo for '
            '$totalWithheld within fourteen (14) business days (Rectification Deadline: 14 Business Days - '
            'by $deadlineDate). Please reach out if you would like a brief reconciliation call to verify '
            'any supporting timecards or rate exhibits.',
      DisputeTone.strictBreach =>
        'MANDATORY CURE DEMAND: You are required to remediate these contractual breaches and issue '
            'an unconditional Credit Memo for $totalWithheld within fourteen (14) business days '
            '(Rectification Deadline: 14 Business Days - no later than $deadlineDate). Failure to cure '
            'within 14 Business Days will trigger formal Vendor Compliance Escalation and payment hold '
            'across pending disbursements under $effectiveContract.',
    };

    final buffer = StringBuffer()
      ..writeln('FORMAL NOTICE OF BILLING DISCREPANCY & REMITTANCE WITHHOLDING')
      ..writeln('NOTICE OF INVOICE DISCREPANCY & PAYMENT WITHHOLDING')
      ..writeln('=' * 72)
      ..writeln('Date:                   $todayDate')
      ..writeln('Vendor:                 $effectiveVendor')
      ..writeln('To:                     $effectiveVendor -- Accounts Receivable & Legal Counsel')
      ..writeln('From (Payor):           $effectiveClient')
      ..writeln('Contract Reference:     $effectiveContract')
      ..writeln('Invoice Reference:      $effectiveInvoice')
      ..writeln('Tone Profile:           ${tone.label}')
      ..writeln('Rectification Deadline: 14 Business Days ($deadlineDate)')
      ..writeln('=' * 72)
      ..writeln()
      ..writeln('Dear Billing & Account Management Team,')
      ..writeln()
      ..writeln(openingTone)
      ..writeln()
      ..writeln('1. FINANCIAL SUMMARY')
      ..writeln('-' * 72)
      ..writeln('   * Invoiced Amount:        $totalInvoiced')
      ..writeln('   * Contract Base:          $approvedPayment')
      ..writeln('   * Withheld Variance:      $totalWithheld (${result.variancePercentage.toStringAsFixed(1)}%)')
      ..writeln()
      ..writeln('2. FLAGGED DISCREPANCY ITEMS (${result.findings.length} FLAGGED)')
      ..writeln('-' * 72);

    if (result.findings.isEmpty) {
      buffer
        ..writeln('   No billing discrepancies flagged in the active audit result.')
        ..writeln();
    } else {
      for (var i = 0; i < result.findings.length; i++) {
        final f = result.findings[i];
        final variance = CurrencyFormatter.formatAmount(
          f.varianceAmount,
          currency: currency,
        );
        final rateComparison = (f.agreedRate != null && f.billedRate != null)
            ? '${CurrencyFormatter.formatAmount(f.billedRate!, currency: currency)} vs. '
                '${CurrencyFormatter.formatAmount(f.agreedRate!, currency: currency)}'
            : 'N/A (Non-Rate / ${f.category.toUpperCase()})';

        buffer
          ..writeln('${i + 1}. ${f.title} [${f.severity.toUpperCase()}]')
          ..writeln('   * Invoice Reference:            ${f.invoiceLineReference}')
          ..writeln('   * Clause Reference:             ${f.clauseReference}')
          ..writeln('   * Invoiced Rate vs Contract:    $rateComparison')
          ..writeln('   * Disputed Amount:              $variance')
          ..writeln('   * Audit Finding:                ${f.description}')
          ..writeln();
      }
    }

    buffer
      ..writeln('3. ADJUSTED PAYMENT REMITTANCE & CLOSING DEMAND')
      ..writeln('-' * 72)
      ..writeln(
        'In accordance with $effectiveContract, Accounts Payable is authorizing release of the '
        'undisputed Contract Base of $approvedPayment against Invoiced Amount $totalInvoiced. '
        'The Disputed Variance of $totalWithheld remains withheld pending rectification.',
      )
      ..writeln()
      ..writeln(closingDemand)
      ..writeln()
      ..writeln('Sincerely,')
      ..writeln()
      ..writeln('________________________________________')
      ..writeln(effectiveClient)
      ..writeln('Finance Operations & Enterprise Procurement');

    return buffer.toString();
  }

  String generateFallbackLetter({
    required AuditResult auditResult,
    required String contractReference,
    required String invoiceReference,
    required String vendorName,
    required DisputeTone tone,
  }) {
    return generateFallbackNotice(
      auditResult,
      tone,
      contractReference: contractReference,
      invoiceReference: invoiceReference,
      vendorName: vendorName,
    );
  }

  String _inferVendorFromFileName(String fileName) {
    final cleaned = fileName
        .replaceAll(
          RegExp(r'\.(pdf|docx|doc|csv|xlsx|xls)$', caseSensitive: false),
          '',
        )
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    return cleaned.isEmpty ? 'Apex Technologies Inc.' : cleaned;
  }
}

