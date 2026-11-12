import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted SMTP server settings loaded from secure storage.
class StoredSmtpCredentials {
  final String? host;
  final int? port;
  final String? username;
  final String? password;

  const StoredSmtpCredentials({
    this.host,
    this.port,
    this.username,
    this.password,
  });

  bool get hasAny =>
      (host != null && host!.isNotEmpty) ||
      port != null ||
      (username != null && username!.isNotEmpty) ||
      (password != null && password!.isNotEmpty);
}

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _geminiApiKeyKey = 'clairdocs_gemini_api_key';
  static const String _groqApiKeyKey = 'clairdocs_groq_api_key';
  static const String _smtpHostKey = 'clairdocs_smtp_host';
  static const String _smtpPortKey = 'clairdocs_smtp_port';
  static const String _smtpUsernameKey = 'clairdocs_smtp_username';
  static const String _smtpPasswordKey = 'clairdocs_smtp_password';

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKeyKey, value: apiKey.trim());
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: _geminiApiKeyKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _geminiApiKeyKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  /// Saves the user-configured Groq API key in OS secure storage.
  Future<void> saveGroqApiKey(String apiKey) async {
    await _storage.write(key: _groqApiKeyKey, value: apiKey.trim());
  }

  /// Reads the stored Groq API key from OS secure storage, if present.
  Future<String?> getGroqApiKey() async {
    return _storage.read(key: _groqApiKeyKey);
  }

  Future<void> deleteGroqApiKey() async {
    await _storage.delete(key: _groqApiKeyKey);
  }

  Future<bool> hasGroqApiKey() async {
    final key = await getGroqApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  /// Persists SMTP settings in OS-level secure storage.
  Future<void> saveSmtpCredentials({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(key: _smtpHostKey, value: host.trim()),
      _storage.write(key: _smtpPortKey, value: port.toString()),
      _storage.write(key: _smtpUsernameKey, value: username.trim()),
      _storage.write(key: _smtpPasswordKey, value: password),
    ]);
  }

  /// Reads stored SMTP settings, returning null fields where absent.
  Future<StoredSmtpCredentials> getSmtpCredentials() async {
    final results = await Future.wait([
      _storage.read(key: _smtpHostKey),
      _storage.read(key: _smtpPortKey),
      _storage.read(key: _smtpUsernameKey),
      _storage.read(key: _smtpPasswordKey),
    ]);

    final host = results[0]?.trim();
    final port = int.tryParse(results[1]?.trim() ?? '');
    final username = results[2]?.trim();
    final password = results[3];

    return StoredSmtpCredentials(
      host: (host != null && host.isNotEmpty) ? host : null,
      port: port,
      username: (username != null && username.isNotEmpty) ? username : null,
      password: (password != null && password.isNotEmpty) ? password : null,
    );
  }

  Future<void> deleteSmtpCredentials() async {
    await Future.wait([
      _storage.delete(key: _smtpHostKey),
      _storage.delete(key: _smtpPortKey),
      _storage.delete(key: _smtpUsernameKey),
      _storage.delete(key: _smtpPasswordKey),
    ]);
  }
}

