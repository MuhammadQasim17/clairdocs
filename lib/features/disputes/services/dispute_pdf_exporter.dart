import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/currency_formatter.dart';
import '../../audit/models/audit_models.dart';
import '../models/dispute_models.dart';

class DisputePdfExporter {
  const DisputePdfExporter();

  /// Normalizes non-standard Unicode dashes (en-dash, em-dash, non-breaking
  /// hyphen \u2011, figure dash, minus), spaces, quotes, and symbols so
  /// built-in Type1 Helvetica renders cleanly without Unicode font warnings.
  static String sanitizePdfText(String input) {
    if (input.isEmpty) return input;
    return input
        // Remove soft hyphens and zero-width / directional format controls.
        .replaceAll(
          RegExp(r'[\u00AD\u200B-\u200F\u202A-\u202E\u2060\uFEFF]'),
          '',
        )
        // Normalize non-breaking and typographic whitespace to regular spaces.
        .replaceAll(
          RegExp(r'[\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]'),
          ' ',
        )
        // Replace all non-standard dashes/hyphens (including \u2011, en-dash,
        // em-dash, figure dash, horizontal bar, and minus) with '-'.
        .replaceAll(
          RegExp(
            r'[\u058A\u05BE\u1400\u1806\u2010-\u2015\u2043\u207B\u208B\u2212\u2E3A\u2E3B\uFE58\uFE63\uFF0D]',
          ),
          '-',
        )
        // Replace bullets and decorative list markers.
        .replaceAll(
          RegExp(r'[\u2022\u2023\u25AA\u25AB\u25CF\u25CB\u25E6]'),
          '-',
        )
        // Replace smart quotes and primes with ASCII equivalents.
        .replaceAll(RegExp(r'[\u2018\u2019\u201A\u201B\u2032\u2035]'), "'")
        .replaceAll(RegExp(r'[\u201C\u201D\u201E\u201F\u2033\u2036]'), '"')
        // Replace common typographic punctuation, arrows, and non-Latin1 currency.
        .replaceAll('\u2026', '...')
        .replaceAll(RegExp(r'[\u2192\u21D2\u2794]'), '->')
        .replaceAll(RegExp(r'[\u2190\u21D0]'), '<-')
        .replaceAll('\u2194', '<->')
        .replaceAll('\u2264', '<=')
        .replaceAll('\u2265', '>=')
        .replaceAll('\u2260', '!=')
        .replaceAll('\u2248', '~')
        .replaceAll('\u20AC', 'EUR ')
        .replaceAll('\u20B9', 'INR ')
        .replaceAll('\u2122', '(TM)')
        // Strip decomposed combining diacritics and any remaining code points
        // outside printable ASCII / WinAnsi Latin-1 range (\x20-\x7E, \xA0-\xFF).
        .replaceAll(RegExp(r'[\u0300-\u036F]'), '')
        .replaceAll(RegExp(r'[^\t\n\r\x20-\x7E\xA0-\xFF]'), '');
  }

  /// Strips raw technical enum tags (e.g., `[RATE_BREACH]`, `[UNAPPROVED_EXPENSE]`)
  /// and normalizes spacing before PDF text sanitization.
  static String cleanFindingText(String input) {
    final stripped = input
        .replaceAll(RegExp(r'\s*\[[A-Z]{2,}(?:_[A-Z0-9]+)+\]'), '')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
    return sanitizePdfText(stripped);
  }

  List<String> _legalRectificationParagraphs({
    required DisputeState disputeState,
    required String vendorName,
    required String clientName,
    required String contractRef,
    required String invoiceRef,
    required String invoicedStr,
    required String approvedStr,
    required String withheldStr,
    required String deadlineDate,
  }) {
    final intro =
        '$clientName hereby delivers this Formal Notice of Invoice Discrepancy & Conditional '
        'Remittance to $vendorName regarding Invoice $invoiceRef under governing Agreement '
        '$contractRef. Across $invoicedStr billed, our reconciliation verifies $approvedStr in '
        'authorized charges and places a conditional hold on $withheldStr.';

    final toneTerms = switch (disputeState.tone) {
      DisputeTone.firmLegal => [
          'In accordance with the audit, invoicing, and compliance terms of $contractRef, Accounts '
              'Payable is releasing the undisputed remittance of $approvedStr while withholding the '
              'disputed variance of $withheldStr pending formal remediation.',
          'Please issue a compliant Credit Memo for $withheldStr or submit a revised compliant '
              'invoice within fourteen (14) business days (no later than $deadlineDate). Should you '
              'assert that written contract amendments authorize these charges, signed supporting '
              'amendments must be furnished prior to that deadline. All contractual audit rights, '
              'set-offs, and legal remedies remain expressly reserved.',
        ],
      DisputeTone.collaborativePartner => [
          'To keep our commercial partnership running smoothly and prevent settlement delays, '
              'Accounts Payable has approved immediate release of the undisputed balance of '
              '$approvedStr, while placing a temporary reconciliation hold on $withheldStr.',
          'We kindly request that your billing team review the itemized findings above and either '
              'confirm an offsetting Credit Memo for $withheldStr or provide approved rate '
              'documentation within fourteen (14) business days (by $deadlineDate). Our Finance '
              'Operations desk is available for a brief commercial review call at your convenience.',
        ],
      DisputeTone.strictBreach => [
          'NOTICE OF MATERIAL BILLING BREACH & PAYMENT HOLD: Audit examination of $invoiceRef '
              'confirms unauthorized rate overcharges and unapproved charges totaling $withheldStr. '
              'Disbursement above the verified contractual base of $approvedStr is strictly suspended.',
          'MANDATORY CURE DEMAND: $vendorName is required to remediate these billing breaches and '
              'deliver an unconditional Credit Memo for $withheldStr within fourteen (14) business '
              'days (no later than $deadlineDate). Failure to cure within the 14-business-day cure '
              'period will trigger formal Vendor Compliance Escalation and suspension of pending '
              'disbursements under $contractRef.',
        ],
    };

    return [intro, ...toneTerms];
  }

  Future<Uint8List> buildDisputePdfBytes({
    required DisputeState disputeState,
  }) async {
    final doc = pw.Document(
      title: 'Formal Notice of Invoice Discrepancy & Conditional Remittance',
      author: 'ClairDocs Enterprise Workbench',
    );

    final todayDate = sanitizePdfText(
      DateFormat('MMMM d, yyyy').format(DateTime.now()),
    );
    final deadlineDate = sanitizePdfText(
      DateFormat('MMMM d, yyyy').format(
        DateTime.now().add(const Duration(days: 20)),
      ),
    );
    final currency = disputeState.currency;
    final auditResult = disputeState.sourceAuditResult;

    final invoicedStr = sanitizePdfText(
      CurrencyFormatter.formatAmount(
        disputeState.totalInvoiced,
        currency: currency,
      ),
    );
    final approvedStr = sanitizePdfText(
      CurrencyFormatter.formatAmount(
        disputeState.approvedPayment,
        currency: currency,
      ),
    );
    final withheldStr = sanitizePdfText(
      CurrencyFormatter.formatAmount(
        disputeState.totalWithheld,
        currency: currency,
      ),
    );

    final findings = auditResult?.findings ?? const <AuditFinding>[];
    final safeContractRef = sanitizePdfText(disputeState.contractReference);
    final safeInvoiceRef = sanitizePdfText(disputeState.invoiceReference);
    final safeVendorName = sanitizePdfText(disputeState.vendorName);
    final safeClientName = sanitizePdfText(disputeState.clientName);
    final safeToneLabel = sanitizePdfText(disputeState.tone.label);

    final rectificationParagraphs = _legalRectificationParagraphs(
      disputeState: disputeState,
      vendorName: safeVendorName,
      clientName: safeClientName,
      contractRef: safeContractRef,
      invoiceRef: safeInvoiceRef,
      invoicedStr: invoicedStr,
      approvedStr: approvedStr,
      withheldStr: withheldStr,
      deadlineDate: deadlineDate,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ClairDocs Enterprise Reconciliation Notice - Issued $todayDate',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          // a) Single Executive Company Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0F172A),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FORMAL NOTICE OF INVOICE DISCREPANCY & CONDITIONAL REMITTANCE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '$safeClientName  |  Tone Profile: $safeToneLabel',
                        style: const pw.TextStyle(
                          color: PdfColor.fromInt(0xFFCBD5E1),
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFDC2626),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    'WITHHOLD: $withheldStr',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // b) 2-Column Metadata Key-Value Grid
          pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFFCBD5E1),
              width: 0.6,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                ),
                children: [
                  _buildMetadataCell('DATE ISSUED', todayDate),
                  _buildMetadataCell('CONTRACT REF', safeContractRef),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildMetadataCell('VENDOR NAME', safeVendorName),
                  _buildMetadataCell('INVOICE REF', safeInvoiceRef),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                ),
                children: [
                  _buildMetadataCell('CLIENT NAME', safeClientName),
                  _buildMetadataCell(
                    'RECTIFICATION DEADLINE',
                    '14 Business Days ($deadlineDate)',
                    valueColor: const PdfColor.fromInt(0xFFB45309),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // c) Sleek 3-Metric Financial Summary Callout Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFCBD5E1),
                width: 0.75,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: _buildFinancialMetric(
                    'TOTAL INVOICED AMOUNT',
                    invoicedStr,
                  ),
                ),
                pw.Container(
                  width: 0.75,
                  height: 26,
                  color: const PdfColor.fromInt(0xFFCBD5E1),
                ),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12),
                    child: _buildFinancialMetric(
                      'APPROVED REMITTANCE (BASE)',
                      approvedStr,
                      valueColor: const PdfColor.fromInt(0xFF059669),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFEF2F2),
                      border: pw.Border.all(
                        color: const PdfColor.fromInt(0xFFFCA5A5),
                        width: 0.75,
                      ),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(3),
                      ),
                    ),
                    child: _buildFinancialMetric(
                      'WITHHELD DISPUTED AMOUNT',
                      withheldStr,
                      valueColor: const PdfColor.fromInt(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // d) Unified Discrepancy Table
          if (findings.isNotEmpty) ...[
            pw.Text(
              'ITEMIZED BILLING DISCREPANCY SCHEDULE',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF0F172A),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(
                color: const PdfColor.fromInt(0xFFCBD5E1),
                width: 0.5,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E293B),
              ),
              headerPadding: const pw.EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),
              headerAlignments: const {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
              cellStyle: const pw.TextStyle(
                fontSize: 8,
                lineSpacing: 1.4,
                color: PdfColor.fromInt(0xFF0F172A),
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 7,
              ),
              cellAlignments: const {
                0: pw.Alignment.topCenter,
                1: pw.Alignment.topLeft,
                2: pw.Alignment.topLeft,
                3: pw.Alignment.topRight,
                4: pw.Alignment.topRight,
                5: pw.Alignment.topRight,
              },
              columnWidths: const {
                0: pw.FixedColumnWidth(36),
                1: pw.FlexColumnWidth(2.75),
                2: pw.FlexColumnWidth(1.25),
                3: pw.FixedColumnWidth(64),
                4: pw.FixedColumnWidth(64),
                5: pw.FixedColumnWidth(74),
              },
              headers: const [
                'Item #',
                'Description & Finding',
                'Violated Clause',
                'Agreed Rate',
                'Billed Rate',
                'Withheld Amount',
              ],
              data: [
                for (var i = 0; i < findings.length; i++)
                  () {
                    final f = findings[i];
                    final agreedStr = f.agreedRate != null
                        ? CurrencyFormatter.formatAmount(
                            f.agreedRate!,
                            currency: currency,
                          )
                        : 'N/A';
                    final billedStr = f.billedRate != null
                        ? CurrencyFormatter.formatAmount(
                            f.billedRate!,
                            currency: currency,
                          )
                        : '--';
                    final withheldItemStr = CurrencyFormatter.formatAmount(
                      f.varianceAmount,
                      currency: currency,
                    );
                    final cleanTitle = cleanFindingText(f.title);
                    final cleanLineRef = cleanFindingText(f.invoiceLineReference);
                    final cleanDesc = cleanFindingText(f.description);
                    final cleanClause = cleanFindingText(f.clauseReference);
                    final descriptionCell = cleanLineRef.isEmpty
                        ? '$cleanTitle\n$cleanDesc'
                        : '$cleanTitle\nRef: $cleanLineRef - $cleanDesc';
                    return [
                      '#${(i + 1).toString().padLeft(2, '0')}',
                      descriptionCell,
                      cleanClause,
                      agreedStr,
                      billedStr,
                      withheldItemStr,
                    ].map(sanitizePdfText).toList();
                  }(),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // e) Formal Legal Rectification Terms
          pw.Text(
            'FORMAL LEGAL RECTIFICATION TERMS',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF0F172A),
            ),
          ),
          pw.SizedBox(height: 6),
          for (final para in rectificationParagraphs)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Text(
                sanitizePdfText(para),
                style: const pw.TextStyle(
                  fontSize: 9,
                  lineSpacing: 2.2,
                  color: PdfColor.fromInt(0xFF1E293B),
                ),
              ),
            ),

          pw.SizedBox(height: 18),

          // f) Single Dual-Signature Execution Block
          pw.Wrap(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(
                      color: PdfColor.fromInt(0xFFCBD5E1),
                      width: 0.75,
                    ),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'AUTHORIZED PAYOR SIGN-OFF',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 22),
                          pw.Container(
                            width: 210,
                            height: 1,
                            color: PdfColors.grey500,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            safeClientName,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF0F172A),
                            ),
                          ),
                          pw.Text(
                            'Finance Operations & Procurement Desk  |  Date: $todayDate',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'VENDOR RECEIPT & ACKNOWLEDGMENT',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 22),
                          pw.Container(
                            width: 210,
                            height: 1,
                            color: PdfColors.grey500,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            safeVendorName,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF0F172A),
                            ),
                          ),
                          pw.Text(
                            'Authorized Representative & Date Signed',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildMetadataCell(
    String label,
    String value, {
    PdfColor valueColor = const PdfColor.fromInt(0xFF0F172A),
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 105,
            child: pw.Text(
              sanitizePdfText(label),
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              sanitizePdfText(value),
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialMetric(
    String label,
    String value, {
    PdfColor valueColor = const PdfColor.fromInt(0xFF0F172A),
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          sanitizePdfText(label),
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          sanitizePdfText(value),
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<Uri?> exportAndSavePdf({
    required DisputeState disputeState,
  }) async {
    final pdfBytes = await buildDisputePdfBytes(disputeState: disputeState);
    final sanitizedInvoice = disputeState.invoiceReference
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'ClairDocs_Dispute_Notice_$sanitizedInvoice.pdf';

    return FilePicker.saveFile(
      dialogTitle: 'Export Formal Dispute Notice PDF',
      fileName: fileName,
      bytes: pdfBytes,
      mimeType: 'application/pdf',
    );
  }
}
