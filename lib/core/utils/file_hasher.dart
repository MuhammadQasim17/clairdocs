import 'dart:io';
import 'package:crypto/crypto.dart';

class FileHasher {
  FileHasher._();

  static Future<String> computeSha256(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  static String hashBytes(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}

