import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/history/services/audit_database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kReleaseMode) {
    try {
      final localEnv =
          File('${Directory.current.path}${Platform.pathSeparator}.env');
      if (await localEnv.exists()) {
        dotenv.loadFromString(envString: await localEnv.readAsString());
      }
    } catch (_) {
      // Allow app startup if .env is unavailable; falls back to --dart-define or in-app key storage
    }
  }
  await AuditDatabaseService.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ClairDocsApp(),
    ),
  );
}
