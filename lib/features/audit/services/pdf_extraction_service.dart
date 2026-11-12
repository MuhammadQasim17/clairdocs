import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/document_file_helper.dart';

String _extractPdfBytesInIsolate(Uint8List bytes) {
  PdfDocument? document;
  try {
    document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();
    final pageCount = document.pages.count;

    for (var i = 0; i < pageCount; i++) {
      final rawPageText = extractor
          .extractText(startPageIndex: i, endPageIndex: i, layoutText: true)
          .trim();
      if (rawPageText.isNotEmpty) {
        final normalized = rawPageText.replaceAll(RegExp(r'\n{3,}'), '\n\n');
        buffer.writeln('--- Page ${i + 1} ---');
        buffer.writeln(normalized);
        buffer.writeln();
      }
    }

    final pagedResult = buffer.toString().trim();
    if (pagedResult.isNotEmpty) {
      return pagedResult;
    }
    return extractor.extractText().trim();
  } catch (_) {
    return '';
  } finally {
    document?.dispose();
  }
}

class PdfExtractionService {
  static const Duration defaultPdfTimeout = Duration(seconds: 5);

  final Duration pdfTimeout;
  final Future<String> Function(Uint8List bytes)? pdfIsolateRunner;

  const PdfExtractionService({
    this.pdfTimeout = defaultPdfTimeout,
    this.pdfIsolateRunner,
  });

  static bool isExtractionFailureOrEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ||
        trimmed.startsWith('Error: Text extraction timed out.') ||
        trimmed.startsWith('Extraction failed:');
  }

  /// Offloads Syncfusion PDF text parsing to a background isolate via [compute]
  /// with a strict 5-second timeout so the Flutter UI thread never blocks.
  Future<String> extractTextFromPdf(File file) async {
    try {
      if (!await file.exists()) {
        return '';
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return '';
      }
      final extractionFuture = pdfIsolateRunner != null
          ? pdfIsolateRunner!(bytes)
          : compute(_extractPdfBytesInIsolate, bytes);

      return await extractionFuture.timeout(
        pdfTimeout,
        onTimeout: () => 'Error: Text extraction timed out.',
      );
    } catch (e) {
      return 'Extraction failed: $e';
    }
  }

  /// Unified document text extraction router supporting `.pdf`, `.docx`, `.doc`,
  /// `.csv`, `.xlsx`, and `.xls` files without base64 binary payloads.
  Future<String> extractDocumentText(File file) async {
    if (!await file.exists()) {
      throw DocumentParseException('Document file does not exist: ${file.path}');
    }

    if (DocumentFileHelper.isPdfPath(file.path)) {
      return extractTextFromPdf(file);
    }

    try {
      if (DocumentFileHelper.isCsvPath(file.path)) {
        final size = await file.length();
        if (size == 0) {
          throw DocumentParseException(
            'Spreadsheet file is empty (0 bytes): ${file.path}',
          );
        }
        String csvContent;
        try {
          csvContent = await file.readAsString();
        } on FileSystemException {
          csvContent = latin1.decode(await file.readAsBytes(), allowInvalid: true);
        } on FormatException {
          csvContent = latin1.decode(await file.readAsBytes(), allowInvalid: true);
        }
        return extractTextFromCsvString(csvContent);
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw DocumentParseException(
          'Document file is empty (0 bytes): ${file.path}',
        );
      }

      if (DocumentFileHelper.isDocxPath(file.path)) {
        return extractTextFromDocxBytes(bytes);
      }
      if (DocumentFileHelper.isDocPath(file.path)) {
        return extractTextFromDocBytes(bytes);
      }
      if (DocumentFileHelper.isXlsxPath(file.path)) {
        return extractTextFromXlsxBytes(bytes);
      }
      if (DocumentFileHelper.isXlsPath(file.path)) {
        return extractTextFromXlsBytes(bytes);
      }
      return await extractTextFromPdf(file);
    } on DocumentParseException {
      rethrow;
    } catch (e) {
      throw DocumentParseException(
        'Failed to extract text from ${file.path}: $e',
        e,
      );
    }
  }

  /// Alias to [extractDocumentText] preserved for existing callers.
  Future<String> extractTextFromFile(File file) => extractDocumentText(file);

  /// Extracts plain text directly from raw PDF [bytes].
  String extractTextFromBytes(Uint8List bytes) {
    return _extractPdfBytesInIsolate(bytes);
  }

  /// Extracts readable text from a `.docx` archive by parsing `word/document.xml`
  /// (plus optional Word header/footer XML parts) in paragraph and table order.
  String extractTextFromDocxBytes(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw DocumentParseException(
        'Invalid .docx archive structure: $e',
        e,
      );
    }

    final headerEntries = <ArchiveFile>[];
    ArchiveFile? documentEntry;
    final footerEntries = <ArchiveFile>[];

    for (final entry in archive) {
      if (!entry.isFile) continue;
      final normalizedName = entry.name.replaceAll('\\', '/').toLowerCase();
      if (normalizedName == 'word/document.xml') {
        documentEntry = entry;
      } else if (RegExp(r'^word/header\d*\.xml$').hasMatch(normalizedName)) {
        headerEntries.add(entry);
      } else if (RegExp(r'^word/footer\d*\.xml$').hasMatch(normalizedName)) {
        footerEntries.add(entry);
      }
    }

    if (documentEntry == null) {
      throw const DocumentParseException(
        'Invalid .docx document: word/document.xml was not found.',
      );
    }

    headerEntries.sort((a, b) => a.name.compareTo(b.name));
    footerEntries.sort((a, b) => a.name.compareTo(b.name));

    final sections = <String>[];

    for (final header in headerEntries) {
      final headerText = _extractWordXmlPart(header);
      if (headerText.isNotEmpty) {
        sections.add(headerText);
      }
    }

    final bodyText = _extractWordXmlPart(documentEntry);
    if (bodyText.isNotEmpty) {
      sections.add(bodyText);
    }

    for (final footer in footerEntries) {
      final footerText = _extractWordXmlPart(footer);
      if (footerText.isNotEmpty) {
        sections.add(footerText);
      }
    }

    return sections.join('\n\n').trim();
  }

  /// Extracts text from `.doc` files (handles ZIP/OOXML-renamed `.doc` as well as
  /// RTF or readable UTF-16LE / ASCII runs inside legacy binary `.doc` files).
  String extractTextFromDocBytes(Uint8List bytes) {
    // Some ".doc" files are actually OOXML ZIP archives or plain XML/text
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      return extractTextFromDocxBytes(bytes);
    }

    // Check UTF-8 / RTF / plain-text Word saves
    final headerSnippet = ascii.decode(
      bytes.take(32).toList(),
      allowInvalid: true,
    );
    if (headerSnippet.startsWith('{\\rtf')) {
      final rtfRaw = latin1.decode(bytes, allowInvalid: true);
      final stripped = rtfRaw
          .replaceAll(RegExp(r'\\par\b'), '\n')
          .replaceAll(RegExp(r'\\tab\b'), '\t')
          .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d*\s?'), '')
          .replaceAll(RegExp(r'[{}]'), '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      if (stripped.isNotEmpty) {
        return stripped;
      }
    }

    // Legacy CFBF binary .doc extraction fallback (collect printable sequences)
    final runs = <String>[];
    final current = StringBuffer();
    for (final byte in bytes) {
      if ((byte >= 0x20 && byte <= 0x7E) || byte == 0x0A || byte == 0x0D) {
        current.writeCharCode(byte);
      } else {
        if (current.length >= 12) {
          runs.add(current.toString().trim());
        }
        current.clear();
      }
    }
    if (current.length >= 12) {
      runs.add(current.toString().trim());
    }

    final filtered = runs
        .where((s) => RegExp(r'[A-Za-z0-9]{3,}').hasMatch(s))
        .where(
          (s) =>
              !s.contains('Microsoft Office Word') &&
              !s.contains('Root Entry') &&
              !s.contains('Word.Document'),
        )
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (filtered.isEmpty) {
      throw const DocumentParseException(
        'Unable to extract readable text from this legacy .doc file. Please save it as .docx or .pdf.',
      );
    }

    return filtered;
  }

  String _extractWordXmlPart(ArchiveFile entry) {
    final rawBytes = entry.readBytes();
    if (rawBytes == null || rawBytes.isEmpty) return '';

    final xmlSource = utf8.decode(rawBytes, allowMalformed: true);
    final xmlDoc = XmlDocument.parse(xmlSource);

    final bodyElements = xmlDoc.findAllElements('*').where(
          (e) => e.localName == 'body' || e.localName == 'hdr' || e.localName == 'ftr',
        );

    final blocks = <String>[];
    final container =
        bodyElements.isNotEmpty ? bodyElements.first : xmlDoc.rootElement;

    void visitBlockContainer(XmlElement element) {
      for (final child in element.children.whereType<XmlElement>()) {
        if (child.localName == 'p') {
          final text = _extractParagraphText(child);
          if (text.isNotEmpty) {
            blocks.add(text);
          }
        } else if (child.localName == 'tbl') {
          final tableText = _extractTableText(child);
          if (tableText.isNotEmpty) {
            blocks.add(tableText);
          }
        } else {
          visitBlockContainer(child);
        }
      }
    }

    visitBlockContainer(container);

    return blocks.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String _extractTableText(XmlElement tableElement) {
    final rowLines = <String>[];
    for (final row in tableElement.descendants.whereType<XmlElement>()) {
      if (row.localName != 'tr') continue;
      final cellTexts = <String>[];
      for (final cell in row.children.whereType<XmlElement>()) {
        if (cell.localName != 'tc') continue;
        final paraParts = <String>[];
        for (final p in cell.descendants.whereType<XmlElement>()) {
          if (p.localName == 'p') {
            final text = _extractParagraphText(p);
            if (text.isNotEmpty) {
              paraParts.add(text);
            }
          }
        }
        cellTexts.add(paraParts.join(' '));
      }
      final nonEmptyCells = cellTexts.where((c) => c.trim().isNotEmpty).toList();
      if (nonEmptyCells.isNotEmpty) {
        rowLines.add(nonEmptyCells.join(' | '));
      }
    }
    return rowLines.join('\n');
  }

  String _extractParagraphText(XmlElement paragraphElement) {
    final buffer = StringBuffer();

    void visit(XmlNode node) {
      if (node is XmlElement) {
        final name = node.localName;
        if (name == 'delText' || name == 'instrText') {
          return;
        }
        if (name == 't') {
          buffer.write(node.innerText);
          return;
        }
        if (name == 'tab') {
          buffer.write('\t');
          return;
        }
        if (name == 'br' || name == 'cr') {
          buffer.write('\n');
          return;
        }
      }
      for (final child in node.children) {
        visit(child);
      }
    }

    visit(paragraphElement);
    return buffer.toString().trim();
  }

  /// Parses CSV text into pipe-separated (` | `) rows suitable for LLM auditing.
  String extractTextFromCsvString(String input) {
    var normalized = input;
    if (normalized.startsWith('\uFEFF')) {
      normalized = normalized.substring(1);
    }
    normalized = normalized.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
      csvSettingsDetector: FirstOccurrenceSettingsDetector(
        fieldDelimiters: [',', ';', '\t'],
        eols: ['\n'],
      ),
    ).convert(normalized);

    final formattedRows = <String>[];
    for (final row in rows) {
      final cells = row.map((cell) => cell.toString().trim()).toList();
      if (cells.any((c) => c.isNotEmpty)) {
        formattedRows.add(cells.join(' | '));
      }
    }

    return formattedRows.join('\n').trim();
  }

  /// Extracts pipe-delimited tabular sheets from an `.xlsx` OpenXML workbook
  /// via `xl/workbook.xml`, `xl/sharedStrings.xml`, and `xl/worksheets/sheet*.xml`.
  String extractTextFromXlsxBytes(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw DocumentParseException(
        'Invalid .xlsx archive structure: $e',
        e,
      );
    }

    final fileMap = <String, ArchiveFile>{};
    for (final entry in archive) {
      if (!entry.isFile) continue;
      fileMap[entry.name.replaceAll('\\', '/').toLowerCase()] = entry;
    }

    final sharedStrings = _parseXlsxSharedStrings(fileMap['xl/sharedstrings.xml']);
    final orderedSheets = _resolveOrderedXlsxSheets(fileMap);

    if (orderedSheets.isEmpty) {
      throw const DocumentParseException(
        'Invalid .xlsx workbook: no worksheets found.',
      );
    }

    final sheetSections = <String>[];
    for (final sheet in orderedSheets) {
      final sheetText = _extractXlsxWorksheetText(
        entry: sheet.entry,
        sharedStrings: sharedStrings,
      );
      if (sheetText.isNotEmpty) {
        sheetSections.add('=== Sheet: ${sheet.name} ===\n$sheetText');
      }
    }

    return sheetSections.join('\n\n').trim();
  }

  /// Extracts spreadsheet data from `.xls` files (supports OOXML-renamed ZIPs,
  /// SpreadsheetML XML, or plain text/TSV `.xls` exports).
  String extractTextFromXlsBytes(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      return extractTextFromXlsxBytes(bytes);
    }

    final hasBinaryNulls = bytes.take(512).contains(0);
    if (!hasBinaryNulls) {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (text.contains('<Workbook') && text.contains('<Row')) {
        final xmlParsed = _extractSpreadsheetMlText(text);
        if (xmlParsed.isNotEmpty) {
          return xmlParsed;
        }
      }
      if (text.isNotEmpty) {
        final csvParsed = extractTextFromCsvString(text);
        if (csvParsed.isNotEmpty) {
          return csvParsed;
        }
      }
    }

    throw const DocumentParseException(
      'Legacy binary .xls workbooks cannot be parsed cleanly. Please save the file as .xlsx or .csv.',
    );
  }

  List<String> _parseXlsxSharedStrings(ArchiveFile? entry) {
    if (entry == null) return const [];
    final raw = entry.readBytes();
    if (raw == null || raw.isEmpty) return const [];

    final doc = XmlDocument.parse(utf8.decode(raw, allowMalformed: true));
    final strings = <String>[];
    for (final si in doc.findAllElements('*').where((e) => e.localName == 'si')) {
      final buffer = StringBuffer();
      void collectText(XmlNode node) {
        if (node is XmlElement) {
          if (node.localName == 'rPh') return;
          if (node.localName == 't') {
            buffer.write(node.innerText);
            return;
          }
        }
        for (final child in node.children) {
          collectText(child);
        }
      }

      collectText(si);
      strings.add(buffer.toString());
    }
    return strings;
  }

  List<({String name, ArchiveFile entry})> _resolveOrderedXlsxSheets(
    Map<String, ArchiveFile> fileMap,
  ) {
    final relTargets = <String, String>{};
    final relsEntry = fileMap['xl/_rels/workbook.xml.rels'];
    if (relsEntry != null) {
      final raw = relsEntry.readBytes();
      if (raw != null && raw.isNotEmpty) {
        final relDoc = XmlDocument.parse(utf8.decode(raw, allowMalformed: true));
        for (final rel in relDoc
            .findAllElements('*')
            .where((e) => e.localName == 'Relationship')) {
          final id = rel.getAttribute('Id');
          final target = rel.getAttribute('Target');
          if (id != null && target != null) {
            var normalized = target.replaceAll('\\', '/').toLowerCase();
            if (normalized.startsWith('/')) {
              normalized = normalized.substring(1);
            } else if (!normalized.startsWith('xl/')) {
              normalized = 'xl/$normalized';
            }
            relTargets[id] = normalized;
          }
        }
      }
    }

    final resolved = <({String name, ArchiveFile entry})>[];
    final workbookEntry = fileMap['xl/workbook.xml'];
    if (workbookEntry != null) {
      final raw = workbookEntry.readBytes();
      if (raw != null && raw.isNotEmpty) {
        final wbDoc = XmlDocument.parse(utf8.decode(raw, allowMalformed: true));
        for (final sheet in wbDoc
            .findAllElements('*')
            .where((e) => e.localName == 'sheet')) {
          final name = sheet.getAttribute('name') ?? 'Sheet';
          String? rId;
          for (final attr in sheet.attributes) {
            if (attr.localName == 'id') {
              rId = attr.value;
              break;
            }
          }
          final targetPath = rId != null ? relTargets[rId] : null;
          final targetFile = targetPath != null ? fileMap[targetPath] : null;
          if (targetFile != null) {
            resolved.add((name: name, entry: targetFile));
          }
        }
      }
    }

    if (resolved.isNotEmpty) return resolved;

    final sheetKeys = fileMap.keys
        .where((k) => RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(k))
        .toList()
      ..sort();
    for (var i = 0; i < sheetKeys.length; i++) {
      final entry = fileMap[sheetKeys[i]]!;
      resolved.add((name: 'Sheet${i + 1}', entry: entry));
    }
    return resolved;
  }

  String _extractXlsxWorksheetText({
    required ArchiveFile entry,
    required List<String> sharedStrings,
  }) {
    final raw = entry.readBytes();
    if (raw == null || raw.isEmpty) return '';

    final doc = XmlDocument.parse(utf8.decode(raw, allowMalformed: true));
    final lines = <String>[];

    for (final row in doc.findAllElements('*').where((e) => e.localName == 'row')) {
      final cellsByCol = <int, String>{};
      var maxCol = -1;
      var sequentialCol = 0;

      for (final cell in row.children.whereType<XmlElement>()) {
        if (cell.localName != 'c') continue;
        final refCol = _columnIndexFromRef(cell.getAttribute('r'));
        final colIndex = refCol ?? sequentialCol;
        sequentialCol = colIndex + 1;
        if (colIndex > maxCol) maxCol = colIndex;

        final value = _extractXlsxCellValue(cell, sharedStrings).trim();
        if (value.isNotEmpty) {
          cellsByCol[colIndex] = value;
        }
      }

      if (cellsByCol.isEmpty || maxCol < 0) continue;

      final denseRow = List<String>.generate(
        maxCol + 1,
        (idx) => cellsByCol[idx] ?? '',
      );
      while (denseRow.isNotEmpty && denseRow.last.isEmpty) {
        denseRow.removeLast();
      }
      if (denseRow.any((c) => c.isNotEmpty)) {
        lines.add(denseRow.join(' | '));
      }
    }

    return lines.join('\n').trim();
  }

  String _extractXlsxCellValue(
    XmlElement cellElement,
    List<String> sharedStrings,
  ) {
    final cellType = cellElement.getAttribute('t');
    if (cellType == 'inlineStr') {
      final buffer = StringBuffer();
      for (final t in cellElement
          .findAllElements('*')
          .where((e) => e.localName == 't')) {
        buffer.write(t.innerText);
      }
      return buffer.toString();
    }

    String? vText;
    for (final child in cellElement.children.whereType<XmlElement>()) {
      if (child.localName == 'v') {
        vText = child.innerText;
        break;
      }
    }
    if (vText == null) return '';

    if (cellType == 's') {
      final idx = int.tryParse(vText.trim());
      if (idx != null && idx >= 0 && idx < sharedStrings.length) {
        return sharedStrings[idx];
      }
      return '';
    }
    if (cellType == 'b') {
      return vText.trim() == '1' ? 'TRUE' : 'FALSE';
    }
    return vText;
  }

  int? _columnIndexFromRef(String? cellRef) {
    if (cellRef == null || cellRef.isEmpty) return null;
    final match = RegExp(r'^([A-Za-z]+)').firstMatch(cellRef.trim());
    if (match == null) return null;
    final letters = match.group(1)!.toUpperCase();
    var col = 0;
    for (var i = 0; i < letters.length; i++) {
      col = col * 26 + (letters.codeUnitAt(i) - 64);
    }
    return col - 1;
  }

  String _extractSpreadsheetMlText(String xmlSource) {
    final doc = XmlDocument.parse(xmlSource);
    final sections = <String>[];

    for (final ws in doc
        .findAllElements('*')
        .where((e) => e.localName == 'Worksheet')) {
      final sheetName = ws.attributes
              .where((a) => a.localName == 'Name')
              .map((a) => a.value)
              .firstOrNull ??
          'Sheet1';
      final rows = <String>[];
      for (final row in ws.findAllElements('*').where((e) => e.localName == 'Row')) {
        final cells = <String>[];
        for (final cell in row.children.whereType<XmlElement>()) {
          if (cell.localName != 'Cell') continue;
          final dataText = cell
              .findAllElements('*')
              .where((e) => e.localName == 'Data')
              .map((e) => e.innerText.trim())
              .join(' ');
          cells.add(dataText);
        }
        if (cells.any((c) => c.isNotEmpty)) {
          rows.add(cells.join(' | '));
        }
      }
      if (rows.isNotEmpty) {
        sections.add('=== Sheet: $sheetName ===\n${rows.join('\n')}');
      }
    }

    return sections.join('\n\n').trim();
  }

  /// Extracts party and document reference metadata (`vendorName`, `clientName`,
  /// `invoiceNumber`, `contractReference`) from invoice and contract headers.
  static ExtractedPartyMetadata extractPartyMetadata({
    String contractText = '',
    String invoiceText = '',
  }) {
    String? sanitizeValue(String? raw) {
      if (raw == null) return null;
      var value = raw.split(' | ').first.trim();
      value = value.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      if (value.isEmpty) return null;
      final lower = value.toLowerCase();
      if (lower == 'n/a' ||
          lower == 'none' ||
          lower == 'unknown' ||
          lower == 'null') {
        return null;
      }
      return value;
    }

    List<String> headerLines(String text) {
      if (text.trim().isEmpty || text.startsWith('[Document Descriptor Fallback]')) {
        return const [];
      }
      return text
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where(
            (l) =>
                l.isNotEmpty &&
                !l.startsWith('--- Page') &&
                !l.startsWith('=== Sheet') &&
                !l.startsWith('[Document Descriptor'),
          )
          .take(30)
          .toList();
    }

    final invoiceLines = headerLines(invoiceText);
    final contractLines = headerLines(contractText);

    String? matchLabeledLine(List<String> lines, RegExp pattern) {
      for (final line in lines) {
        final m = pattern.firstMatch(line);
        if (m != null) {
          final candidate = sanitizeValue(m.group(1));
          if (candidate != null && !candidate.contains('@')) {
            return candidate;
          }
        }
      }
      return null;
    }

    final vendorLabelPattern = RegExp(
      r'^(?:Vendor|Supplier|Service\s+Provider|Provider|Contractor|From|Billed\s+By|Issued\s+By|Remit\s+To)\s*[:|\-]\s*(.+)$',
      caseSensitive: false,
    );
    final corpSuffixPattern = RegExp(
      r'\b(?:LLC|L\.L\.C\.|Inc\.?|Corp\.?|Corporation|Ltd\.?|Limited|LLP|GmbH|PLC)\b\.?$',
      caseSensitive: false,
    );
    final stopHeaderPattern = RegExp(
      r'^(?:invoice|tax\s+invoice|bill\s+to|ship\s+to|remit\s+to|client|customer|date|due\s+date|contract|agreement|master\s+services|statement\s+of\s+work|description|line\s+item)',
      caseSensitive: false,
    );

    String? vendorName =
        matchLabeledLine(invoiceLines, vendorLabelPattern) ??
            matchLabeledLine(contractLines, vendorLabelPattern);

    if (vendorName == null) {
      for (final line in invoiceLines.take(15)) {
        final cleaned = sanitizeValue(line);
        if (cleaned == null || stopHeaderPattern.hasMatch(cleaned)) continue;
        if (corpSuffixPattern.hasMatch(cleaned) && cleaned.length <= 80) {
          vendorName = cleaned;
          break;
        }
      }
    }

    final clientLabelPattern = RegExp(
      r'^(?:Bill\s+To|Billed\s+To|Client(?:\s+Name)?|Customer(?:\s+Name)?|Payor|Contracting\s+Party|Prepared\s+For)\s*[:|\-]\s*(.+)$',
      caseSensitive: false,
    );
    String? clientName =
        matchLabeledLine(invoiceLines, clientLabelPattern) ??
            matchLabeledLine(contractLines, clientLabelPattern);

    final invoiceNumPattern = RegExp(
      r'\b(?:Invoice\s*(?:#|Number\b|No\.?|Reference\b|Ref\.?|ID\b)|INV\s*#)(?:\s*[:\-]\s*|\s+)([A-Z0-9][A-Z0-9\-/]{2,})',
      caseSensitive: false,
    );
    String? invoiceNumber;
    for (final line in invoiceLines) {
      final m = invoiceNumPattern.firstMatch(line);
      if (m != null) {
        invoiceNumber = sanitizeValue(m.group(1));
        break;
      }
    }
    invoiceNumber ??= RegExp(r'\b(INV[-_][A-Z0-9\-]{2,})\b', caseSensitive: false)
        .firstMatch(invoiceLines.join('\n'))
        ?.group(1);

    final contractRefPattern = RegExp(
      r'\b(?:Contract|Agreement|MSA|SOW)\s*(?:#|Reference\b|Ref\.?|Number\b|No\.?|ID\b)(?:\s*[:\-]\s*|\s+)([A-Z0-9][A-Z0-9\-/]{2,})',
      caseSensitive: false,
    );
    String? contractRef;
    for (final line in [...invoiceLines, ...contractLines]) {
      final m = contractRefPattern.firstMatch(line);
      if (m != null) {
        contractRef = sanitizeValue(m.group(1));
        break;
      }
    }
    contractRef ??= RegExp(
      r'\b((?:MSA|SOW)[-_][A-Z0-9\-]{2,})\b',
      caseSensitive: false,
    ).firstMatch([...contractLines, ...invoiceLines].join('\n'))?.group(1);

    final emailRegex = RegExp(
      r'\b([A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,})\b',
    );
    String? vendorEmail;
    final billingEmailPattern = RegExp(
      r'^(?:billing|ar|accounts(?:\.?receivable)?|invoices?|finance|remit)@',
      caseSensitive: false,
    );
    for (final line in invoiceLines) {
      if (clientLabelPattern.hasMatch(line)) continue;
      for (final match in emailRegex.allMatches(line)) {
        final candidate = match.group(1);
        if (candidate == null) continue;
        if (billingEmailPattern.hasMatch(candidate)) {
          vendorEmail = candidate;
          break;
        }
        vendorEmail ??= candidate;
      }
      if (vendorEmail != null && billingEmailPattern.hasMatch(vendorEmail)) {
        break;
      }
    }

    return ExtractedPartyMetadata(
      vendorName: vendorName,
      vendorEmail: vendorEmail,
      clientName: clientName,
      invoiceNumber: invoiceNumber,
      contractReference: contractRef,
    );
  }
}

class ExtractedPartyMetadata {
  final String? vendorName;
  final String? vendorEmail;
  final String? clientName;
  final String? invoiceNumber;
  final String? contractReference;

  const ExtractedPartyMetadata({
    this.vendorName,
    this.vendorEmail,
    this.clientName,
    this.invoiceNumber,
    this.contractReference,
  });
}

