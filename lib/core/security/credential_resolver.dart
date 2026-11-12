import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Shared API credential resolution helper enforcing precedence:
/// OS secure storage > initialized dotenv (dev/test) > --dart-define >
/// in-memory provider fallback > dev-only disk `.env` probe.
class CredentialResolver {
  CredentialResolver._();

  static Future<String?> resolveApiKey({
    required String envKeyName,
    required Future<String?> Function() readSecureStorage,
    required String compileTimeKey,
    String? Function()? inAppKeyReader,
    Duration secureStorageTimeout = const Duration(seconds: 2),
  }) async {
    // 1. Primary: User-configured OS secure credential storage
    try {
      final storedKey = await readSecureStorage()
          .timeout(secureStorageTimeout, onTimeout: () => null);
      if (storedKey != null && storedKey.trim().isNotEmpty) {
        return storedKey.trim();
      }
    } catch (_) {
      // Ignore secure storage platform channel failures in headless/test runs
    }

    // 2. Dev/test fallback: Initialized flutter_dotenv (never bundled in release)
    if (!kReleaseMode && dotenv.isInitialized) {
      final dotEnvKey = dotenv.env[envKeyName]?.trim();
      if (dotEnvKey != null && dotEnvKey.isNotEmpty) {
        return dotEnvKey;
      }
    }

    // 3. Compile-time --dart-define override
    final trimmedCompile = compileTimeKey.trim();
    if (trimmedCompile.isNotEmpty) {
      return trimmedCompile;
    }

    // 4. In-memory provider fallback
    final inAppKey = inAppKeyReader?.call()?.trim();
    if (inAppKey != null && inAppKey.isNotEmpty) {
      return inAppKey;
    }

    // 5. Dev-only filesystem `.env` probe (disabled in release builds)
    final diskKey = await readDevDotEnvKey(envKeyName);
    if (diskKey != null && diskKey.isNotEmpty) {
      return diskKey;
    }

    return null;
  }

  /// Reads [keyName] from `Directory.current/.env` only outside release builds.
  static Future<String?> readDevDotEnvKey(String keyName) async {
    if (kReleaseMode) return null;
    try {
      final envFile =
          File('${Directory.current.path}${Platform.pathSeparator}.env');
      if (!await envFile.exists()) return null;

      final prefix = '$keyName=';
      final lines = await envFile.readAsLines();
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        if (line.startsWith(prefix)) {
          var value = line.substring(prefix.length).trim();
          if ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'"))) {
            value = value.substring(1, value.length - 1);
          }
          return value.trim();
        }
      }
    } catch (_) {
      // Ignore fallback file access errors
    }
    return null;
  }
}
