import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/security/secure_storage_service.dart';
import '../models/dispute_models.dart';
import 'dispute_pdf_exporter.dart';

typedef SmtpSendFn = Future<SendReport> Function(
  Message message,
  SmtpServer server, {
  Duration? timeout,
});

/// SMTP server configuration used when dispatching dispute emails.
class SmtpConfig {
  final String host;
  final int port;
  final String username;
  final String password;
  final String fromEmail;
  final bool useSsl;

  const SmtpConfig({
    this.host = 'smtp.gmail.com',
    this.port = 587,
    this.username = '',
    this.password = '',
    this.fromEmail = '',
    this.useSsl = false,
  });

  factory SmtpConfig.fromEnvOrDefaults() {
    String readEnv(String key) {
      if (!dotenv.isInitialized) return '';
      return dotenv.env[key]?.trim() ?? '';
    }

    final host = readEnv('SMTP_HOST');
    final port = int.tryParse(readEnv('SMTP_PORT')) ?? 587;
    final username = readEnv('SMTP_USERNAME');
    final password = readEnv('SMTP_PASSWORD');
    final fromEmail = readEnv('SMTP_FROM');
    final useSslEnv = readEnv('SMTP_USE_SSL').toLowerCase();

    return SmtpConfig(
      host: host.isNotEmpty ? host : 'smtp.gmail.com',
      port: port,
      username: username,
      password: password,
      fromEmail: fromEmail.isNotEmpty ? fromEmail : username,
      useSsl: useSslEnv == 'true' || port == 465,
    );
  }
}

class DispatchResult {
  final String channel;
  final String destination;
  final String? attachmentFileName;
  final int? statusCode;
  final DateTime dispatchedAt;

  const DispatchResult({
    required this.channel,
    required this.destination,
    this.attachmentFileName,
    this.statusCode,
    required this.dispatchedAt,
  });
}

/// Handles outbound SMTP email (with PDF attachment) and JSON webhook dispatch
/// for completed formal dispute notices.
class DisputeDispatchService {
  static const String pdfAttachmentFileName = 'ClairDocs_Dispute_Notice.pdf';

  final http.Client? httpClient;
  final DisputePdfExporter pdfExporter;
  final SmtpSendFn? smtpSender;
  final SecureStorageService secureStorage;

  const DisputeDispatchService({
    this.httpClient,
    this.pdfExporter = const DisputePdfExporter(),
    this.smtpSender,
    this.secureStorage = const SecureStorageService(),
  });

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  /// Builds the enterprise JSON payload dispatched to Webhook endpoints.
  static Map<String, dynamic> buildWebhookPayload({
    required DisputeState disputeState,
    String? noticeTextOverride,
    DateTime? timestamp,
  }) {
    final effectiveNotice =
        (noticeTextOverride != null && noticeTextOverride.trim().isNotEmpty)
            ? noticeTextOverride
            : disputeState.draftText;

    return <String, dynamic>{
      'vendorName': disputeState.vendorName,
      'invoicedTotal': disputeState.totalInvoiced,
      'approvedRelease': disputeState.approvedPayment,
      'withheldAmount': disputeState.totalWithheld,
      'discrepancyCount': disputeState.sourceAuditResult?.findings.length ?? 0,
      'disputeNoticeText': effectiveNotice,
      'timestamp': (timestamp ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  /// Dispatches the formal dispute notice text via SMTP with
  /// [pdfAttachmentFileName] automatically attached.
  Future<DispatchResult> dispatchEmail({
    required DisputeState disputeState,
    required String toEmail,
    required String subject,
    required String bodyText,
    SmtpConfig? smtpConfig,
    bool persistCredentials = true,
  }) async {
    final trimmedTo = toEmail.trim();
    if (!_emailPattern.hasMatch(trimmedTo)) {
      throw const ClairException(
        'Please enter a valid vendor Accounts Receivable email address.',
      );
    }

    final trimmedSubject = subject.trim();
    if (trimmedSubject.isEmpty) {
      throw const ClairException('Email subject line cannot be empty.');
    }

    final config = smtpConfig ?? SmtpConfig.fromEnvOrDefaults();
    final trimmedHost = config.host.trim();
    final trimmedUsername = config.username.trim();
    final effectiveFrom = config.fromEmail.trim().isNotEmpty
        ? config.fromEmail.trim()
        : trimmedUsername;

    if (trimmedHost.isEmpty) {
      throw const ClairException('SMTP host is required (e.g. smtp.gmail.com).');
    }
    if (trimmedUsername.isEmpty || effectiveFrom.isEmpty) {
      throw const ClairException(
        'SMTP username / sender address is required to authenticate dispatch.',
      );
    }

    final pdfBytes = await pdfExporter.buildDisputePdfBytes(
      disputeState: disputeState,
    );

    final message = Message()
      ..from = Address(effectiveFrom, disputeState.clientName)
      ..recipients.add(trimmedTo)
      ..subject = trimmedSubject
      ..text = bodyText
      ..attachments = [
        StreamAttachment(
          Stream<List<int>>.value(pdfBytes),
          'application/pdf',
          fileName: pdfAttachmentFileName,
        ),
      ];

    final server = SmtpServer(
      trimmedHost,
      port: config.port,
      username: trimmedUsername,
      password: config.password,
      ssl: config.useSsl,
    );

    final sender = smtpSender ?? send;
    try {
      await sender(
        message,
        server,
        timeout: const Duration(seconds: 15),
      );
    } on ClairException {
      rethrow;
    } catch (e) {
      throw ClairException('SMTP email dispatch failed: $e', e);
    }

    try {
      if (persistCredentials) {
        await secureStorage.saveSmtpCredentials(
          host: trimmedHost,
          port: config.port,
          username: trimmedUsername,
          password: config.password,
        );
      } else {
        await secureStorage.deleteSmtpCredentials();
      }
    } catch (_) {
      // Non-fatal: email dispatch already succeeded cleanly.
    }

    return DispatchResult(
      channel: 'email',
      destination: trimmedTo,
      attachmentFileName: pdfAttachmentFileName,
      dispatchedAt: DateTime.now().toUtc(),
    );
  }

  /// Posts the structured dispute JSON payload to an enterprise Webhook URL
  /// (Slack Incoming Webhook, Microsoft Teams, or Zapier).
  Future<DispatchResult> dispatchWebhook({
    required String webhookUrl,
    required DisputeState disputeState,
    String? noticeTextOverride,
  }) async {
    final trimmedUrl = webhookUrl.trim();
    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.trim().isEmpty) {
      throw const ClairException(
        'Please enter a valid HTTP or HTTPS Webhook URL.',
      );
    }

    final payload = buildWebhookPayload(
      disputeState: disputeState,
      noticeTextOverride: noticeTextOverride,
    );

    final client = httpClient ?? http.Client();
    final ownsClient = httpClient == null;
    try {
      final response = await client
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final snippet = response.body.length > 160
            ? '${response.body.substring(0, 160)}...'
            : response.body;
        throw ClairException(
          'Webhook endpoint returned HTTP ${response.statusCode}'
          '${snippet.trim().isNotEmpty ? ': $snippet' : '.'}',
        );
      }

      return DispatchResult(
        channel: 'webhook',
        destination: trimmedUrl,
        statusCode: response.statusCode,
        dispatchedAt: DateTime.now().toUtc(),
      );
    } on TimeoutException {
      throw const ClairException(
        'Webhook request timed out after 12 seconds.',
      );
    } on ClairException {
      rethrow;
    } catch (e) {
      throw ClairException('Webhook dispatch failed: $e', e);
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }
}
