import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mailer/mailer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:clairdocs/app.dart';
import 'package:clairdocs/core/constants/api_constants.dart';
import 'package:clairdocs/core/constants/app_strings.dart';
import 'package:clairdocs/core/errors/exceptions.dart';
import 'package:clairdocs/core/security/secure_storage_service.dart';
import 'package:clairdocs/core/theme/app_colors.dart';
import 'package:clairdocs/core/utils/document_file_helper.dart';
import 'package:clairdocs/core/widgets/clair_logo_badge.dart';
import 'package:clairdocs/core/widgets/clair_pdf_viewer.dart';
import 'package:clairdocs/core/widgets/document_pane_header.dart';
import 'package:clairdocs/core/widgets/selectable_audit_card.dart';
import 'package:clairdocs/core/widgets/word_document_preview.dart';
import 'package:clairdocs/features/analytics/models/analytics_summary.dart';
import 'package:clairdocs/features/analytics/presentation/analytics_dashboard_screen.dart';
import 'package:clairdocs/features/audit/models/audit_models.dart';
import 'package:clairdocs/features/audit/presentation/widgets/action_studio_panel.dart';
import 'package:clairdocs/features/audit/presentation/widgets/api_key_dialog.dart';
import 'package:clairdocs/features/audit/presentation/widgets/discrepancy_item_card.dart';
import 'package:clairdocs/features/audit/presentation/widgets/document_viewer_pane.dart';
import 'package:clairdocs/features/audit/presentation/widgets/rate_comparison_card.dart';
import 'package:clairdocs/features/audit/presentation/widgets/settings_dialog.dart';
import 'package:clairdocs/features/audit/presentation/widgets/top_command_bar.dart';
import 'package:clairdocs/features/audit/providers/audit_provider.dart';
import 'package:clairdocs/features/audit/services/gemini_audit_service.dart';
import 'package:clairdocs/features/audit/services/groq_audit_service.dart';
import 'package:clairdocs/features/audit/services/pdf_extraction_service.dart';
import 'package:clairdocs/features/contracts/presentation/widgets/contract_viewer_panel.dart';
import 'package:clairdocs/features/contracts/providers/contract_providers.dart';
import 'package:clairdocs/features/disputes/models/dispute_models.dart';
import 'package:clairdocs/features/disputes/presentation/widgets/dispatch_notice_dialog.dart';
import 'package:clairdocs/features/disputes/presentation/widgets/dispute_studio_modal.dart';
import 'package:clairdocs/features/disputes/providers/dispute_provider.dart';
import 'package:clairdocs/features/disputes/services/dispute_dispatch_service.dart';
import 'package:clairdocs/features/disputes/services/dispute_generator_service.dart';
import 'package:clairdocs/features/disputes/services/dispute_pdf_exporter.dart';
import 'package:clairdocs/features/history/models/audit_record.dart';
import 'package:clairdocs/features/history/presentation/widgets/audit_vault_dialog.dart';
import 'package:clairdocs/features/history/providers/audit_history_provider.dart';
import 'package:clairdocs/features/history/services/audit_database_service.dart';
import 'package:clairdocs/features/invoices/models/invoice_document.dart';
import 'package:clairdocs/features/invoices/presentation/widgets/invoice_viewer_panel.dart';
import 'package:clairdocs/features/invoices/providers/invoice_providers.dart';
import 'package:clairdocs/features/splash/splash_screen.dart';

class _FixedEngineAuditNotifier extends AuditNotifier {
  @override
  FutureOr<AuditResult?> build() => null;

  @override
  Future<void> runAudit() async {
    state = AsyncData(
      AuditResult.demoSample().copyWith(
        auditEngine: ApiConstants.groqEngineLabel,
      ),
    );
  }
}

class _OfflineMockAuditService extends GeminiAuditService {
  _OfflineMockAuditService({super.pdfExtractor, super.groqService});

  @override
  Future<String> resolveApiKey() async {
    throw const ApiKeyMissingException('Test offline mode');
  }
}

typedef _OfflineMockAuditServiceWithGroq = _OfflineMockAuditService;

class _OfflineMockGroqService extends GroqAuditService {
  @override
  Future<String> resolveApiKey() async {
    throw const ApiKeyMissingException('Test offline Groq mode');
  }
}

class _RecordingPdfViewerController extends PdfViewerController {
  final List<String> searchedQueries = <String>[];

  @override
  PdfTextSearchResult searchText(
    String searchText, {
    TextSearchOption? searchOption,
  }) {
    searchedQueries.add(searchText);
    return super.searchText(searchText, searchOption: searchOption);
  }
}

class _InMemoryAuditDatabaseService extends AuditDatabaseService {
  final List<AuditRecord> _records = <AuditRecord>[];

  @override
  Future<void> saveAuditRecord(AuditRecord record) async {
    _records.removeWhere((r) => r.id == record.id);
    _records.insert(0, record);
  }

  @override
  Future<List<AuditRecord>> fetchAllAudits() async {
    final sorted = List<AuditRecord>.from(_records)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  @override
  Future<void> deleteAuditRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> close() async {}
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('GeminiAuditService resolves API key from dotenv and falls back to in-app key', () async {
    dotenv.loadFromString(envString: 'GEMINI_API_KEY=dotenv_test_key_123');
    final serviceFromDotEnv = GeminiAuditService(
      inAppKeyReader: () => 'in_app_fallback_key',
    );
    expect(await serviceFromDotEnv.resolveApiKey(), equals('dotenv_test_key_123'));

    dotenv.clean();
    final serviceFromInApp = GeminiAuditService(
      inAppKeyReader: () => 'in_app_fallback_key',
    );
    expect(await serviceFromInApp.resolveApiKey(), equals('in_app_fallback_key'));
  });

  test('GeminiAuditService handles 429 rate limits with retry status and friendly exhaustion error', () async {
    final recordedDelays = <int>[];
    final recordedStatuses = <String>[];

    final service = GeminiAuditService(
      delayFn: (d) async => recordedDelays.add(d.inSeconds),
    );

    // 1. Recovers on 3rd attempt after two 429 failures
    var attempts = 0;
    final recovered = await service.executeWithRateLimitRetry(
      () async {
        attempts++;
        if (attempts == 1) {
          throw Exception('429 Quota exceeded. Please retry in 6.2s.');
        }
        if (attempts == 2) {
          throw Exception('RESOURCE_EXHAUSTED: rate limit exceeded');
        }
        return '{"ok": true}';
      },
      onRetryStatus: recordedStatuses.add,
    );

    expect(recovered, equals('{"ok": true}'));
    expect(attempts, equals(3));
    expect(recordedDelays, equals([7, 8]));
    expect(
      recordedStatuses,
      equals([
        'Rate limit reached. Retrying automatically in 7 seconds...',
        'Rate limit reached. Retrying automatically in 8 seconds...',
      ]),
    );

    // 2. Exhausts all 3 retries and throws GeminiRateLimitException
    recordedDelays.clear();
    await expectLater(
      () => service.executeWithRateLimitRetry(
        () async => throw Exception('Quota exceeded: limit: 5 (429)'),
      ),
      throwsA(
        isA<GeminiRateLimitException>().having(
          (e) => e.message,
          'message',
          contains('AI Studio Free Tier Limit Reached (5 requests/min)'),
        ),
      ),
    );
    expect(recordedDelays, equals([4, 8]));
  });

  test('GeminiAuditService retries 503 high demand and falls back to gemini-3.5-flash-lite', () async {
    final recordedDelays = <int>[];
    final recordedModels = <String>[];
    final recordedStatuses = <String>[];

    final service = GeminiAuditService(
      delayFn: (d) async => recordedDelays.add(d.inSeconds),
    );

    // 1. Primary model fails 503 across 2 retries, then fallback gemini-3.5-flash-lite succeeds
    final result = await service.executeWithModelFallback(
      (modelId) async {
        recordedModels.add(modelId);
        if (modelId == 'gemini-3.8-flash') {
          throw Exception(
            '503 This model is currently experiencing high demand. Spikes in demand are usually temporary.',
          );
        }
        return '{"fallback_model": "$modelId"}';
      },
      onRetryStatus: recordedStatuses.add,
    );

    expect(result, equals('{"fallback_model": "gemini-3.5-flash-lite"}'));
    expect(
      recordedModels,
      equals([
        'gemini-3.8-flash',
        'gemini-3.8-flash',
        'gemini-3.8-flash',
        'gemini-3.5-flash-lite',
      ]),
    );
    expect(recordedDelays, equals([2, 4]));
    expect(
      recordedStatuses,
      containsAllInOrder([
        'Google AI servers busy, retrying in 2s...',
        'Google AI servers busy, retrying in 4s...',
        'Servers busy on gemini-3.8-flash. Switching to fallback gemini-3.5-flash-lite...',
      ]),
    );

    // 2. All models fail with 503 -> throws GeminiServerBusyException
    await expectLater(
      () => service.executeWithModelFallback(
        (_) async => throw Exception('503 Service Unavailable'),
      ),
      throwsA(
        isA<GeminiServerBusyException>().having(
          (e) => e.message,
          'message',
          equals(
            'Google AI servers are experiencing temporary high demand (503). Please wait 30 seconds and tap Retry Audit.',
          ),
        ),
      ),
    );
  });

  test('PdfExtractionService offloads PDF parsing to compute isolate with 5s timeout fallback', () async {
    expect(PdfExtractionService.defaultPdfTimeout, equals(const Duration(seconds: 5)));

    final pdfDoc = PdfDocument();
    final page = pdfDoc.pages.add();
    page.graphics.drawString(
      'Section 4.2: Lead Cloud Architect rate cap is USD 185/hr.',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );
    final bytes = Uint8List.fromList(await pdfDoc.save());
    pdfDoc.dispose();

    final tempDir = await Directory.systemTemp.createTemp('clairdocs_pdf_iso_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final pdfFile = File('${tempDir.path}${Platform.pathSeparator}contract.pdf');
    await pdfFile.writeAsBytes(bytes);

    const extractor = PdfExtractionService();
    final syncExtracted = extractor.extractTextFromBytes(bytes);
    expect(syncExtracted, contains('--- Page 1 ---'));
    expect(syncExtracted, contains('Section 4.2: Lead Cloud Architect rate cap is USD 185/hr.'));

    // Real background isolate execution via compute()
    final isoExtracted = await extractor.extractTextFromPdf(pdfFile);
    expect(isoExtracted, contains('--- Page 1 ---'));
    expect(isoExtracted, contains('Section 4.2: Lead Cloud Architect rate cap is USD 185/hr.'));

    // Timeout fallback returns controlled string and audit pipeline still proceeds cleanly
    final stallingExtractor = PdfExtractionService(
      pdfTimeout: const Duration(milliseconds: 25),
      pdfIsolateRunner: (_) => Completer<String>().future,
    );
    final timedOutResult = await stallingExtractor.extractTextFromPdf(pdfFile);
    expect(timedOutResult, equals('Error: Text extraction timed out.'));
    expect(PdfExtractionService.isExtractionFailureOrEmpty(timedOutResult), isTrue);

    dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_test_pdf_fallback');
    addTearDown(dotenv.clean);

    String? capturedUserPrompt;
    final statuses = <String>[];
    final mockGroqClient = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = payload['messages'] as List<dynamic>;
      capturedUserPrompt = (messages[1] as Map<String, dynamic>)['content'] as String?;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode(AuditResult.demoSample().toJson()),
              },
            },
          ],
        }),
        200,
      );
    });

    final fallbackService = _OfflineMockAuditServiceWithGroq(
      pdfExtractor: stallingExtractor,
      groqService: GroqAuditService(httpClient: mockGroqClient),
    );

    final fallbackAudit = await fallbackService.auditDocuments(
      contractFile: pdfFile,
      invoiceFile: pdfFile,
      onRetryStatus: statuses.add,
    );

    expect(
      statuses,
      containsAllInOrder([
        'Extracting text locally from documents...',
        'Auditing with Gemini 3.8 / Groq...',
      ]),
    );
    expect(capturedUserPrompt, contains('[Document Descriptor Fallback]'));
    expect(capturedUserPrompt, contains('Error: Text extraction timed out.'));
    expect(fallbackAudit.auditEngine, equals('Engine: GPT-OSS 20B (Groq)'));
  });

  test('PdfExtractionService extracts .docx word/document.xml and feeds audit pipeline', () async {
    expect(
      DocumentFileHelper.supportedExtensions,
      containsAllInOrder(['pdf', 'docx', 'doc', 'csv', 'xlsx', 'xls']),
    );
    expect(DocumentFileHelper.isSupportedExtension('SOW_2026.DOCX'), isTrue);
    expect(DocumentFileHelper.isSupportedExtension('Invoice_2026.doc'), isTrue);
    expect(DocumentFileHelper.isSupportedExtension('Invoice_Lines.CSV'), isTrue);
    expect(DocumentFileHelper.isSupportedExtension('Rate_Card.xlsx'), isTrue);
    expect(DocumentFileHelper.isSupportedExtension('Legacy_Billing.xls'), isTrue);
    expect(DocumentFileHelper.isSupportedExtension('malware.exe'), isFalse);

    Uint8List buildDocxBytes(String bodyXml) {
      final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $bodyXml
  </w:body>
</w:document>''';
      final archive = Archive()
        ..addFile(ArchiveFile.string('word/document.xml', documentXml));
      return Uint8List.fromList(ZipEncoder().encode(archive));
    }

    final contractDocx = buildDocxBytes('''
      <w:p><w:r><w:t>Section 4.2: Lead Architect ceiling is \$185/hr.</w:t></w:r></w:p>
      <w:tbl>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Role</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>Rate Cap</w:t></w:r></w:p></w:tc>
        </w:tr>
        <w:tr>
          <w:tc><w:p><w:r><w:t>Lead Cloud Architect</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:r><w:t>\$185.00</w:t></w:r></w:p></w:tc>
        </w:tr>
      </w:tbl>
    ''');

    final invoiceDocx = buildDocxBytes('''
      <w:p><w:r><w:t>Line Item #01: Lead Cloud Architect billed at \$210/hr.</w:t></w:r></w:p>
    ''');

    final tempDir = await Directory.systemTemp.createTemp('clairdocs_docx_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final contractFile = File('${tempDir.path}${Platform.pathSeparator}contract.docx');
    final invoiceFile = File('${tempDir.path}${Platform.pathSeparator}invoice.docx');
    await contractFile.writeAsBytes(contractDocx);
    await invoiceFile.writeAsBytes(invoiceDocx);

    const extractor = PdfExtractionService();
    final extractedContract = await extractor.extractTextFromFile(contractFile);
    expect(extractedContract, contains('Section 4.2: Lead Architect ceiling is \$185/hr.'));
    expect(extractedContract, contains('Lead Cloud Architect | \$185.00'));

    // Feed .docx contract + .docx invoice seamlessly through GeminiAuditService -> Groq pipeline
    dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_test_docx_audit');
    addTearDown(dotenv.clean);

    String? capturedUserPrompt;
    final mockGroqClient = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = payload['messages'] as List<dynamic>;
      capturedUserPrompt = (messages[1] as Map<String, dynamic>)['content'] as String?;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode(AuditResult.demoSample().toJson()),
              },
            },
          ],
        }),
        200,
      );
    });

    final offlineGeminiWithGroq = _OfflineMockAuditServiceWithGroq(
      groqService: GroqAuditService(httpClient: mockGroqClient),
    );

    final auditResult = await offlineGeminiWithGroq.auditDocuments(
      contractFile: contractFile,
      invoiceFile: invoiceFile,
    );

    expect(
      capturedUserPrompt,
      contains('Lead Cloud Architect | \$185.00'),
    );
    expect(
      capturedUserPrompt,
      contains('Line Item #01: Lead Cloud Architect billed at \$210/hr.'),
    );
    expect(auditResult.auditEngine, equals('Engine: GPT-OSS 20B (Groq)'));
  });

  test('PdfExtractionService.extractDocumentText parses .csv and .xlsx tables for LLM audit', () async {
    const extractor = PdfExtractionService();

    final tempDir = await Directory.systemTemp.createTemp('clairdocs_sheet_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // 1. Test .csv ingestion (with \n line endings & currency values)
    final csvFile = File('${tempDir.path}${Platform.pathSeparator}invoice_lines.csv');
    await csvFile.writeAsString(
      'Description,Hours,Billed Rate,Total\n'
      'Lead Cloud Architect,120,"\$210.00","\$25,200.00"\n'
      'Cloud Architect,80,"\$175.00","\$14,000.00"\n',
    );

    final csvTable = await extractor.extractDocumentText(csvFile);
    expect(
      csvTable,
      contains('Description | Hours | Billed Rate | Total'),
    );
    expect(
      csvTable,
      contains('Lead Cloud Architect | 120 | \$210.00 | \$25,200.00'),
    );

    // 2. Test .xlsx OpenXML workbook ingestion (workbook.xml + rels + sharedStrings + sheet1.xml)
    final workbookXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Invoice Lines" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';
    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Target="worksheets/sheet1.xml"/>
</Relationships>''';
    const sharedStringsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="5" uniqueCount="5">
  <si><t>Description</t></si>
  <si><t>Hours</t></si>
  <si><t>Billed Rate</t></si>
  <si><t>Total</t></si>
  <si><t>Senior DevOps Engineer</t></si>
</sst>''';
    const sheet1Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="1">
      <c r="A1" t="s"><v>0</v></c>
      <c r="B1" t="s"><v>1</v></c>
      <c r="C1" t="s"><v>2</v></c>
      <c r="D1" t="s"><v>3</v></c>
    </row>
    <row r="2">
      <c r="A2" t="s"><v>4</v></c>
      <c r="B2"><v>80</v></c>
      <c r="C2"><v>195</v></c>
      <c r="D2"><v>15600</v></c>
    </row>
  </sheetData>
</worksheet>''';

    final xlsxArchive = Archive()
      ..addFile(ArchiveFile.string('xl/workbook.xml', workbookXml))
      ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', relsXml))
      ..addFile(ArchiveFile.string('xl/sharedStrings.xml', sharedStringsXml))
      ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', sheet1Xml));
    final xlsxBytes = Uint8List.fromList(ZipEncoder().encode(xlsxArchive));

    final xlsxFile = File('${tempDir.path}${Platform.pathSeparator}invoice_lines.xlsx');
    await xlsxFile.writeAsBytes(xlsxBytes);

    final xlsxTable = await extractor.extractDocumentText(xlsxFile);
    expect(xlsxTable, contains('=== Sheet: Invoice Lines ==='));
    expect(xlsxTable, contains('Description | Hours | Billed Rate | Total'));
    expect(xlsxTable, contains('Senior DevOps Engineer | 80 | 195 | 15600'));

    // 3. Feed spreadsheet invoice into audit pipeline with "Invoice Spreadsheet Data:" label
    final contractPdfDoc = PdfDocument();
    contractPdfDoc.pages.add().graphics.drawString(
      'Section 4.2: Senior DevOps Engineer cap USD 165/hr.',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );
    final contractPdfFile = File('${tempDir.path}${Platform.pathSeparator}contract.pdf');
    await contractPdfFile.writeAsBytes(await contractPdfDoc.save());
    contractPdfDoc.dispose();

    dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_test_xlsx_audit');
    addTearDown(dotenv.clean);

    String? capturedUserPrompt;
    final mockGroqClient = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = payload['messages'] as List<dynamic>;
      capturedUserPrompt = (messages[1] as Map<String, dynamic>)['content'] as String?;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode(AuditResult.demoSample().toJson()),
              },
            },
          ],
        }),
        200,
      );
    });

    final hybridService = _OfflineMockAuditServiceWithGroq(
      groqService: GroqAuditService(httpClient: mockGroqClient),
    );

    final result = await hybridService.auditDocuments(
      contractFile: contractPdfFile,
      invoiceFile: xlsxFile,
    );

    expect(
      capturedUserPrompt,
      contains('Invoice Spreadsheet Data:\n=== Sheet: Invoice Lines ==='),
    );
    expect(
      capturedUserPrompt,
      contains('Senior DevOps Engineer | 80 | 195 | 15600'),
    );
    expect(result.auditEngine, equals('Engine: GPT-OSS 20B (Groq)'));
  });

  test('GroqAuditService calls openai/gpt-oss-20b with 1500 max_tokens and truncates to 12000 chars', () async {
    expect(ApiConstants.geminiAuditTimeout, equals(const Duration(seconds: 8)));
    expect(ApiConstants.geminiSlowStatusDelay, equals(const Duration(seconds: 4)));
    expect(ApiConstants.groqAuditTimeout, equals(const Duration(seconds: 10)));

    dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_test_groq_key');
    addTearDown(dotenv.clean);

    final longContract = 'A' * 15000;
    final mockAuditJson = AuditResult.demoSample().toJson();
    final mockClient = MockClient((request) async {
      expect(
        request.url.toString(),
        equals('https://api.groq.com/openai/v1/chat/completions'),
      );
      expect(request.headers['Authorization'], equals('Bearer gsk_test_groq_key'));

      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['model'], equals('openai/gpt-oss-20b'));
      expect(payload['temperature'], equals(0.1));
      expect(payload['max_tokens'], equals(1500));
      expect(payload['response_format'], equals({'type': 'json_object'}));

      final messages = payload['messages'] as List<dynamic>;
      final userMessage = (messages[1] as Map<String, dynamic>)['content'] as String;
      // Contract text truncated strictly at first 12,000 characters
      expect(userMessage, contains('Contract Document Text:\n${'A' * 12000}\n\nVendor Invoice Text:'));
      expect(userMessage, isNot(contains('A' * 12001)));

      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode(mockAuditJson),
              },
            },
          ],
        }),
        200,
      );
    });

    final groqService = GroqAuditService(httpClient: mockClient);
    final result = await groqService.auditDocuments(
      contractText: longContract,
      invoiceText: 'Invoice line items text',
    );

    expect(result.auditEngine, equals('Engine: GPT-OSS 20B (Groq)'));
    expect(result.totalVarianceAmount, equals(4850.00));
    expect(result.findings.length, equals(3));

    // Verify automatic fallback from openai/gpt-oss-20b (404) to openai/gpt-oss-120b
    final attemptedModels = <String>[];
    final fallbackClient = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final model = payload['model'] as String;
      attemptedModels.add(model);

      if (model == 'openai/gpt-oss-20b') {
        return http.Response(
          '{"error":{"message":"Model not found"}}',
          404,
        );
      }

      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode(mockAuditJson),
              },
            },
          ],
        }),
        200,
      );
    });

    final fallbackService = GroqAuditService(httpClient: fallbackClient);
    final fallbackResult = await fallbackService.auditDocuments(
      contractText: 'Contract clause text',
      invoiceText: 'Invoice line items text',
    );

    expect(attemptedModels, equals(['openai/gpt-oss-20b', 'openai/gpt-oss-120b']));
    expect(fallbackResult.auditEngine, equals('Engine: GPT-OSS 120B (Groq)'));
  });

  test('GeminiAuditService warns at 4s, times out at 8s, and fails over immediately to Groq 20B', () async {
    dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_test_failover');
    addTearDown(dotenv.clean);

    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode(AuditResult.demoSample().toJson()),
              },
            },
          ],
        }),
        200,
      );
    });

    // 1. Slow/hanging Gemini triggers slow-status update then times out cleanly into Groq 20B
    final slowStatuses = <String>[];
    final slowHybridService = GeminiAuditService(
      groqService: GroqAuditService(httpClient: mockClient),
      geminiSlowStatusDelay: const Duration(milliseconds: 15),
      geminiRequestTimeout: const Duration(milliseconds: 50),
    );

    final slowResult = await slowHybridService.executeHybridAudit(
      contractText: 'Contract text',
      invoiceText: 'Invoice text',
      onRetryStatus: slowStatuses.add,
      geminiPhaseFn: () => Completer<({String? text, String modelId})>().future,
    );

    expect(slowResult.auditEngine, equals('Engine: GPT-OSS 20B (Groq)'));
    expect(slowStatuses, contains('Routing to Groq ultra-fast engine...'));

    // 2. Primary Gemini hits 429 -> instant failover to Engine: GPT-OSS 20B (Groq)
    final rateLimitStatuses = <String>[];
    final hybridService = GeminiAuditService(
      groqService: GroqAuditService(httpClient: mockClient),
    );

    final result = await hybridService.executeHybridAudit(
      contractText: 'Contract text',
      invoiceText: 'Invoice text',
      onRetryStatus: rateLimitStatuses.add,
      geminiPhaseFn: () async => throw const GeminiRateLimitException(),
    );

    expect(result.auditEngine, equals('Engine: GPT-OSS 20B (Groq)'));
    expect(rateLimitStatuses, contains('Routing to Groq ultra-fast engine...'));

    // 3. Both Gemini and Groq fail -> throws DualEngineAuditException
    final failingHybrid = GeminiAuditService(
      groqService: GroqAuditService(
        httpClient: MockClient((_) async => http.Response('{"error":{"message":"Groq down"}}', 500)),
      ),
    );

    await expectLater(
      () => failingHybrid.executeHybridAudit(
        contractText: 'Contract text',
        invoiceText: 'Invoice text',
        geminiPhaseFn: () async => throw const GeminiServerBusyException(),
      ),
      throwsA(
        isA<DualEngineAuditException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('Both AI audit engines failed'),
            contains('Gemini (gemini-3.8-flash)'),
            contains('Groq (openai/gpt-oss-20b)'),
          ),
        ),
      ),
    );
  });

  test('AuditResult and AuditFinding JSON serialization round-trip', () {
    final original = AuditResult.demoSample();
    final json = original.toJson();
    final deserialized = AuditResult.fromJson(json);

    expect(deserialized.currency, equals('USD'));
    expect(deserialized.totalVarianceAmount, equals(4850.00));
    expect(deserialized.invoicedTotal, equals(48250.00));
    expect(deserialized.verifiedContractBase, equals(43400.00));
    expect(deserialized.findings.length, equals(3));
    expect(deserialized.findings.first.agreedRate, equals(185.00));
    expect(deserialized.findings.first.billedRate, equals(210.00));
  });

  test('DisputeGeneratorService timeout -> Groq openai/gpt-oss-120b -> deterministic generateFallbackNotice', () async {
    expect(DisputeGeneratorService.defaultLlmTimeout, equals(const Duration(seconds: 8)));

    dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_test_dispute_key');
    addTearDown(dotenv.clean);

    final audit = AuditResult.demoSample();

    // 1. Verify deterministic generateFallbackNotice across tones
    final templateGen = DisputeGeneratorService();
    final firmNotice = templateGen.generateFallbackNotice(audit, DisputeTone.firmLegal);
    expect(firmNotice, contains('FORMAL NOTICE OF BILLING DISCREPANCY & REMITTANCE WITHHOLDING'));
    expect(firmNotice, contains('Apex Technologies Inc.'));
    expect(firmNotice, contains('\$48,250.00'));
    expect(firmNotice, contains('\$43,400.00'));
    expect(firmNotice, contains('\$4,850.00'));
    expect(firmNotice, contains('\$210.00 vs. \$185.00'));
    expect(firmNotice, contains('14 Business Days'));
    expect(firmNotice, contains('Section 4.2'));

    final partnerNotice = templateGen.generateFallbackNotice(audit, DisputeTone.collaborativePartner);
    expect(partnerNotice, contains('reconciliation call'));

    final strictNotice = templateGen.generateFallbackNotice(audit, DisputeTone.strictBreach);
    expect(strictNotice, contains('MANDATORY CURE DEMAND'));

    // 2. Gemini hangs past timeout -> falls back immediately to Groq openai/gpt-oss-120b
    String? requestedGroqModel;
    final groqMockClient = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      requestedGroqModel = payload['model'] as String?;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': 'GROQ GENERATED FORMAL DISPUTE LETTER',
              },
            },
          ],
        }),
        200,
      );
    });

    final timeoutToGroqService = DisputeGeneratorService(
      groqService: GroqAuditService(httpClient: groqMockClient),
      llmTimeout: const Duration(milliseconds: 25),
      geminiDraftOverride: (_, _, _) => Completer<String?>().future,
    );

    final groqDraftResult = await timeoutToGroqService.generateDisputeNotice(
      auditResult: audit,
      tone: DisputeTone.firmLegal,
    );

    expect(requestedGroqModel, equals('openai/gpt-oss-120b'));
    expect(groqDraftResult.usedFallback, isFalse);
    expect(groqDraftResult.engineLabel, equals('Engine: GPT-OSS 120B (Groq)'));
    expect(groqDraftResult.letterText, equals('GROQ GENERATED FORMAL DISPUTE LETTER'));

    // 3. Both Gemini timeout AND Groq failure -> instant deterministic fallback notice
    final failingGroqClient = MockClient(
      (_) async => http.Response('{"error":{"message":"Groq unavailable"}}', 503),
    );
    final dualFallbackService = DisputeGeneratorService(
      groqService: GroqAuditService(httpClient: failingGroqClient),
      llmTimeout: const Duration(milliseconds: 25),
      geminiDraftOverride: (_, _, _) => Completer<String?>().future,
    );

    final fallbackDraftResult = await dualFallbackService.generateDisputeNotice(
      auditResult: audit,
      tone: DisputeTone.strictBreach,
    );

    expect(fallbackDraftResult.usedFallback, isTrue);
    expect(fallbackDraftResult.engineLabel, equals('INSTANT TEMPLATE DRAFT'));
    expect(fallbackDraftResult.letterText, contains('MATERIAL BILLING BREACH'));
    expect(fallbackDraftResult.letterText, contains('14 Business Days'));
  });

  test('PdfExtractionService.extractPartyMetadata extracts real Vendor/Client/Refs over filename', () async {
    const contractText = '''
MASTER SERVICES AGREEMENT
Contract Reference: MSA-2026-CS
Client: Northstar Retail Corp
Vendor: CloudScale Solutions LLC
Section 4.2: Cloud Architect cap USD 185/hr.
''';
    const invoiceText = '''
CloudScale Solutions LLC
1200 Cloud Way, Austin TX
Bill To: Northstar Retail Corp
Invoice #: INV-902
Line 1: Cloud Architect - 100 hrs @ \$210.00 = \$21,000.00
''';

    final meta = PdfExtractionService.extractPartyMetadata(
      contractText: contractText,
      invoiceText: invoiceText,
    );
    expect(meta.vendorName, equals('CloudScale Solutions LLC'));
    expect(meta.clientName, equals('Northstar Retail Corp'));
    expect(meta.invoiceNumber, equals('INV-902'));
    expect(meta.contractReference, equals('MSA-2026-CS'));

    // Also verify filenames echoed by LLM are overridden by real header metadata
    dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_test_party_meta');
    addTearDown(dotenv.clean);

    final jsonWithFilenameEcho = AuditResult.demoSample().toJson()
      ..['vendorName'] = 'Tech_Invoice_INV902.pdf'
      ..['clientName'] = null
      ..['invoiceNumber'] = null
      ..['contractReference'] = null;
    final mockClient = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': jsonEncode(jsonWithFilenameEcho)},
            },
          ],
        }),
        200,
      );
    });

    final hybrid = GeminiAuditService(
      groqService: GroqAuditService(httpClient: mockClient),
    );
    final result = await hybrid.executeHybridAudit(
      contractText: contractText,
      invoiceText: invoiceText,
      geminiPhaseFn: () async => throw const GeminiRateLimitException(),
    );

    expect(result.vendorName, equals('CloudScale Solutions LLC'));
    expect(result.clientName, equals('Northstar Retail Corp'));
    expect(result.invoiceNumber, equals('INV-902'));
    expect(result.contractReference, equals('MSA-2026-CS'));
  });

  test('DisputeGeneratorService fallback & DisputePdfExporter compile valid PDF', () async {
    final audit = AuditResult.demoSample();
    final generator = DisputeGeneratorService();

    final letter = generator.generateFallbackLetter(
      auditResult: audit,
      contractReference: 'MSA_2026.pdf',
      invoiceReference: 'INV-2026-889.pdf',
      vendorName: 'CloudScale Solutions LLC',
      tone: DisputeTone.firmLegal,
    );

    expect(letter, contains('NOTICE OF INVOICE DISCREPANCY & PAYMENT WITHHOLDING'));
    expect(letter, contains('CloudScale Solutions LLC'));
    expect(letter, contains('\$48,250.00'));
    expect(letter, contains('\$43,400.00'));
    expect(letter, contains('\$4,850.00'));
    expect(letter, contains('fourteen (14) business days'));

    final state = DisputeState(
      status: DisputeGenerationStatus.ready,
      tone: DisputeTone.firmLegal,
      draftText: letter,
      vendorName: 'CloudScale Solutions LLC',
      clientName: 'Northstar Retail Corp',
      invoiceReference: 'INV-902',
      contractReference: 'MSA-2026-CS',
      totalWithheld: audit.totalVarianceAmount,
      totalInvoiced: audit.invoicedTotal,
      approvedPayment: audit.verifiedContractBase,
      currency: audit.currency,
      sourceAuditResult: audit,
    );

    const exporter = DisputePdfExporter();
    final pdfBytes = await exporter.buildDisputePdfBytes(disputeState: state);

    expect(pdfBytes.length, greaterThan(1000));
    // Verify PDF magic header %PDF-
    expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
  });

  test(
    'DisputePdfExporter normalizes Unicode dashes and prevents font-fallback warnings',
    () async {
      // 1. Direct unit checks for dash variants (\u2010-\u2015, \u2212), spaces,
      // smart punctuation, non-Latin1 currency symbols, and emojis.
      const rawInput =
          'INV\u2011902 \u2013 MSA\u20142026 \u2010 Fee\u2012Plan\u2015A \u2212 \$50\u00A0•\u200B '
          '“Quoted” \u2018Item\u2019 \u2192 Clause\u2026 €1,500 ✓';
      expect(
        DisputePdfExporter.sanitizePdfText(rawInput),
        equals(
          'INV-902 - MSA-2026 - Fee-Plan-A - \$50 - '
          '"Quoted" \'Item\' -> Clause... EUR 1,500 ',
        ),
      );

      // 2. Compile a full PDF populated with non-standard Unicode characters
      // across party names, refs, findings, and EUR currency metrics.
      const unicodeAudit = AuditResult(
        currency: 'EUR',
        totalVarianceAmount: 1500.0,
        invoicedTotal: 2500.0,
        verifiedContractBase: 1000.0,
        variancePercentage: 60.0,
        vendorName: 'CloudScale\u00A0Solutions\u2014LLC',
        clientName: 'Northstar\u2011Retail Corp',
        invoiceNumber: 'INV\u20112026\u2013902',
        contractReference: 'MSA\u20112026\u2014CS',
        findings: [
          AuditFinding(
            id: 'f-uni-1',
            title: 'Senior\u2011Engineer Rate\u2013Overcharge [RATE_BREACH]',
            category: 'rate_overcharge',
            severity: 'high',
            clauseReference: 'Clause\u00A04.2\u2014Rates',
            invoiceLineReference: 'Line\u201103',
            agreedRate: 100.0,
            billedRate: 150.0,
            varianceAmount: 1500.0,
            description:
                '[UNAPPROVED_EXPENSE] Billed “off\u2011rate” hours\u2026 beyond 14\u2011day SLA \u2192 Breach ✓',
          ),
        ],
      );

      final unicodeState = DisputeState(
        status: DisputeGenerationStatus.ready,
        tone: DisputeTone.firmLegal,
        vendorName: unicodeAudit.vendorName!,
        clientName: unicodeAudit.clientName!,
        invoiceReference: unicodeAudit.invoiceNumber!,
        contractReference: unicodeAudit.contractReference!,
        totalWithheld: unicodeAudit.totalVarianceAmount,
        totalInvoiced: unicodeAudit.invoicedTotal,
        approvedPayment: unicodeAudit.verifiedContractBase,
        currency: 'EUR',
        sourceAuditResult: unicodeAudit,
      );

      final capturedPrints = <String>[];
      const exporter = DisputePdfExporter();
      final pdfBytes = await runZoned(
        () => exporter.buildDisputePdfBytes(disputeState: unicodeState),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => capturedPrints.add(line),
        ),
      );

      expect(pdfBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));

      // Verify zero character fallback or Latin1 encoding failures occurred.
      expect(
        capturedPrints.where(
          (line) =>
              line.contains('Unable to find a font') ||
              line.contains('Cannot decode the string to Latin1'),
        ),
        isEmpty,
      );

      // Verify Syncfusion reads back ASCII '-' hyphens and normalized text intact.
      final parsedDoc = PdfDocument(inputBytes: pdfBytes);
      try {
        final extractedText = PdfTextExtractor(parsedDoc)
            .extractText()
            .replaceAll(RegExp(r'\s+'), ' ');
        expect(extractedText, contains('INV-2026-902'));
        expect(extractedText, contains('MSA-2026-CS'));
        expect(extractedText, contains('Northstar-Retail Corp'));
        expect(extractedText, contains('CloudScale Solutions-LLC'));
        expect(extractedText, contains('Senior-Engineer Rate-Overcharge'));
        expect(extractedText, contains('Clause 4.2-Rates'));
        expect(extractedText, contains('Billed "off-rate" hours... beyond 14-day SLA -> Breach'));
        expect(extractedText, contains('EUR 1,500.00'));
        expect(extractedText, isNot(contains('[RATE_OVERCHARGE]')));
        expect(extractedText, isNot(contains('[RATE_BREACH]')));
        expect(extractedText, isNot(contains('[UNAPPROVED_EXPENSE]')));
      } finally {
        parsedDoc.dispose();
      }

      // Verify clean enum stripping preserves non-enum bracketed notes.
      expect(
        DisputePdfExporter.cleanFindingText(
          'Senior DevOps Engineer Rate Breach [RATE_BREACH] [Exhibit B]',
        ),
        equals('Senior DevOps Engineer Rate Breach [Exhibit B]'),
      );
      expect(ClairPdfViewer.maxScale, equals(3.0));
      expect(ClairPdfViewer.minRasterScale, equals(2.5));
    },
  );

  testWidgets('ClairDocs Phase 4 & Phase 5 end-to-end audit and dispute studio test', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final testVaultDb = _InMemoryAuditDatabaseService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          geminiAuditServiceProvider.overrideWithValue(_OfflineMockAuditService()),
          groqAuditServiceProvider.overrideWithValue(_OfflineMockGroqService()),
          auditDatabaseServiceProvider.overrideWithValue(testVaultDb),
        ],
        child: const ClairDocsApp(),
      ),
    );

    // 0. Animated Splash Screen entrance (1.5s fade + 0.85 -> 1.0 scale) & 2.0s transition
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(ClairLogoBadge), findsOneWidget);
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.appTagline), findsOneWidget);

    final scaleFinder = find.byKey(const ValueKey('splash_entrance_scale'));
    final initialScale = tester.widget<ScaleTransition>(scaleFinder).scale.value;
    expect(initialScale, closeTo(0.85, 0.01));

    await tester.pump(const Duration(milliseconds: 1500));
    final finishedScale = tester.widget<ScaleTransition>(scaleFinder).scale.value;
    expect(finishedScale, closeTo(1.0, 0.01));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);

    // 1. Initial Awaiting Documents State (no files selected) & exact 1:1 split frame widths
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TopCommandBar),
        matching: find.byType(ClairLogoBadge),
      ),
      findsOneWidget,
    );
    expect(find.text('Awaiting Documents'), findsOneWidget);
    expect(find.text('Select Governing Contract'), findsOneWidget);
    expect(find.text('Select Vendor Invoice'), findsOneWidget);
    expect(find.text('Ready for Autonomous Audit'), findsOneWidget);
    expect(find.text('Draft Dispute Notice'), findsNothing);

    final contractSize = tester.getSize(find.byType(ContractViewerPanel));
    final invoiceSize = tester.getSize(find.byType(InvoiceViewerPanel));
    expect(contractSize.width, closeTo(invoiceSize.width, 0.01));
    expect(contractSize.height, closeTo(invoiceSize.height, 0.01));

    final runAuditBtnFinder = find.ancestor(
      of: find.text('Run AI Audit').first,
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(runAuditBtnFinder).enabled, isFalse);

    // 2. Select one document -> becomes "Ready for Audit"; tapping Run AI Audit shows counterpart validation error
    await tester.tap(find.text('Demo Sample').first);
    await tester.pumpAndSettle();
    expect(find.text('Ready for Audit'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(runAuditBtnFinder).enabled, isTrue);

    await tester.tap(find.text('Run AI Audit').first);
    await tester.pumpAndSettle();
    expect(find.text('Audit Attention Required'), findsOneWidget);
    expect(find.text('Audit Could Not Complete'), findsOneWidget);

    // 3. Select second panel Demo Sample (auto-resets error back to idle) and run audit
    await tester.tap(find.text('Demo Sample').last);
    await tester.pumpAndSettle();
    expect(find.text('Ready for Autonomous Audit'), findsOneWidget);

    await tester.tap(find.text('Run AI Audit').first);
    await tester.pump();
    expect(find.text('Auditing Documents...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    // Verify 3-second debounce cooldown activates immediately after completion
    expect(find.text('Wait 3s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Run AI Audit'), findsOneWidget);

    expect(find.text('3 Discrepancies Detected'), findsOneWidget);
    expect(find.text('Gemini 3.8'), findsOneWidget);
    expect(find.text('GEMINI 3.8'), findsOneWidget);
    expect(find.text('+\$4,850.00'), findsNWidgets(2));
    expect(find.text('Draft Dispute Notice'), findsOneWidget);

    // 3b. Click finding card to synchronize highlight & scroll in both document panes
    await tester.tap(find.text('Omitted 5% Quarterly Volume Discount'));
    await tester.pumpAndSettle();
    expect(find.text('Highlighted: Section 12.3'), findsOneWidget);
    expect(find.text('Highlighted: Volume Rebate'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear highlight').first);
    await tester.pumpAndSettle();
    expect(find.text('Highlighted: Section 12.3'), findsNothing);

    // 4. Open Interactive Dispute Studio modal
    await tester.tap(find.text('Draft Dispute Notice'));
    await tester.pumpAndSettle();

    expect(find.text('Interactive Dispute Studio'), findsOneWidget);
    expect(find.text('Vendor: Apex Technologies Inc.'), findsOneWidget);
    expect(find.text('TOTAL WITHHELD'), findsOneWidget);
    expect(find.text('Firm Legal'), findsOneWidget);
    expect(find.text('Collaborative Partner'), findsOneWidget);
    expect(find.text('Strict Breach'), findsOneWidget);
    expect(find.text('Regenerate'), findsOneWidget);
    expect(find.text('Copy to Clipboard'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.textContaining('NOTICE OF INVOICE DISCREPANCY'), findsOneWidget);

    // Switch tone to Collaborative Partner & Strict Breach instantaneously (single frame, 0 LLM calls)
    await tester.tap(find.text('Collaborative Partner'));
    await tester.pump();
    expect(find.textContaining('reconciliation call'), findsOneWidget);

    await tester.tap(find.text('Strict Breach'));
    await tester.pump();
    expect(find.textContaining('MATERIAL BILLING BREACH'), findsOneWidget);
    expect(find.textContaining('reconciliation call'), findsNothing);

    // Copy to Clipboard & Export PDF are enabled immediately once text is rendered
    String? copiedClipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        copiedClipboardText = args?['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final exportButtonFinder = find.ancestor(
      of: find.text('Export PDF'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(exportButtonFinder).enabled, isTrue);

    await tester.tap(find.text('Copy to Clipboard'));
    await tester.pumpAndSettle();
    expect(copiedClipboardText, contains('MATERIAL BILLING BREACH'));
    expect(find.text('Dispute notice copied to clipboard.'), findsOneWidget);

    // 5. Close Studio and click "Remove file" cross button on both panels -> resets to Awaiting Documents
    await tester.tap(find.byTooltip('Close Studio'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove file').first);
    await tester.pumpAndSettle();

    expect(find.text('No Governing Contract Selected'), findsOneWidget);
    expect(find.text('Ready for Autonomous Audit'), findsOneWidget);
    expect(find.text('Draft Dispute Notice'), findsNothing);
    // Only the still-open Demo Invoice mockup contains +$4,850.00; ActionStudio KPI was cleared
    expect(find.text('+\$4,850.00'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove file').first);
    await tester.pumpAndSettle();

    expect(find.text('No Vendor Invoice Selected'), findsOneWidget);
    expect(find.text('Awaiting Documents'), findsOneWidget);
    expect(find.text('+\$4,850.00'), findsNothing);
  });

  testWidgets(
    'DocumentPaneHeader wraps cleanly without clipping SHA-256 badge and finding cards ellipsis-wrap long titles',
    (WidgetTester tester) async {
      const longTitle =
          'Unauthorized Rate Increase for Senior DevOps Engineer';
      const longFile =
          'Master_Services_Agreement_Enterprise_Amendment_2026_Final_v3.pdf';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Narrow split pane (~390px wide) with all controls active
                SizedBox(
                  width: 390,
                  child: DocumentPaneHeader(
                    icon: Icons.description_outlined,
                    accentColor: Colors.lightBlue,
                    title: longFile,
                    isDemo: false,
                    hasFile: true,
                    isPdf: true,
                    sha256Hash: 'abcdef1234567890',
                    formattedSize: '1.2 MB',
                    zoomPercent: 100,
                    currentPage: 1,
                    totalPages: 4,
                    onSelectLiveDoc: () {},
                    onSelectDemoSample: () {},
                    onClearFile: () {},
                    onZoomOut: () {},
                    onZoomIn: () {},
                    onResetZoom: () {},
                    onPreviousPage: null,
                    onNextPage: () {},
                  ),
                ),
                // Narrow Studio column (~280px wide)
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      const RateComparisonCard(
                        finding: AuditFinding(
                          id: 'rc-1',
                          title: longTitle,
                          category: 'rate_overcharge',
                          description: 'Exceeds approved MSA rate schedule.',
                          clauseReference: 'Section 4.2 (Exhibit B)',
                          invoiceLineReference: 'Line Item #01',
                          agreedRate: 150.0,
                          billedRate: 210.0,
                          varianceAmount: 3000.0,
                          severity: 'high',
                        ),
                      ),
                      DiscrepancyItemCard.fromFinding(
                        finding: const AuditFinding(
                          id: 'di-1',
                          title: longTitle,
                          category: 'rate_overcharge',
                          description: 'Exceeds approved MSA rate schedule.',
                          clauseReference: 'Section 4.2 (Exhibit B)',
                          invoiceLineReference: 'Line Item #01',
                          agreedRate: 150.0,
                          billedRate: 210.0,
                          varianceAmount: 3000.0,
                          severity: 'high',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Verify SHA-256 Verified badge & controls remain completely unclipped
      expect(find.text('SHA-256 Verified'), findsOneWidget);
      expect(find.text('Live Doc'), findsOneWidget);
      expect(find.byTooltip('Remove file'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);

      final badgeRect = tester.getRect(find.text('SHA-256 Verified'));
      final headerRect = tester.getRect(find.byType(DocumentPaneHeader));
      final liveDocRect = tester.getRect(find.text('Live Doc'));
      final demoSampleRect = tester.getRect(find.text('Demo Sample'));
      final titleRect = tester.getRect(find.text(longFile));
      final closeRect = tester.getRect(find.byTooltip('Remove file'));

      // Reverted Row 1: Clean full-width title + far-right Close (X);
      // Mode pills live in Row 2 (below title), never inline with the title.
      expect(liveDocRect.left, lessThan(demoSampleRect.left));
      expect(liveDocRect.top, greaterThanOrEqualTo(titleRect.bottom));
      expect(titleRect.right, lessThanOrEqualTo(closeRect.left));
      expect(closeRect.right, greaterThan(headerRect.right - 20));
      expect(closeRect.right, lessThanOrEqualTo(headerRect.right));

      expect(badgeRect.left, greaterThanOrEqualTo(headerRect.left));
      expect(badgeRect.right, lessThanOrEqualTo(headerRect.right));
      expect(badgeRect.top, greaterThanOrEqualTo(headerRect.top));
      expect(badgeRect.bottom, lessThanOrEqualTo(headerRect.bottom));

      // Verify finding cards are neutral (unhighlighted & no glow) by default before hover/selection
      final animatedBoxes = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(animatedBoxes.length, greaterThanOrEqualTo(2));
      for (final box in animatedBoxes) {
        final dec = box.decoration as BoxDecoration?;
        expect(dec?.color, equals(AppColors.surfaceCard));
        expect(dec?.boxShadow, isNull);
        expect((dec?.border as Border?)?.top.color, equals(AppColors.borderSubtle));
      }

      // Verify long finding titles configure maxLines == 2 + TextOverflow.ellipsis
      final titleTexts = tester
          .widgetList<Text>(find.text(longTitle))
          .toList();
      expect(titleTexts.length, equals(2));
      for (final titleText in titleTexts) {
        expect(titleText.maxLines, equals(2));
        expect(titleText.overflow, equals(TextOverflow.ellipsis));
      }
    },
  );

  testWidgets(
    'Interactive PDF Line Highlighter extracts keywords, syncs activeSelectedFindingProvider, and calls PdfViewerController.searchText',
    (WidgetTester tester) async {
      const sampleFinding = AuditFinding(
        id: 'find-devops-1',
        title: 'Rate Overcharge: Senior DevOps Engineer',
        category: 'rate_breach',
        description: 'Billed above Section 3.1 contracted rate.',
        clauseReference: 'Section 3.1 (Exhibit A)',
        invoiceLineReference: 'Line Item #02',
        searchKeyword: 'Senior DevOps Engineer',
        agreedRate: 150.0,
        billedRate: 210.0,
        varianceAmount: 1800.0,
        severity: 'high',
      );

      // 1. Verify searchKeyword round-trip & candidate prioritization per pane role
      final roundTripFinding = AuditFinding.fromJson(sampleFinding.toJson());
      expect(roundTripFinding.searchKeyword, equals('Senior DevOps Engineer'));

      final contractCandidates = DocumentViewerPane.buildSearchCandidates(
        roundTripFinding,
        role: DocumentPaneRole.contract,
      );
      expect(contractCandidates.first, equals('Section 3.1'));
      expect(contractCandidates, contains('Senior DevOps Engineer'));

      final invoiceCandidates = DocumentViewerPane.buildSearchCandidates(
        roundTripFinding,
        role: DocumentPaneRole.invoice,
      );
      expect(invoiceCandidates.first, equals('Senior DevOps Engineer'));
      expect(invoiceCandidates, contains('Line Item #02'));

      // 2. Verify selecting activeSelectedFindingProvider calls controller.searchText
      final contractPdfCtrl = _RecordingPdfViewerController();
      final invoicePdfCtrl = _RecordingPdfViewerController();
      addTearDown(contractPdfCtrl.dispose);
      addTearDown(invoicePdfCtrl.dispose);

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  final selected = ref.watch(activeSelectedFindingProvider);
                  return Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: DocumentViewerPane(
                                role: DocumentPaneRole.contract,
                                accentColor: Colors.lightBlue,
                                pdfController: contractPdfCtrl,
                                isPdfActive: true,
                                builder: (_, _, _, _, _) => const SizedBox(),
                              ),
                            ),
                            Expanded(
                              child: DocumentViewerPane(
                                role: DocumentPaneRole.invoice,
                                accentColor: Colors.redAccent,
                                pdfController: invoicePdfCtrl,
                                isPdfActive: true,
                                builder: (_, _, _, _, _) => const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DiscrepancyItemCard.fromFinding(
                        finding: sampleFinding,
                        isSelected: selected?.id == sampleFinding.id,
                        onTap: () => ref
                            .read(activeSelectedFindingProvider.notifier)
                            .selectFinding(sampleFinding),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DiscrepancyItemCard));
      await tester.pump();

      expect(
        container.read(activeSelectedFindingProvider)?.id,
        equals('find-devops-1'),
      );
      expect(contractPdfCtrl.searchedQueries, contains('Section 3.1'));
      expect(invoicePdfCtrl.searchedQueries, contains('Senior DevOps Engineer'));
      expect(find.textContaining('Searching "Section 3.1"'), findsOneWidget);
      expect(
        find.textContaining('Searching "Senior DevOps Engineer"'),
        findsOneWidget,
      );

      // Let finite 2.2s glow animation settle cleanly
      await tester.pumpAndSettle();

      // Clear highlight resets activeSelectedFindingProvider
      await tester.tap(find.byTooltip('Clear highlight').first);
      await tester.pumpAndSettle();
      expect(container.read(activeSelectedFindingProvider), isNull);
    },
  );

  test(
    'AuditDatabaseService persists, fetches, and deletes records in local SQLite clairdocs_vault.db',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('clairdocs_vault_');
      final dbPath = '${tempDir.path}${Platform.pathSeparator}clairdocs_vault.db';
      final dbService = AuditDatabaseService(databasePathOverride: dbPath);

      try {
        final demo = AuditResult.demoSample();
        final findingsJson = jsonEncode(
          demo.findings.map((f) => f.toJson()).toList(),
        );

        final olderRecord = AuditRecord(
          id: 'vault-01',
          timestamp: '2026-11-10T09:00:00.000Z',
          contractName: 'MSA_CloudScale_2026.pdf',
          invoiceName: 'INV-902.pdf',
          vendorName: 'CloudScale Solutions LLC',
          invoicedTotal: 32500.0,
          contractBase: 28000.0,
          totalVariance: 4500.0,
          findingsJson: findingsJson,
          noticeText: 'Formal Notice for CloudScale Solutions LLC',
        );
        final newerRecord = AuditRecord(
          id: 'vault-02',
          timestamp: '2026-11-11T09:30:00.000Z',
          contractName: 'MSA_Apex_2026.pdf',
          invoiceName: 'INV-2026-889.pdf',
          vendorName: 'Apex Technologies Inc.',
          invoicedTotal: 48250.0,
          contractBase: 43400.0,
          totalVariance: 4850.0,
          findingsJson: findingsJson,
          noticeText: 'Formal Notice for Apex Technologies Inc.',
        );

        await dbService.saveAuditRecord(olderRecord);
        await dbService.saveAuditRecord(newerRecord);

        final fetched = await dbService.fetchAllAudits();
        expect(fetched.length, equals(2));
        // Sorted newest first
        expect(fetched.first.id, equals('vault-02'));
        expect(fetched.first.vendorName, equals('Apex Technologies Inc.'));
        expect(fetched.first.totalVariance, equals(4850.0));
        expect(fetched.first.decodeFindings().length, equals(3));
        expect(fetched.last.id, equals('vault-01'));

        await dbService.deleteAuditRecord('vault-02');
        final afterDelete = await dbService.fetchAllAudits();
        expect(afterDelete.length, equals(1));
        expect(afterDelete.single.vendorName, equals('CloudScale Solutions LLC'));
      } finally {
        await dbService.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );

  testWidgets(
    'Audit Vault auto-saves completed audits, filters by vendor, reloads past audit, and exposes Export PDF',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final memoryDb = _InMemoryAuditDatabaseService();
      await memoryDb.saveAuditRecord(
        AuditRecord(
          id: 'past-cs-1',
          timestamp: '2026-11-09T14:15:00.000Z',
          contractName: 'MSA-2026-CS.pdf',
          invoiceName: 'INV-902.pdf',
          vendorName: 'CloudScale Solutions LLC',
          invoicedTotal: 25000.0,
          contractBase: 21500.0,
          totalVariance: 3500.0,
          findingsJson: jsonEncode(
            AuditResult.demoSample().findings.map((f) => f.toJson()).toList(),
          ),
          noticeText: 'Stored legal notice for CloudScale Solutions LLC',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiAuditServiceProvider.overrideWithValue(_OfflineMockAuditService()),
            groqAuditServiceProvider.overrideWithValue(_OfflineMockGroqService()),
            auditDatabaseServiceProvider.overrideWithValue(memoryDb),
          ],
          child: const ClairDocsApp(),
        ),
      );

      // Advance past 2s SplashScreen
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Run Demo audit -> triggers background save into Vault
      await tester.tap(find.text('Demo Sample').first);
      await tester.tap(find.text('Demo Sample').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Run AI Audit').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final savedRecords = await memoryDb.fetchAllAudits();
      expect(savedRecords.length, equals(2));
      expect(
        savedRecords.any((r) => r.vendorName == 'Apex Technologies Inc.'),
        isTrue,
      );

      // Open Audit Vault dialog via TopCommandBar button
      await tester.tap(find.text('Audit Vault'));
      await tester.pumpAndSettle();

      expect(find.byType(AuditVaultDialog), findsOneWidget);
      expect(find.text('Audit Vault & History'), findsOneWidget);
      expect(find.text('2 SAVED'), findsOneWidget);
      expect(find.text('Apex Technologies Inc.'), findsOneWidget);
      expect(find.text('CloudScale Solutions LLC'), findsOneWidget);

      // Filter by vendor name
      await tester.enterText(find.byType(TextField), 'CloudScale');
      await tester.pumpAndSettle();
      expect(find.text('CloudScale Solutions LLC'), findsOneWidget);
      expect(find.text('Apex Technologies Inc.'), findsNothing);

      // Export PDF button is active & enabled
      final exportBtn = find.descendant(
        of: find.byType(AuditVaultDialog),
        matching: find.ancestor(
          of: find.text('Export PDF'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(tester.widget<ButtonStyleButton>(exportBtn).enabled, isTrue);

      // Reload Past Audit clears current docs & restores saved audit + notice
      await tester.tap(find.text('Reload Past Audit'));
      await tester.pumpAndSettle();

      expect(find.byType(AuditVaultDialog), findsNothing);
      expect(find.text('AUDIT VAULT'), findsOneWidget);
      expect(find.text('+\$3,500.00'), findsOneWidget);

      // Open Draft Dispute Notice -> preserves stored Vault noticeText
      await tester.tap(find.text('Draft Dispute Notice'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Stored legal notice for CloudScale Solutions LLC'),
        findsOneWidget,
      );
    },
  );

  test(
    'AnalyticsSummary aggregates KPI totals, top 5 vendors, and category breakdown cleanly',
    () {
      final emptySummary = AnalyticsSummary.fromRecords(const []);
      expect(emptySummary.totalAuditsPerformed, equals(0));
      expect(emptySummary.totalDollarsWithheld, equals(0.0));
      expect(emptySummary.averageVariancePercentage, equals(0.0));
      expect(emptySummary.topVendors, isEmpty);
      expect(emptySummary.categoryBreakdown, isEmpty);

      AuditRecord buildRecord({
        required String id,
        required String vendor,
        required double base,
        required double variance,
        required List<AuditFinding> findings,
      }) {
        return AuditRecord(
          id: id,
          timestamp: '2026-11-11T09:00:00.000Z',
          contractName: 'MSA_$id.pdf',
          invoiceName: 'INV_$id.pdf',
          vendorName: vendor,
          invoicedTotal: base + variance,
          contractBase: base,
          totalVariance: variance,
          findingsJson: jsonEncode(findings.map((f) => f.toJson()).toList()),
          noticeText: 'Notice $id',
        );
      }

      const rateFinding = AuditFinding(
        id: 'rf-1',
        title: 'Rate Overcharge',
        category: 'rate_breach',
        description: 'Overcharged',
        clauseReference: 'Clause 4.2',
        invoiceLineReference: 'Line 1',
        varianceAmount: 3000.0,
        severity: 'high',
      );
      const travelFinding = AuditFinding(
        id: 'tf-1',
        title: 'First Class Travel',
        category: 'unapproved_expense',
        description: 'Travel',
        clauseReference: 'Clause 9.1',
        invoiceLineReference: 'Line 2',
        varianceAmount: 1000.0,
        severity: 'high',
      );

      final records = <AuditRecord>[
        // Apex appears twice -> 3000 + 2000 = 5000 total
        buildRecord(
          id: '1',
          vendor: 'Apex Technologies Inc.',
          base: 30000.0,
          variance: 3000.0,
          findings: const [rateFinding],
        ),
        buildRecord(
          id: '2',
          vendor: 'Apex Technologies Inc.',
          base: 20000.0,
          variance: 2000.0,
          findings: const [
            AuditFinding(
              id: 'rf-2',
              title: 'Overtime Surcharge',
              category: 'hour_cap_exceeded',
              description: 'Cap exceeded',
              clauseReference: 'Clause 5',
              invoiceLineReference: 'Line 3',
              varianceAmount: 2000.0,
              severity: 'medium',
            ),
          ],
        ),
        buildRecord(
          id: '3',
          vendor: 'CloudScale Solutions LLC',
          base: 40000.0,
          variance: 4000.0,
          findings: const [rateFinding, travelFinding],
        ),
        buildRecord(
          id: '4',
          vendor: 'Delta Cloud Ops',
          base: 10000.0,
          variance: 1500.0,
          findings: const [
            AuditFinding(
              id: 'tm-1',
              title: 'Rebate Omitted',
              category: 'term_mismatch',
              description: 'Rebate',
              clauseReference: 'Clause 12',
              invoiceLineReference: 'Line 4',
              varianceAmount: 1500.0,
              severity: 'medium',
            ),
          ],
        ),
        buildRecord(
          id: '5',
          vendor: 'Echo Data Systems',
          base: 10000.0,
          variance: 1200.0,
          findings: const [travelFinding],
        ),
        buildRecord(
          id: '6',
          vendor: 'Foundry Consulting',
          base: 10000.0,
          variance: 900.0,
          findings: const [],
        ),
        buildRecord(
          id: '7',
          vendor: 'Gamma Infrastructure',
          base: 10000.0,
          variance: 400.0,
          findings: const [],
        ),
      ];

      final summary = AnalyticsSummary.fromRecords(records);
      expect(summary.totalAuditsPerformed, equals(7));
      expect(summary.totalDollarsWithheld, equals(13000.0));
      // Record %s: 10%, 10%, 10%, 15%, 12%, 9%, 4% -> mean = 70/7 = 10.0%
      expect(summary.averageVariancePercentage, closeTo(10.0, 0.01));

      expect(summary.topVendors.length, equals(5));
      expect(summary.topVendors[0].vendorName, equals('Apex Technologies Inc.'));
      expect(summary.topVendors[0].totalVariance, equals(5000.0));
      expect(summary.topVendors[0].auditCount, equals(2));
      expect(summary.topVendors[1].vendorName, equals('CloudScale Solutions LLC'));
      expect(summary.topVendors[1].totalVariance, equals(4000.0));
      expect(
        summary.topVendors.any((v) => v.vendorName == 'Gamma Infrastructure'),
        isFalse,
      );

      expect(
        summary.categoryBreakdown.any((c) => c.label == 'Hourly Rate Breaches'),
        isTrue,
      );
      expect(
        summary.categoryBreakdown.any(
          (c) => c.label == 'Unapproved Travel & Expenses',
        ),
        isTrue,
      );
      final totalShare = summary.categoryBreakdown.fold<double>(
        0.0,
        (sum, item) => sum + item.percentage,
      );
      expect(totalShare, closeTo(100.0, 0.01));
    },
  );

  testWidgets(
    'Analytics & Savings button opens AnalyticsDashboardScreen with KPI cards, BarChart, and PieChart from SQLite records',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final memoryDb = _InMemoryAuditDatabaseService();
      await memoryDb.saveAuditRecord(
        AuditRecord(
          id: 'ana-1',
          timestamp: '2026-11-11T09:15:00.000Z',
          contractName: 'MSA_Apex.pdf',
          invoiceName: 'INV-889.pdf',
          vendorName: 'Apex Technologies Inc.',
          invoicedTotal: 48250.0,
          contractBase: 43400.0,
          totalVariance: 4850.0,
          findingsJson: jsonEncode(
            AuditResult.demoSample().findings.map((f) => f.toJson()).toList(),
          ),
          noticeText: 'Notice Apex',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiAuditServiceProvider.overrideWithValue(_OfflineMockAuditService()),
            groqAuditServiceProvider.overrideWithValue(_OfflineMockGroqService()),
            auditDatabaseServiceProvider.overrideWithValue(memoryDb),
          ],
          child: const ClairDocsApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Open Analytics & Savings dashboard from TopCommandBar
      expect(find.text('Analytics & Savings'), findsOneWidget);
      await tester.tap(find.text('Analytics & Savings'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AnalyticsDashboardScreen), findsOneWidget);
      expect(find.text('Analytics & Savings Dashboard'), findsOneWidget);
      expect(find.text('TOTAL AUDITS PERFORMED'), findsOneWidget);
      expect(find.text('TOTAL DOLLARS WITHHELD / RECOVERED'), findsOneWidget);
      expect(find.text('AVERAGE VARIANCE PERCENTAGE'), findsOneWidget);
      expect(find.text('\$4,850.00'), findsOneWidget);
      expect(find.text('11.2%'), findsOneWidget);

      expect(find.text('Top 5 Overcharging Vendors'), findsOneWidget);
      expect(find.text('Variance Breakdown by Category'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Hourly Rate Breaches'), findsOneWidget);

      // Navigate cleanly back to Workbench
      await tester.tap(find.text('Back to Workbench'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsDashboardScreen), findsNothing);
    },
  );

  test(
    'PdfExtractionService.extractPartyMetadata extracts vendorEmail prioritizing AR/billing address',
    () {
      const contractText = '''
MASTER SERVICES AGREEMENT
Contract Reference: MSA-2026-APEX
Client: GlobalFin Corp
Vendor: Apex Technologies Inc.
General Inquiries: info@apextech.io
''';
      const invoiceText = '''
Apex Technologies Inc.
100 Enterprise Plaza
Accounts Receivable: billing@apextech.io
Support: support@apextech.io
Bill To: GlobalFin Corp
Invoice #: INV-2026-889
''';

      final meta = PdfExtractionService.extractPartyMetadata(
        contractText: contractText,
        invoiceText: invoiceText,
      );
      expect(meta.vendorEmail, equals('billing@apextech.io'));
    },
  );

  test(
    'DisputeDispatchService.dispatchEmail attaches ClairDocs_Dispute_Notice.pdf and sends SMTP message',
    () async {
      Message? capturedMessage;
      String? capturedHost;
      int? capturedPort;
      String? capturedUsername;

      final service = DisputeDispatchService(
        smtpSender: (message, server, {timeout}) async {
          capturedMessage = message;
          capturedHost = server.host;
          capturedPort = server.port;
          capturedUsername = server.username;
          return SendReport(
            message,
            DateTime.now(),
            DateTime.now(),
            DateTime.now(),
          );
        },
      );

      final disputeState = DisputeState(
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        clientName: 'GlobalFin Corp',
        invoiceReference: 'INV-2026-889',
        contractReference: 'MSA-2026-APEX',
        totalInvoiced: 24500.0,
        approvedPayment: 19650.0,
        totalWithheld: 4850.0,
        draftText: 'Formal dispute body text.',
        sourceAuditResult: AuditResult.demoSample(),
      );

      final result = await service.dispatchEmail(
        disputeState: disputeState,
        toEmail: 'billing@apextech.io',
        subject: 'Formal Notice - INV-2026-889',
        bodyText: 'Formal dispute body text.',
        smtpConfig: const SmtpConfig(
          host: 'smtp.enterprise.test',
          port: 587,
          username: 'ap@globalfin.io',
          password: 'secret-app-password',
          fromEmail: 'ap@globalfin.io',
        ),
      );

      expect(result.channel, equals('email'));
      expect(result.destination, equals('billing@apextech.io'));
      expect(
        result.attachmentFileName,
        equals('ClairDocs_Dispute_Notice.pdf'),
      );
      expect(capturedHost, equals('smtp.enterprise.test'));
      expect(capturedPort, equals(587));
      expect(capturedUsername, equals('ap@globalfin.io'));
      expect(capturedMessage, isNotNull);
      expect(capturedMessage!.recipients, contains('billing@apextech.io'));
      expect(capturedMessage!.subject, equals('Formal Notice - INV-2026-889'));
      expect(capturedMessage!.text, equals('Formal dispute body text.'));
      expect(capturedMessage!.attachments, hasLength(1));

      final attachment = capturedMessage!.attachments.single as StreamAttachment;
      expect(attachment.fileName, equals('ClairDocs_Dispute_Notice.pdf'));
      expect(attachment.contentType, equals('application/pdf'));
      final attachedBytes = await attachment.asStream().expand((e) => e).toList();
      expect(utf8.decode(attachedBytes.take(5).toList()), equals('%PDF-'));
    },
  );

  test(
    'DisputeDispatchService.dispatchWebhook posts structured 7-key enterprise JSON payload',
    () async {
      Uri? capturedUri;
      Map<String, dynamic>? capturedJson;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedJson = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"ok": true}', 200);
      });

      final service = DisputeDispatchService(httpClient: mockClient);
      final disputeState = DisputeState(
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        totalInvoiced: 24500.0,
        approvedPayment: 19650.0,
        totalWithheld: 4850.0,
        draftText: 'Formal notice letter text.',
        sourceAuditResult: AuditResult.demoSample(),
      );

      final result = await service.dispatchWebhook(
        webhookUrl: 'https://hooks.slack.com/services/T000/B000/SECRET',
        disputeState: disputeState,
      );

      expect(result.channel, equals('webhook'));
      expect(result.statusCode, equals(200));
      expect(
        capturedUri.toString(),
        equals('https://hooks.slack.com/services/T000/B000/SECRET'),
      );
      expect(capturedJson, isNotNull);
      expect(
        capturedJson!.keys.toSet(),
        equals({
          'vendorName',
          'invoicedTotal',
          'approvedRelease',
          'withheldAmount',
          'discrepancyCount',
          'disputeNoticeText',
          'timestamp',
        }),
      );
      expect(capturedJson!['vendorName'], equals('Apex Technologies Inc.'));
      expect(capturedJson!['invoicedTotal'], equals(24500.0));
      expect(capturedJson!['approvedRelease'], equals(19650.0));
      expect(capturedJson!['withheldAmount'], equals(4850.0));
      expect(capturedJson!['discrepancyCount'], equals(3));
      expect(
        capturedJson!['disputeNoticeText'],
        equals('Formal notice letter text.'),
      );
      expect(DateTime.tryParse(capturedJson!['timestamp'] as String), isNotNull);
    },
  );

  testWidgets(
    'DisputeStudioModal Dispatch Notice workflow opens dialog, pre-fills vendor email, posts webhook, and shows toast',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Map<String, dynamic>? dispatchedPayload;
      final webhookClient = MockClient((request) async {
        dispatchedPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"ok": true}', 200);
      });

      final testVaultDb = _InMemoryAuditDatabaseService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiAuditServiceProvider.overrideWithValue(
              _OfflineMockAuditService(),
            ),
            groqAuditServiceProvider.overrideWithValue(
              _OfflineMockGroqService(),
            ),
            auditDatabaseServiceProvider.overrideWithValue(testVaultDb),
            disputeDispatchServiceProvider.overrideWithValue(
              DisputeDispatchService(httpClient: webhookClient),
            ),
          ],
          child: const ClairDocsApp(),
        ),
      );

      // Advance past SplashScreen (2.0s)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Load Demo Contract & Demo Invoice -> Run AI Audit
      await tester.tap(find.text('Demo Sample').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo Sample').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Run AI Audit').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Open Dispute Studio and click Dispatch Notice
      await tester.tap(find.text('Draft Dispute Notice'));
      await tester.pumpAndSettle();

      expect(find.text('Dispatch Notice'), findsOneWidget);
      await tester.tap(find.text('Dispatch Notice'));
      await tester.pumpAndSettle();

      expect(find.byType(DispatchNoticeDialog), findsOneWidget);
      expect(find.text('Dispatch Formal Notice'), findsOneWidget);
      expect(
        find.text('Auto-attaches ClairDocs_Dispute_Notice.pdf'),
        findsOneWidget,
      );
      expect(find.text('billing@apextech.io'), findsOneWidget);

      // Switch to Webhook mode and submit
      await tester.tap(find.text('Post to Webhook'));
      await tester.pumpAndSettle();
      expect(find.text('JSON PAYLOAD PREVIEW'), findsOneWidget);

      final webhookField = find.ancestor(
        of: find.text('Webhook URL'),
        matching: find.byType(TextField),
      );
      await tester.enterText(
        webhookField,
        'https://hooks.slack.com/services/T123/B456/WEBHOOK',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Webhook & Send'));
      await tester.pumpAndSettle();

      expect(find.byType(DispatchNoticeDialog), findsNothing);
      expect(
        find.text('Dispute Notice Dispatched to Vendor'),
        findsOneWidget,
      );
      expect(dispatchedPayload, isNotNull);
      expect(
        dispatchedPayload!['vendorName'],
        equals('Apex Technologies Inc.'),
      );
      expect(dispatchedPayload!['withheldAmount'], equals(4850.0));
    },
  );

  test(
    'AuditDatabaseService.ensureInitialized prepares native SQLite libraries cleanly',
    () async {
      await AuditDatabaseService.ensureInitialized();
      final tempDir = await Directory.systemTemp.createTemp('clairdocs_sqlite_');
      final dbFile = '${tempDir.path}${Platform.pathSeparator}vault_init.db';
      final dbService = AuditDatabaseService(databasePathOverride: dbFile);
      addTearDown(() async {
        await dbService.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final fetched = await dbService.fetchAllAudits();
      expect(fetched, isEmpty);
    },
  );

  testWidgets(
    'Dual-document workbench maintains exact 50/50 split and zero overflow across maximized and Restore Down window sizes',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Future<void> setWindowSize(Size size) async {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
      }

      await setWindowSize(const Size(1920, 1080));

      final testVaultDb = _InMemoryAuditDatabaseService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiAuditServiceProvider.overrideWithValue(
              _OfflineMockAuditService(),
            ),
            groqAuditServiceProvider.overrideWithValue(
              _OfflineMockGroqService(),
            ),
            auditDatabaseServiceProvider.overrideWithValue(testVaultDb),
          ],
          child: const ClairDocsApp(),
        ),
      );

      // Advance past SplashScreen (2.0s)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Load both demo documents so dense mockups & tables are tested during resize
      await tester.tap(find.text('Demo Sample').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo Sample').last);
      await tester.pumpAndSettle();

      // Verify dual-document parent Row uses MainAxisSize.max and Expanded(flex: 1)
      final dualDocRow = tester.widget<Row>(
        find
            .ancestor(
              of: find.byType(ContractViewerPanel),
              matching: find.byType(Row),
            )
            .first,
      );
      expect(dualDocRow.mainAxisSize, equals(MainAxisSize.max));
      expect(
        find.ancestor(
          of: find.byWidget(dualDocRow),
          matching: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
      );

      final contractExpanded = tester.widget<Expanded>(
        find
            .ancestor(
              of: find.byType(ContractViewerPanel),
              matching: find.byType(Expanded),
            )
            .first,
      );
      final invoiceExpanded = tester.widget<Expanded>(
        find
            .ancestor(
              of: find.byType(InvoiceViewerPanel),
              matching: find.byType(Expanded),
            )
            .first,
      );
      expect(contractExpanded.flex, equals(1));
      expect(invoiceExpanded.flex, equals(1));

      for (final size in const [
        Size(1920, 1080),
        Size(1280, 720),
        Size(960, 640),
        Size(900, 600),
      ]) {
        final capturedErrors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          capturedErrors.add(details);
        };
        try {
          await setWindowSize(size);
        } finally {
          FlutterError.onError = prevOnError;
        }
        final contractSize = tester.getSize(find.byType(ContractViewerPanel));
        final invoiceSize = tester.getSize(find.byType(InvoiceViewerPanel));
        expect(contractSize.width, closeTo(invoiceSize.width, 0.01));
        expect(contractSize.height, closeTo(invoiceSize.height, 0.01));

        final contractHeaderSize = tester.getSize(
          find.descendant(
            of: find.byType(ContractViewerPanel),
            matching: find.byType(DocumentPaneHeader),
          ),
        );
        final invoiceHeaderSize = tester.getSize(
          find.descendant(
            of: find.byType(InvoiceViewerPanel),
            matching: find.byType(DocumentPaneHeader),
          ),
        );
        expect(
          contractHeaderSize.height,
          closeTo(invoiceHeaderSize.height, 0.01),
        );

        expect(
          capturedErrors,
          isEmpty,
          reason: capturedErrors
              .map((e) => e.toString())
              .join('\n---\n'),
        );
      }

      // Restore Down desktop width (1280x720): run AI audit and confirm
      // "3 Discrepancies Detected" status badge is unclipped in TopCommandBar.
      await setWindowSize(const Size(1280, 720));
      await tester.tap(find.text('Run AI Audit').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final badgeFinder = find.descendant(
        of: find.byType(TopCommandBar),
        matching: find.text('3 Discrepancies Detected'),
      );
      expect(badgeFinder, findsOneWidget);
      expect(
        find.ancestor(
          of: badgeFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
      );
      final topBarRect = tester.getRect(find.byType(TopCommandBar));
      final pillRect = tester.getRect(badgeFinder);
      expect(pillRect.left, greaterThanOrEqualTo(topBarRect.left));
      expect(pillRect.right, lessThanOrEqualTo(topBarRect.right));

      // Verify TopCommandBar buttons are flexible (not inside a clipping horizontal scroll view)
      // and stay completely within bounds during Restore Down (800x560).
      await setWindowSize(const Size(800, 560));
      final vaultFinder = find.descendant(
        of: find.byType(TopCommandBar),
        matching: find.text('Audit Vault'),
      );
      expect(vaultFinder, findsOneWidget);
      expect(
        find.ancestor(
          of: vaultFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
      );
      final narrowBarRect = tester.getRect(find.byType(TopCommandBar));
      for (final removedLabel in const ['Upload Contract', 'Upload Invoice']) {
        expect(
          find.descendant(
            of: find.byType(TopCommandBar),
            matching: find.text(removedLabel),
          ),
          findsNothing,
        );
      }
      for (final label in const [
        'Audit Vault',
        'Analytics & Savings',
      ]) {
        final rect = tester.getRect(
          find.descendant(
            of: find.byType(TopCommandBar),
            matching: find.text(label),
          ),
        );
        expect(rect.left, greaterThanOrEqualTo(narrowBarRect.left));
        expect(rect.right, lessThanOrEqualTo(narrowBarRect.right));
      }
      final ctaRect = tester.getRect(
        find.descendant(
          of: find.byType(TopCommandBar),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(ctaRect.left, greaterThanOrEqualTo(narrowBarRect.left));
      expect(ctaRect.right, lessThanOrEqualTo(narrowBarRect.right));
      final settingsRect = tester.getRect(
        find.byTooltip('Settings & Credential Store'),
      );
      expect(settingsRect.left, greaterThanOrEqualTo(narrowBarRect.left));
      expect(settingsRect.right, lessThanOrEqualTo(narrowBarRect.right));
    },
  );

  test(
    'DisputeDispatchService.dispatchEmail automatically persists SMTP credentials to SecureStorageService',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      const storage = SecureStorageService();
      final service = DisputeDispatchService(
        secureStorage: storage,
        smtpSender: (message, server, {timeout}) async => SendReport(
          message,
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
        ),
      );

      final disputeState = DisputeState(
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        clientName: 'GlobalFin Corp',
        invoiceReference: 'INV-2026-889',
        contractReference: 'MSA-2026-APEX',
        totalInvoiced: 24500.0,
        approvedPayment: 19650.0,
        totalWithheld: 4850.0,
        draftText: 'Formal notice letter text.',
        sourceAuditResult: AuditResult.demoSample(),
      );

      await service.dispatchEmail(
        disputeState: disputeState,
        toEmail: 'billing@apextech.io',
        subject: 'Discrepancy Notice',
        bodyText: 'Formal notice letter text.',
        smtpConfig: const SmtpConfig(
          host: 'smtp.enterprise.org',
          port: 465,
          username: 'finance-ap@globalfin.io',
          password: 'app-password-9988',
          fromEmail: 'finance-ap@globalfin.io',
          useSsl: true,
        ),
      );

      final saved = await storage.getSmtpCredentials();
      expect(saved.hasAny, isTrue);
      expect(saved.host, equals('smtp.enterprise.org'));
      expect(saved.port, equals(465));
      expect(saved.username, equals('finance-ap@globalfin.io'));
      expect(saved.password, equals('app-password-9988'));
    },
  );

  testWidgets(
    'DispatchNoticeDialog auto-fills from Store Room, masks SMTP password cleanly, and omits inline credential clutter',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({
        'clairdocs_smtp_host': 'smtp.store-room.io',
        'clairdocs_smtp_port': '465',
        'clairdocs_smtp_username': 'store-ap@globalfin.io',
        'clairdocs_smtp_password': 'stored-app-password-99',
      });
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      const storage = SecureStorageService();
      final mockDispatchService = DisputeDispatchService(
        secureStorage: storage,
        smtpSender: (message, server, {timeout}) async => SendReport(
          message,
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
        ),
      );

      final disputeState = DisputeState(
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        clientName: 'GlobalFin Corp',
        invoiceReference: 'INV-2026-889',
        contractReference: 'MSA-2026-APEX',
        totalInvoiced: 24500.0,
        approvedPayment: 19650.0,
        totalWithheld: 4850.0,
        draftText: 'Formal notice letter.',
        sourceAuditResult: AuditResult.demoSample(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            disputeDispatchServiceProvider.overrideWithValue(mockDispatchService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => DispatchNoticeDialog(
                      disputeState: disputeState,
                      noticeText: disputeState.draftText,
                    ),
                  ),
                  child: const Text('Open Dispatch'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Dispatch'));
      await tester.pumpAndSettle();

      TextField passwordField() => tester.widget<TextField>(
            find.ancestor(
              of: find.text('SMTP Password / App Key'),
              matching: find.byType(TextField),
            ),
          );
      TextField portField() => tester.widget<TextField>(
            find.ancestor(
              of: find.text('Port'),
              matching: find.byType(TextField),
            ),
          );

      // Verify clean UI: inline Save Credentials, Clear, Remember, and Copy clutter removed
      expect(find.text('Save Credentials'), findsNothing);
      expect(find.text('Clear'), findsNothing);
      expect(find.text('Remember SMTP Credentials'), findsNothing);
      expect(find.byTooltip('Copy SMTP username'), findsNothing);
      expect(find.byTooltip('Copy SMTP password'), findsNothing);

      // Verify auto-fill from Store Room & status badge
      expect(find.text('Auto-filled from Store Room'), findsOneWidget);
      expect(find.text('smtp.store-room.io'), findsOneWidget);
      expect(portField().controller!.text, equals('465'));
      expect(find.text('store-ap@globalfin.io'), findsOneWidget);
      expect(
        passwordField().controller!.text,
        equals('stored-app-password-99'),
      );

      // Masked by default + eye icon toggles visibility cleanly
      expect(passwordField().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(passwordField().obscureText, isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pumpAndSettle();
      expect(passwordField().obscureText, isTrue);

      // Dispatch email cleanly
      await tester.tap(find.text('Send Email Notice'));
      await tester.pumpAndSettle();
      expect(find.byType(DispatchNoticeDialog), findsNothing);
    },
  );

  testWidgets(
    'SettingsDialog Store Room saves, copies password, clear wipes vault, and integrates with TopCommandBar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      String? copiedClipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedClipboardText =
              (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      const storage = SecureStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            geminiAuditServiceProvider.overrideWithValue(
              _OfflineMockAuditService(
                pdfExtractor: PdfExtractionService(),
                groqService: GroqAuditService(
                  httpClient: MockClient((_) async => http.Response('{}', 200)),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TopCommandBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Settings Store Room from TopCommandBar settings icon
      await tester.tap(find.byTooltip('Settings & Credential Store'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsDialog), findsOneWidget);
      expect(find.text('SMTP CREDENTIAL STORE ROOM'), findsOneWidget);

      Future<void> enterIntoField(String label, String value) async {
        final finder = find.ancestor(
          of: find.text(label),
          matching: find.byType(TextField),
        );
        await tester.enterText(finder, value);
      }

      TextField storePasswordField() => tester.widget<TextField>(
            find.ancestor(
              of: find.text('Google App Password / Key'),
              matching: find.byType(TextField),
            ),
          );

      // Masked by default + eye toggle
      expect(storePasswordField().obscureText, isTrue);
      await enterIntoField('SMTP Host', 'smtp.custom-enterprise.com');
      await enterIntoField('Port', '465');
      await enterIntoField('SMTP Username / From', 'ap-vault@clairdocs.io');
      await enterIntoField('Google App Password / Key', 'abcd-efgh-ijkl-mnop');
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(storePasswordField().obscureText, isFalse);

      // Save Credentials to Secure Storage
      await tester.tap(find.text('Save Credentials'));
      await tester.pumpAndSettle();
      expect(
        find.text('SMTP credentials saved securely to Store Room.'),
        findsOneWidget,
      );
      final saved = await storage.getSmtpCredentials();
      expect(saved.host, equals('smtp.custom-enterprise.com'));
      expect(saved.port, equals(465));
      expect(saved.username, equals('ap-vault@clairdocs.io'));
      expect(saved.password, equals('abcd-efgh-ijkl-mnop'));

      // Copy password via copy icon next to saved password field
      await tester.tap(find.byTooltip('Copy saved password'));
      await tester.pumpAndSettle();
      expect(copiedClipboardText, equals('abcd-efgh-ijkl-mnop'));
      expect(
        find.text('SMTP Password copied to clipboard.'),
        findsOneWidget,
      );

      // Clear saved SMTP credentials
      await tester.tap(find.text('Clear').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Saved SMTP credentials cleared from Store Room.'),
        findsOneWidget,
      );
      final wiped = await storage.getSmtpCredentials();
      expect(wiped.hasAny, isFalse);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsDialog), findsNothing);
    },
  );

  testWidgets(
    'SelectableAuditCard & DiscrepancyItemCard start neutral by default and highlight only on explicit hover or selection',
    (WidgetTester tester) async {
      bool selected = false;
      late StateSetter modalSetState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                modalSetState = setState;
                return Center(
                  child: SizedBox(
                    width: 340,
                    child: DiscrepancyItemCard(
                      title: 'Lead Cloud Architect Rate Breach',
                      clauseCitation: 'Clause 4.2',
                      lineReference: 'Line Item #01',
                      varianceAmount: '+\$3,000.00',
                      explanation: 'Billed above contracted rate cap.',
                      isSelected: selected,
                      onTap: () => setState(() => selected = !selected),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      BoxDecoration cardDecoration() {
        final container = tester.widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(SelectableAuditCard),
            matching: find.byType(AnimatedContainer),
          ),
        );
        return container.decoration! as BoxDecoration;
      }

      // 1. Default state before user interaction: neutral surfaceCard + borderSubtle, zero glow
      final defaultDec = cardDecoration();
      expect(defaultDec.color, equals(AppColors.surfaceCard));
      expect((defaultDec.border! as Border).top.color, equals(AppColors.borderSubtle));
      expect(defaultDec.boxShadow, isNull);

      // 2. Hover state: transitions to subtle sky border highlight
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byType(DiscrepancyItemCard)));
      await tester.pumpAndSettle();

      final hoverDec = cardDecoration();
      expect(
        (hoverDec.border! as Border).top.color,
        equals(AppColors.sky.withValues(alpha: 0.55)),
      );
      expect(hoverDec.boxShadow, isNull);

      // Moving pointer away returns cleanly to neutral default
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      final unhoverDec = cardDecoration();
      expect(unhoverDec.color, equals(AppColors.surfaceCard));
      expect((unhoverDec.border! as Border).top.color, equals(AppColors.borderSubtle));

      // 3. Explicit selection: highlights with surfaceElevate + amber border + glow
      await tester.tap(find.byType(DiscrepancyItemCard));
      await tester.pumpAndSettle();
      final selectedDec = cardDecoration();
      expect(selectedDec.color, equals(AppColors.surfaceElevate));
      expect((selectedDec.border! as Border).top.color, equals(AppColors.amber));
      expect(selectedDec.boxShadow, isNotNull);

      // Cleanly toggles off back to neutral
      modalSetState(() => selected = false);
      await tester.pumpAndSettle();
      expect(cardDecoration().color, equals(AppColors.surfaceCard));
    },
  );

  testWidgets(
    'TopCommandBar renders Audit Vault untruncated with bright Settings icon, and DispatchNoticeDialog / SettingsDialog use high-contrast text & icons',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1.0;

      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      const storage = SecureStorageService();
      final mockDispatchService = DisputeDispatchService(
        secureStorage: storage,
        smtpSender: (message, server, {timeout}) async => SendReport(
          message,
          DateTime.now(),
          DateTime.now(),
          DateTime.now(),
        ),
      );

      final disputeState = DisputeState(
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        clientName: 'GlobalFin Corp',
        invoiceReference: 'INV-2026-889',
        contractReference: 'MSA-2026-APEX',
        totalInvoiced: 24500.0,
        approvedPayment: 19650.0,
        totalWithheld: 4850.0,
        draftText: 'Formal notice letter.',
        sourceAuditResult: AuditResult.demoSample(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            disputeDispatchServiceProvider.overrideWithValue(mockDispatchService),
            geminiAuditServiceProvider.overrideWithValue(
              _OfflineMockAuditService(
                pdfExtractor: PdfExtractionService(),
                groqService: GroqAuditService(
                  httpClient: MockClient((_) async => http.Response('{}', 200)),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TopCommandBar(),
                  Expanded(
                    child: Center(
                      child: Builder(
                        builder: (context) => TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => DispatchNoticeDialog(
                              disputeState: disputeState,
                              noticeText: disputeState.draftText,
                            ),
                          ),
                          child: const Text('Open Dispatch Contrast Check'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      for (final size in const [
        Size(1920, 1080),
        Size(1280, 720),
        Size(800, 560),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();

        final vaultTextFinder = find.descendant(
          of: find.byType(TopCommandBar),
          matching: find.text('Audit Vault'),
        );
        expect(vaultTextFinder, findsOneWidget);
        final vaultParagraph = tester.renderObject<RenderParagraph>(vaultTextFinder);
        expect(
          vaultParagraph.didExceedMaxLines,
          isFalse,
          reason: '"Audit Vault" truncated at viewport $size',
        );

        final settingsIcon = tester.widget<Icon>(
          find.descendant(
            of: find.byTooltip('Settings & Credential Store'),
            matching: find.byType(Icon),
          ),
        );
        expect(settingsIcon.color, equals(Colors.white));
      }

      // Reset to desktop size before opening modals
      tester.view.physicalSize = const Size(1280, 720);
      await tester.pumpAndSettle();

      // Open DispatchNoticeDialog and check bright text, labels & icon contrast
      await tester.tap(find.text('Open Dispatch Contrast Check'));
      await tester.pumpAndSettle();

      final subtitleWidget = tester.widget<Text>(
        find.text(
          'Send directly to vendor Accounts Receivable or trigger an enterprise Webhook',
        ),
      );
      expect(subtitleWidget.style!.color!.a, greaterThanOrEqualTo(0.9));
      expect(subtitleWidget.style!.color, isNot(equals(AppColors.textSecondary)));
      expect(subtitleWidget.style!.color, isNot(equals(AppColors.textMuted)));

      final sectionWidget = tester.widget<Text>(find.text('SMTP TRANSPORT'));
      expect(sectionWidget.style!.color, equals(Colors.white));

      final smtpHostField = tester.widget<TextField>(
        find.ancestor(
          of: find.text('SMTP Host'),
          matching: find.byType(TextField),
        ),
      );
      expect(smtpHostField.style!.color, equals(Colors.white));
      expect(smtpHostField.decoration!.labelStyle!.color, equals(AppColors.textPrimary));
      expect(
        (smtpHostField.decoration!.prefixIcon! as Icon).color,
        equals(Colors.white),
      );

      final eyeToggleIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byTooltip('Show password'),
          matching: find.byType(Icon),
        ),
      );
      expect(eyeToggleIcon.color, equals(Colors.white));

      final closeIconBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.close_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(closeIconBtn.color, equals(Colors.white));

      // Switch to Webhook tab and confirm bright text contrast there too
      await tester.tap(find.text('Post to Webhook'));
      await tester.pumpAndSettle();
      final webhookTabText = tester.widget<Text>(find.text('Post to Webhook'));
      expect(webhookTabText.style!.color, equals(Colors.white));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify SettingsDialog contrast as well
      await tester.tap(find.byTooltip('Settings & Credential Store'));
      await tester.pumpAndSettle();
      final storeSectionText =
          tester.widget<Text>(find.text('SMTP CREDENTIAL STORE ROOM'));
      expect(storeSectionText.style!.color, equals(Colors.white));
      final storeSubtitleText = tester.widget<Text>(
        find.text(
          'Store SMTP credentials here once; Email Vendor dispatches auto-fill automatically.',
        ),
      );
      expect(storeSubtitleText.style!.color, equals(Colors.white));
    },
  );

  testWidgets(
    'TopCommandBar omits upload buttons, displays Contract > No Invoice > Status breadcrumbs, and shows full engine name without ellipsis',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditProvider.overrideWith(_FixedEngineAuditNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TopCommandBar(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Upload Contract & Upload Invoice removed completely from TopCommandBar
      expect(
        find.descendant(
          of: find.byType(TopCommandBar),
          matching: find.text('Upload Contract'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(TopCommandBar),
          matching: find.text('Upload Invoice'),
        ),
        findsNothing,
      );

      // Default breadcrumb placeholders: No Contract & No Invoice with neutral styling matching status badge sizing
      expect(find.text('No Contract'), findsOneWidget);
      expect(find.text('No Invoice'), findsOneWidget);
      expect(find.text('Awaiting Documents'), findsOneWidget);
      final noContractStyle =
          tester.widget<Text>(find.text('No Contract')).style!;
      final noInvoiceStyle =
          tester.widget<Text>(find.text('No Invoice')).style!;
      expect(noContractStyle.fontSize, equals(11.0));
      expect(noContractStyle.fontSize, equals(noInvoiceStyle.fontSize));
      expect(noContractStyle.fontWeight, equals(FontWeight.w500));
      expect(noContractStyle.fontWeight, equals(noInvoiceStyle.fontWeight));
      expect(
        noContractStyle.color,
        equals(AppColors.textPrimary.withValues(alpha: 0.78)),
      );
      expect(noContractStyle.color, equals(noInvoiceStyle.color));
      expect(
        tester.widget<Text>(find.text('Awaiting Documents')).style?.color,
        equals(Colors.white),
      );

      // Activate Contract Demo only -> vibrant blue "MSA_2026 (Demo)" + neutral "No Invoice" + "Ready for Audit"
      final element = tester.element(find.byType(TopCommandBar));
      final container = ProviderScope.containerOf(element);
      container.read(contractDocumentProvider.notifier).setDemoMode(true);
      await tester.pumpAndSettle();

      expect(find.text('MSA_2026 (Demo)'), findsOneWidget);
      expect(find.text('No Invoice'), findsOneWidget);
      expect(find.text('Ready for Audit'), findsOneWidget);
      final partialContractStyle =
          tester.widget<Text>(find.text('MSA_2026 (Demo)')).style!;
      expect(partialContractStyle.color, equals(AppColors.sky));
      expect(partialContractStyle.fontSize, equals(11.0));
      expect(partialContractStyle.fontWeight, equals(FontWeight.w600));
      final partialNoInvoiceStyle =
          tester.widget<Text>(find.text('No Invoice')).style!;
      expect(
        partialNoInvoiceStyle.color,
        equals(AppColors.textPrimary.withValues(alpha: 0.78)),
      );
      expect(partialNoInvoiceStyle.fontSize, equals(11.0));

      // Load Invoice Demo + completed audit with full Groq engine label
      container.read(invoiceDocumentProvider.notifier).setDemoMode(true);
      await container.read(auditProvider.notifier).runAudit();
      await tester.pumpAndSettle();

      expect(find.text('MSA_2026 (Demo)'), findsOneWidget);
      expect(find.text('INV-2026-889 (Demo)'), findsOneWidget);
      expect(find.text('3 Discrepancies Detected'), findsOneWidget);
      final statusBadgeStyle =
          tester.widget<Text>(find.text('3 Discrepancies Detected')).style!;
      final loadedContractStyle =
          tester.widget<Text>(find.text('MSA_2026 (Demo)')).style!;
      final loadedInvoiceStyle =
          tester.widget<Text>(find.text('INV-2026-889 (Demo)')).style!;
      expect(loadedContractStyle.color, equals(AppColors.sky));
      expect(loadedContractStyle.fontSize, equals(statusBadgeStyle.fontSize));
      expect(
        loadedContractStyle.fontWeight,
        equals(statusBadgeStyle.fontWeight),
      );
      expect(
        loadedContractStyle.fontFamily,
        equals(statusBadgeStyle.fontFamily),
      );
      expect(loadedContractStyle.height, equals(statusBadgeStyle.height));
      expect(
        loadedInvoiceStyle.fontSize,
        equals(statusBadgeStyle.fontSize),
      );
      expect(
        loadedInvoiceStyle.fontWeight,
        equals(statusBadgeStyle.fontWeight),
      );
      expect(loadedInvoiceStyle.height, equals(statusBadgeStyle.height));
      expect(loadedContractStyle.color, equals(loadedInvoiceStyle.color));

      final engineTextFinder = find.descendant(
        of: find.byType(TopCommandBar),
        matching: find.text(ApiConstants.groqEngineLabel),
      );
      expect(engineTextFinder, findsOneWidget);
      final engineTextWidget = tester.widget<Text>(engineTextFinder);
      expect(engineTextWidget.overflow, isNot(equals(TextOverflow.ellipsis)));
      final engineParagraph =
          tester.renderObject<RenderParagraph>(engineTextFinder);
      expect(engineParagraph.didExceedMaxLines, isFalse);

      final barRect = tester.getRect(find.byType(TopCommandBar));
      final engineRect = tester.getRect(engineTextFinder);
      expect(engineRect.left, greaterThanOrEqualTo(barRect.left));
      expect(engineRect.right, lessThanOrEqualTo(barRect.right));
    },
  );

  testWidgets(
    'DispatchNoticeDialog Manage in Settings opens SettingsDialog, refreshes credentials, and uses crisp modal borders',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      const storage = SecureStorageService();
      final disputeState = DisputeState(
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        clientName: 'GlobalFin Corp',
        invoiceReference: 'INV-2026-889',
        contractReference: 'MSA-2026-APEX',
        totalInvoiced: 24500.0,
        approvedPayment: 19650.0,
        totalWithheld: 4850.0,
        draftText: 'Formal notice letter.',
        sourceAuditResult: AuditResult.demoSample(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => DispatchNoticeDialog(
                      disputeState: disputeState,
                      noticeText: disputeState.draftText,
                    ),
                  ),
                  child: const Text('Open Dispatch'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Dispatch'));
      await tester.pumpAndSettle();

      TextField dispatchField(String label) => tester.widget<TextField>(
            find.descendant(
              of: find.byType(DispatchNoticeDialog),
              matching: find.ancestor(
                of: find.text(label),
                matching: find.byType(TextField),
              ),
            ),
          );

      expect(find.text('Manage in Settings'), findsOneWidget);
      expect(find.text('Auto-filled from Store Room'), findsNothing);
      final hostBorder =
          dispatchField('SMTP Host').decoration?.enabledBorder
              as OutlineInputBorder?;
      expect(hostBorder?.borderSide.color, equals(const Color(0xFF475569)));

      // Tapping Manage in Settings overlays SettingsDialog
      await tester.ensureVisible(find.text('Manage in Settings'));
      await tester.tap(find.text('Manage in Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsDialog), findsOneWidget);
      expect(find.byType(DispatchNoticeDialog), findsOneWidget);

      Future<void> enterStoreField(String label, String value) async {
        final finder = find.descendant(
          of: find.byType(SettingsDialog),
          matching: find.ancestor(
            of: find.text(label),
            matching: find.byType(TextField),
          ),
        );
        await tester.enterText(finder, value);
      }

      await enterStoreField('SMTP Host', 'smtp.reloaded.io');
      await enterStoreField('Port', '465');
      await enterStoreField('SMTP Username / From', 'reloaded-ap@globalfin.io');
      await enterStoreField(
        'Google App Password / Key',
        'reloaded-app-key-77',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(SettingsDialog),
          matching: find.text('Save Credentials'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(SettingsDialog),
          matching: find.text('Done'),
        ),
      );
      await tester.pumpAndSettle();

      // Returning from SettingsDialog refreshes DispatchNoticeDialog fields & badge
      expect(find.byType(SettingsDialog), findsNothing);
      expect(find.text('Auto-filled from Store Room'), findsOneWidget);
      expect(find.text('Manage in Settings'), findsNothing);
      expect(
        dispatchField('SMTP Host').controller!.text,
        equals('smtp.reloaded.io'),
      );
      expect(dispatchField('Port').controller!.text, equals('465'));
      expect(
        dispatchField('SMTP Username / From').controller!.text,
        equals('reloaded-ap@globalfin.io'),
      );
      expect(
        dispatchField('SMTP Password / App Key').controller!.text,
        equals('reloaded-app-key-77'),
      );
    },
  );

  testWidgets(
    'InvoiceViewerPanel renders loaded CSV cleanly without duplicate filename block or SPREADSHEET CSV tag banner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late Directory tempDir;
      late File csvFile;
      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('clairdocs_csv_ui_');
        csvFile = File(
          '${tempDir.path}${Platform.pathSeparator}vendor_invoice_aug.csv',
        );
        await csvFile.writeAsString(
          'Description,Hours,Rate,Total\nCloud Architect,40,350,14000\n',
        );
      });
      addTearDown(() async {
        await tester.runAsync(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
      });

      final csvDoc = InvoiceDocument(
        id: 'csv-1',
        filePath: csvFile.path,
        fileName: 'vendor_invoice_aug.csv',
        fileSizeBytes: 64,
        sha256Hash: 'abc123def456',
        loadedAt: DateTime(2026, 11, 12),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceDocumentProvider.overrideWith(
              () => _PreloadedCsvInvoiceNotifier(csvDoc),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 600,
                child: InvoiceViewerPanel(),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 15; i++) {
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Filename appears once in DocumentPaneHeader and is NOT duplicated inside WordDocumentPreview
      expect(find.byType(DocumentPaneHeader), findsOneWidget);
      expect(find.byType(WordDocumentPreview), findsOneWidget);
      expect(find.text('vendor_invoice_aug.csv'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(WordDocumentPreview),
          matching: find.text('vendor_invoice_aug.csv'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(WordDocumentPreview),
          matching: find.text('SPREADSHEET CSV'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(WordDocumentPreview),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );
      // CSV content renders cleanly inside the card
      expect(
        find.textContaining('Cloud Architect | 40 | 350 | 14000'),
        findsOneWidget,
      );
    },
  );

  test(
    'SecureStorageService persists GROQ_API_KEY and audit services prioritize secure storage over dotenv',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      const storage = SecureStorageService();
      expect(await storage.hasGroqApiKey(), isFalse);

      await storage.saveApiKey('vault_gemini_key_999');
      await storage.saveGroqApiKey('gsk_vault_priority_888');
      expect(await storage.hasGroqApiKey(), isTrue);
      expect(await storage.getGroqApiKey(), equals('gsk_vault_priority_888'));

      dotenv.loadFromString(
        envString:
            'GEMINI_API_KEY=dotenv_gemini_low\nGROQ_API_KEY=gsk_dotenv_low',
      );
      addTearDown(dotenv.clean);

      final geminiService = GeminiAuditService(secureStorage: storage);
      final groqService = GroqAuditService(secureStorage: storage);

      expect(
        await geminiService.resolveApiKey(),
        equals('vault_gemini_key_999'),
      );
      expect(
        await groqService.resolveApiKey(),
        equals('gsk_vault_priority_888'),
      );

      await storage.deleteGroqApiKey();
      expect(await storage.hasGroqApiKey(), isFalse);
      expect(await groqService.resolveApiKey(), equals('gsk_dotenv_low'));
    },
  );

  test(
    'GeminiAuditService schema TypeError triggers Groq failover or throws MalformedPayloadException, and Groq guards non-string content',
    () async {
      dotenv.loadFromString(envString: 'GROQ_API_KEY=gsk_schema_failover');
      addTearDown(dotenv.clean);

      // 1. Gemini returns valid JSON syntax with broken schema types -> fails over to Groq
      final groqMockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode(AuditResult.demoSample().toJson()),
                },
              },
            ],
          }),
          200,
        );
      });

      final failoverService = GeminiAuditService(
        groqService: GroqAuditService(httpClient: groqMockClient),
      );
      final recovered = await failoverService.executeHybridAudit(
        contractText: 'MSA contract clause text',
        invoiceText: 'Vendor invoice line text',
        geminiPhaseFn: () async => (
          text: '{"totalVarianceAmount": "not-a-number", "findings": "invalid"}',
          modelId: ApiConstants.defaultGeminiModel,
        ),
      );
      expect(recovered.auditEngine, equals('Engine: GPT-OSS 20B (Groq)'));

      // 2. When failover texts are empty, invalid Gemini schema throws MalformedPayloadException (never raw TypeError)
      await expectLater(
        () => failoverService.executeHybridAudit(
          contractText: '',
          invoiceText: '',
          geminiPhaseFn: () async => (
            text: '{"totalVarianceAmount": null, "findings": []}',
            modelId: ApiConstants.defaultGeminiModel,
          ),
        ),
        throwsA(isA<MalformedPayloadException>()),
      );

      // 3. Groq returning non-string message["content"] throws MalformedPayloadException (never raw TypeError)
      final nonStringContentClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': ['unexpected', 'list', 'content'],
                },
              },
            ],
          }),
          200,
        );
      });
      final badContentGroq = GroqAuditService(httpClient: nonStringContentClient);
      await expectLater(
        () => badContentGroq.auditDocuments(
          contractText: 'Contract text',
          invoiceText: 'Invoice text',
        ),
        throwsA(isA<MalformedPayloadException>()),
      );

      // 4. Groq returning invalid AuditResult JSON schema throws MalformedPayloadException
      final badSchemaGroqClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"totalVarianceAmount": "bad", "findings": 123}',
                },
              },
            ],
          }),
          200,
        );
      });
      final badSchemaGroq = GroqAuditService(httpClient: badSchemaGroqClient);
      await expectLater(
        () => badSchemaGroq.auditDocuments(
          contractText: 'Contract text',
          invoiceText: 'Invoice text',
        ),
        throwsA(isA<MalformedPayloadException>()),
      );
    },
  );

  testWidgets(
    'ApiKeyDialog recovers from storage failure without endless spinner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiAuditServiceProvider.overrideWithValue(
              _FailingSaveAuditService(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ApiKeyDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'AIzaTestFailureKey');
      await tester.tap(find.text('Save Securely'));
      await tester.pumpAndSettle();

      expect(find.byType(ApiKeyDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text(
          'Unable to save Gemini API key to OS credential vault. Please retry.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SettingsDialog saves GROQ_API_KEY into SecureStorageService',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      const storage = SecureStorageService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            geminiAuditServiceProvider.overrideWithValue(
              _OfflineMockAuditService(
                groqService: GroqAuditService(secureStorage: storage),
              ),
            ),
            groqAuditServiceProvider.overrideWithValue(
              GroqAuditService(secureStorage: storage),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final groqField = find.ancestor(
        of: find.text('GROQ_API_KEY'),
        matching: find.byType(TextField),
      );
      await tester.enterText(groqField, 'gsk_settings_saved_456');
      final groqSaveBtn = find.widgetWithText(ElevatedButton, 'Save Key').last;
      await tester.ensureVisible(groqSaveBtn);
      await tester.tap(groqSaveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Groq API key securely stored in OS credential vault.'),
        findsOneWidget,
      );
      expect(await storage.getGroqApiKey(), equals('gsk_settings_saved_456'));
    },
  );

  testWidgets(
    'AuditWorkbenchScreen switches between 3-column desktop (>=900px) and mobile NavigationBar (<900px) without overflow',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final capturedErrors = <FlutterErrorDetails>[];
      Future<void> runWithoutFlutterErrors(Future<void> Function() body) async {
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          capturedErrors.add(details);
        };
        try {
          await body();
        } finally {
          FlutterError.onError = prevOnError;
        }
        expect(
          capturedErrors,
          isEmpty,
          reason: capturedErrors.map((e) => e.toString()).join('\n---\n'),
        );
      }

      tester.view.physicalSize = const Size(1280, 720);
      final testVaultDb = _InMemoryAuditDatabaseService();
      await runWithoutFlutterErrors(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              geminiAuditServiceProvider.overrideWithValue(
                _OfflineMockAuditService(),
              ),
              groqAuditServiceProvider.overrideWithValue(
                _OfflineMockGroqService(),
              ),
              auditDatabaseServiceProvider.overrideWithValue(testVaultDb),
            ],
            child: const ClairDocsApp(),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      });

      // Desktop (>= 900px): all 3 panes side-by-side, no mobile NavigationBar
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(ContractViewerPanel), findsOneWidget);
      expect(find.byType(InvoiceViewerPanel), findsOneWidget);
      expect(find.byType(ActionStudioPanel), findsOneWidget);

      // Collapse to mobile (< 900px) at 390x844 and 360x780
      for (final mobileSize in const [Size(390, 844), Size(360, 780)]) {
        await runWithoutFlutterErrors(() async {
          tester.view.physicalSize = mobileSize;
          await tester.pumpAndSettle();
        });

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('• Awaiting Documents'), findsOneWidget);
        expect(find.text('Governing Contract'), findsOneWidget);
        expect(find.text('Vendor Invoice'), findsOneWidget);
        expect(find.text('Run AI Audit'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Audit Vault'), findsOneWidget);
        expect(find.text('Analytics'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('About'), findsNothing);
      }

      // Activate Demo Sample directly on both cards on the unified setup screen (no tab switching needed)
      await runWithoutFlutterErrors(() async {
        final demoButtons = find.text('Demo Sample');
        expect(demoButtons, findsNWidgets(2));
        await tester.tap(demoButtons.first);
        await tester.pumpAndSettle();
      });
      expect(find.text('Master_Services_Agreement_2026.pdf'), findsOneWidget);

      await runWithoutFlutterErrors(() async {
        final demoButtons = find.text('Demo Sample');
        expect(demoButtons, findsOneWidget);
        await tester.tap(demoButtons.first);
        await tester.pumpAndSettle();
      });
      expect(find.text('Apex_Tech_Invoice_INV-2026-889.pdf'), findsOneWidget);
      expect(find.text('• Ready for Audit'), findsOneWidget);

      // Run AI audit directly from the unified screen
      await runWithoutFlutterErrors(() async {
        await tester.ensureVisible(find.text('Run AI Audit'));
        await tester.tap(find.text('Run AI Audit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      });
      expect(find.text('• 3 Discrepancies Detected'), findsOneWidget);
      expect(find.text('TOTAL DISPUTED VARIANCE'), findsOneWidget);
      expect(find.text('Draft Dispute Notice'), findsOneWidget);

      // Open DisputeStudioModal on 360x780 mobile viewport and confirm zero overflow
      await runWithoutFlutterErrors(() async {
        await tester.ensureVisible(find.text('Draft Dispute Notice'));
        await tester.tap(find.text('Draft Dispute Notice'));
        await tester.pumpAndSettle();
      });
      expect(find.byType(DisputeStudioModal), findsOneWidget);

      await runWithoutFlutterErrors(() async {
        await tester.tap(find.byTooltip('Close Studio'));
        await tester.pumpAndSettle();
      });

      // Pop back from MobileAuditResultsScreen to Home setup screen
      await runWithoutFlutterErrors(() async {
        await tester.tap(find.byTooltip('Back to Setup'));
        await tester.pumpAndSettle();
      });

      // Verify the 4 bottom navigation destinations (all full-screen tabs):
      // 1. Audit Vault
      await runWithoutFlutterErrors(() async {
        await tester.tap(find.text('Audit Vault'));
        await tester.pumpAndSettle();
      });
      expect(find.byType(AuditVaultDialog), findsOneWidget);
      expect(find.text('Audit Vault & History'), findsOneWidget);

      // 2. Analytics
      await runWithoutFlutterErrors(() async {
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
      });
      expect(find.byType(AnalyticsDashboardScreen), findsOneWidget);
      expect(find.text('Analytics & Savings Dashboard'), findsOneWidget);

      // 3. Settings (includes theme options)
      await runWithoutFlutterErrors(() async {
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
      });
      expect(find.byType(SettingsDialog), findsOneWidget);
      expect(find.text('APPLICATION THEME'), findsOneWidget);
      expect(find.text('Dark (Default)'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // 4. Return to Home
      await runWithoutFlutterErrors(() async {
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
      });
      expect(find.text('Governing Contract'), findsOneWidget);
      expect(find.text('Vendor Invoice'), findsOneWidget);
    },
  );

  testWidgets(
    'Mobile dialogs, modals, and AnalyticsDashboardScreen render without overflow on 360x780 viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterSecureStorage.setMockInitialValues({});
      addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));

      final capturedErrors = <FlutterErrorDetails>[];
      Future<void> runWithoutFlutterErrors(Future<void> Function() body) async {
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          capturedErrors.add(details);
        };
        try {
          await body();
        } finally {
          FlutterError.onError = prevOnError;
        }
        expect(
          capturedErrors,
          isEmpty,
          reason: capturedErrors.map((e) => e.toString()).join('\n---\n'),
        );
      }

      final testVaultDb = _InMemoryAuditDatabaseService();
      await testVaultDb.saveAuditRecord(
        AuditRecord(
          id: 'mobile-vault-1',
          timestamp: '2026-11-12T10:00:00.000Z',
          contractName: 'Apex_Master_Services_Agreement_2026.pdf',
          invoiceName: 'APEX_Invoice_INV_2026_889.pdf',
          vendorName: 'Apex Technologies Inc.',
          invoicedTotal: 48250.0,
          contractBase: 43400.0,
          totalVariance: 4850.0,
          findingsJson: jsonEncode(
            AuditResult.demoSample().findings.map((f) => f.toJson()).toList(),
          ),
          noticeText: 'Stored notice draft.',
        ),
      );

      final sampleDispute = DisputeState(
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        clientName: 'GlobalFin Corp',
        invoiceReference: 'INV-2026-889',
        contractReference: 'MSA-2026-APEX',
        totalInvoiced: 48250.0,
        approvedPayment: 43400.0,
        totalWithheld: 4850.0,
        draftText: 'Formal dispute notice draft body.',
        sourceAuditResult: AuditResult.demoSample(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            geminiAuditServiceProvider.overrideWithValue(
              _OfflineMockAuditService(),
            ),
            groqAuditServiceProvider.overrideWithValue(
              _OfflineMockGroqService(),
            ),
            auditDatabaseServiceProvider.overrideWithValue(testVaultDb),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ListView(
                  children: [
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                      child: const Text('Open Settings'),
                    ),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const ApiKeyDialog(),
                      ),
                      child: const Text('Open ApiKey'),
                    ),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AuditVaultDialog(),
                      ),
                      child: const Text('Open Vault'),
                    ),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => DispatchNoticeDialog(
                          disputeState: sampleDispute,
                          noticeText: sampleDispute.draftText,
                        ),
                      ),
                      child: const Text('Open Dispatch'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AnalyticsDashboardScreen(),
                        ),
                      ),
                      child: const Text('Open Analytics'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> openAndCloseDialog(String trigger, Type dialogType) async {
        await runWithoutFlutterErrors(() async {
          await tester.tap(find.text(trigger));
          await tester.pumpAndSettle();
        });
        expect(find.byType(dialogType), findsOneWidget);
        await runWithoutFlutterErrors(() async {
          Navigator.of(tester.element(find.byType(dialogType))).pop();
          await tester.pumpAndSettle();
        });
      }

      await openAndCloseDialog('Open Settings', SettingsDialog);
      await openAndCloseDialog('Open ApiKey', ApiKeyDialog);
      await openAndCloseDialog('Open Vault', AuditVaultDialog);

      await runWithoutFlutterErrors(() async {
        await tester.tap(find.text('Open Dispatch'));
        await tester.pumpAndSettle();
      });
      expect(find.byType(DispatchNoticeDialog), findsOneWidget);
      await runWithoutFlutterErrors(() async {
        await tester.tap(find.text('Post to Webhook'));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(DispatchNoticeDialog))).pop();
        await tester.pumpAndSettle();
      });

      await runWithoutFlutterErrors(() async {
        await tester.tap(find.text('Open Analytics'));
        await tester.pumpAndSettle();
      });
      expect(find.byType(AnalyticsDashboardScreen), findsOneWidget);
      await runWithoutFlutterErrors(() async {
        await tester.tap(find.byTooltip('Back to Workbench'));
        await tester.pumpAndSettle();
      });
    },
  );
}

class _FailingSaveAuditService extends GeminiAuditService {
  @override
  Future<bool> hasConfiguredApiKey() async => false;

  @override
  Future<void> saveApiKey(String apiKey) async {
    throw StateError('Simulated OS Credential Vault write failure');
  }
}

class _PreloadedCsvInvoiceNotifier extends InvoiceDocumentNotifier {
  final InvoiceDocument _doc;
  _PreloadedCsvInvoiceNotifier(this._doc);

  @override
  InvoiceState build() => InvoiceState(document: _doc);
}
