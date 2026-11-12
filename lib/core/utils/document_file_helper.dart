import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'file_hasher.dart';

class PickedDocumentMetadata {
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final String sha256Hash;

  const PickedDocumentMetadata({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.sha256Hash,
  });
}

class PickedDocumentOutcome {
  final PickedDocumentMetadata? metadata;
  final String? errorMessage;

  const PickedDocumentOutcome({
    this.metadata,
    this.errorMessage,
  });

  bool get isCancelled => metadata == null && errorMessage == null;
}

class DocumentFileHelper {
  DocumentFileHelper._();

  static const List<String> supportedExtensions = [
    'pdf',
    'docx',
    'doc',
    'csv',
    'xlsx',
    'xls',
  ];

  static String extensionOf(String path) {
    final normalized = path.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == normalized.length - 1) {
      return '';
    }
    return normalized.substring(dotIndex + 1);
  }

  static bool isPdfPath(String path) => extensionOf(path) == 'pdf';

  static bool isDocxPath(String path) => extensionOf(path) == 'docx';

  static bool isDocPath(String path) => extensionOf(path) == 'doc';

  static bool isCsvPath(String path) => extensionOf(path) == 'csv';

  static bool isXlsxPath(String path) => extensionOf(path) == 'xlsx';

  static bool isXlsPath(String path) => extensionOf(path) == 'xls';

  static bool isWordPath(String path) {
    final ext = extensionOf(path);
    return ext == 'docx' || ext == 'doc';
  }

  static bool isSpreadsheetPath(String path) {
    final ext = extensionOf(path);
    return ext == 'csv' || ext == 'xlsx' || ext == 'xls';
  }

  static bool isSupportedExtension(String path) {
    return supportedExtensions.contains(extensionOf(path));
  }

  static Future<PickedDocumentOutcome> pickAndValidate({
    required String dialogTitle,
  }) async {
    final pickedFile = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
    );

    if (pickedFile == null) {
      return const PickedDocumentOutcome();
    }

    final path = pickedFile.path;
    if (path == null || path.isEmpty) {
      return const PickedDocumentOutcome(
        errorMessage: 'Selected file path could not be resolved.',
      );
    }

    final file = File(path);
    if (!await file.exists()) {
      return const PickedDocumentOutcome(
        errorMessage: 'Selected file does not exist on disk.',
      );
    }

    if (!isSupportedExtension(path)) {
      return const PickedDocumentOutcome(
        errorMessage:
            'Only PDF, Word (.docx, .doc), and Spreadsheet (.csv, .xlsx, .xls) files are supported.',
      );
    }

    final fileSizeBytes = await file.length();
    if (fileSizeBytes == 0) {
      return const PickedDocumentOutcome(
        errorMessage: 'Selected document file is empty (0 bytes).',
      );
    }

    final hash = await FileHasher.computeSha256(path);

    return PickedDocumentOutcome(
      metadata: PickedDocumentMetadata(
        filePath: path,
        fileName: pickedFile.name,
        fileSizeBytes: fileSizeBytes,
        sha256Hash: hash,
      ),
    );
  }
}
