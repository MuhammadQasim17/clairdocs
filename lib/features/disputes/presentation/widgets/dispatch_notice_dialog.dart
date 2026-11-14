import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/enterprise_dialog_chrome.dart';
import '../../../audit/presentation/widgets/settings_dialog.dart';
import '../../models/dispute_models.dart';
import '../../providers/dispute_provider.dart';
import '../../services/dispute_dispatch_service.dart';

enum _DispatchChannel { email, webhook }

/// Modal dialog allowing the user to dispatch the active dispute notice either
/// via SMTP Email (with `ClairDocs_Dispute_Notice.pdf` attached) or to an
/// enterprise JSON Webhook URL.
class DispatchNoticeDialog extends ConsumerStatefulWidget {
  final DisputeState disputeState;
  final String noticeText;
  final FlutterSecureStorage? secureStorage;
  final bool isFullScreen;

  const DispatchNoticeDialog({
    super.key,
    required this.disputeState,
    required this.noticeText,
    this.secureStorage,
    this.isFullScreen = false,
  });

  @override
  ConsumerState<DispatchNoticeDialog> createState() =>
      _DispatchNoticeDialogState();
}

class _DispatchNoticeDialogState extends ConsumerState<DispatchNoticeDialog> {
  _DispatchChannel _selectedChannel = _DispatchChannel.email;
  bool _isSending = false;
  bool _showPassword = false;
  bool _hasEditedSmtp = false;
  bool _loadedFromStoreRoom = false;
  String? _errorMessage;

  late final TextEditingController _toEmailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _smtpHostController;
  late final TextEditingController _smtpPortController;
  late final TextEditingController _smtpUserController;
  late final TextEditingController _smtpPassController;
  late final TextEditingController _webhookUrlController;

  @override
  void initState() {
    super.initState();
    final defaults = SmtpConfig.fromEnvOrDefaults();
    final d = widget.disputeState;

    _toEmailController = TextEditingController(text: d.vendorEmail);
    _subjectController = TextEditingController(
      text:
          'Formal Notice of Invoice Discrepancy - ${d.invoiceReference} (${d.vendorName})',
    );
    _smtpHostController = TextEditingController(text: defaults.host);
    _smtpPortController = TextEditingController(text: '${defaults.port}');
    _smtpUserController = TextEditingController(text: defaults.username);
    _smtpPassController = TextEditingController(text: defaults.password);
    _webhookUrlController = TextEditingController();

    _loadSavedSmtpCredentials();
  }

  SecureStorageService get _secureStorage => widget.secureStorage != null
      ? SecureStorageService(storage: widget.secureStorage)
      : ref.read(secureStorageServiceProvider);

  Future<void> _loadSavedSmtpCredentials({
    bool resetWhenEmpty = false,
  }) async {
    try {
      final saved = await _secureStorage.getSmtpCredentials();
      if (!mounted || _hasEditedSmtp) return;
      if (!saved.hasAny) {
        if (resetWhenEmpty) {
          final defaults = SmtpConfig.fromEnvOrDefaults();
          setState(() {
            _loadedFromStoreRoom = false;
            _smtpHostController.text = defaults.host;
            _smtpPortController.text = '${defaults.port}';
            _smtpUserController.text = defaults.username;
            _smtpPassController.text = defaults.password;
          });
        }
        return;
      }
      setState(() {
        _loadedFromStoreRoom = true;
        if (saved.host != null) {
          _smtpHostController.text = saved.host!;
        }
        if (saved.port != null) {
          _smtpPortController.text = '${saved.port!}';
        }
        if (saved.username != null) {
          _smtpUserController.text = saved.username!;
        }
        if (saved.password != null) {
          _smtpPassController.text = saved.password!;
        }
      });
    } catch (_) {
      // Keep default/.env values if OS secure storage cannot be read.
    }
  }

  Future<void> _openSettingsStoreRoom() async {
    if (_isSending) return;
    if (widget.isFullScreen) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SettingsDialog(
            secureStorage: widget.secureStorage,
            isFullScreen: true,
            showBackButton: true,
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => SettingsDialog(secureStorage: widget.secureStorage),
      );
    }
    if (!mounted) return;
    _hasEditedSmtp = false;
    await _loadSavedSmtpCredentials(resetWhenEmpty: true);
  }

  @override
  void dispose() {
    _toEmailController.dispose();
    _subjectController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPassController.dispose();
    _webhookUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(disputeDispatchServiceProvider);
      final parsedPort = int.tryParse(_smtpPortController.text.trim()) ?? 587;
      final config = SmtpConfig(
        host: _smtpHostController.text.trim(),
        port: parsedPort,
        username: _smtpUserController.text.trim(),
        password: _smtpPassController.text,
        fromEmail: _smtpUserController.text.trim(),
        useSsl: parsedPort == 465,
      );

      final result = await service.dispatchEmail(
        disputeState: widget.disputeState.copyWith(draftText: widget.noticeText),
        toEmail: _toEmailController.text,
        subject: _subjectController.text,
        bodyText: widget.noticeText,
        smtpConfig: config,
      );

      final storage = _secureStorage;
      if (!identical(storage, service.secureStorage)) {
        try {
          await storage.saveSmtpCredentials(
            host: config.host,
            port: config.port,
            username: config.username,
            password: config.password,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ClairException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _submitWebhook() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(disputeDispatchServiceProvider);
      final result = await service.dispatchWebhook(
        webhookUrl: _webhookUrlController.text,
        disputeState: widget.disputeState,
        noticeTextOverride: widget.noticeText,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ClairException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _buildStoreRoomBadge() {
    final isDark = AppColors.isDark(context);
    final color = _loadedFromStoreRoom
        ? (isDark ? AppColors.emerald : const Color(0xFF047857))
        : (widget.isFullScreen
            ? (isDark ? AppColors.textSecondary : AppColors.brandAccentDark)
            : (isDark ? Colors.white : AppColors.brandAccentDark));
    final bg = _loadedFromStoreRoom
        ? AppColors.emeraldBg
        : (isDark ? AppColors.surfaceElevate : AppColors.surfaceSecondaryLight);
    final borderColor = _loadedFromStoreRoom
        ? color.withValues(alpha: 0.5)
        : (isDark ? AppColors.sky.withValues(alpha: 0.65) : AppColors.brandAccent.withValues(alpha: 0.65));
    final label =
        _loadedFromStoreRoom ? 'Auto-filled from Store Room' : 'Manage in Settings';

    return Tooltip(
      message: _loadedFromStoreRoom
          ? 'Open Settings to inspect or update stored SMTP credentials'
          : 'Open Settings & Credential Store to configure SMTP credentials',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: _isSending ? null : _openSettingsStoreRoom,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _loadedFromStoreRoom
                      ? Icons.verified_user_outlined
                      : Icons.settings_outlined,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTypography.monoBadge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (!_loadedFromStoreRoom) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 11,
                    color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmailTab = _selectedChannel == _DispatchChannel.email;
    final isDark = AppColors.isDark(context);
    final borderColor = enterpriseBorderColor(context);

    final samplePayloadJson = const JsonEncoder.withIndent('  ').convert(
      DisputeDispatchService.buildWebhookPayload(
        disputeState: widget.disputeState,
        noticeTextOverride: widget.noticeText.length > 80
            ? '${widget.noticeText.substring(0, 80)}...'
            : widget.noticeText,
      ),
    );

    final scrollContent = SingleChildScrollView(
      padding: EdgeInsets.all(
        widget.isFullScreen ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Channel Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.background
                  : AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ChannelTabButton(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email Vendor',
                    isSelected: isEmailTab,
                    accentColor: AppColors.brandAccent,
                    onTap: _isSending
                        ? null
                        : () => setState(() {
                              _selectedChannel =
                                  _DispatchChannel.email;
                              _errorMessage = null;
                            }),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ChannelTabButton(
                    icon: Icons.webhook_rounded,
                    label: 'Post to Webhook',
                    isSelected: !isEmailTab,
                    accentColor: AppColors.sky,
                    onTap: _isSending
                        ? null
                        : () => setState(() {
                              _selectedChannel =
                                  _DispatchChannel.webhook;
                              _errorMessage = null;
                            }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (isEmailTab) ...[
            EnterpriseSectionCard(
              sectionTitle: 'RECIPIENT & SUBJECT',
              child: Column(
                children: [
                  TextField(
                    controller: _toEmailController,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    decoration: buildEnterpriseFieldDecoration(
                      'To Email',
                      context: context,
                      hint: 'billing@vendor-company.com',
                      prefixIcon: Icons.mark_email_unread_outlined,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _subjectController,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: buildEnterpriseFieldDecoration(
                      'Subject Line',
                      context: context,
                      prefixIcon: Icons.subject_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EnterpriseSectionCard(
              sectionTitle: 'SMTP TRANSPORT',
              trailing: _buildStoreRoomBadge(),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _smtpHostController,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (_) => _hasEditedSmtp = true,
                          decoration: buildEnterpriseFieldDecoration(
                            'SMTP Host',
                            context: context,
                            hint: 'smtp.gmail.com',
                            prefixIcon: Icons.dns_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _smtpPortController,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _hasEditedSmtp = true,
                          decoration: buildEnterpriseFieldDecoration(
                            'Port',
                            context: context,
                            hint: '587',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LayoutBuilder(
                    builder: (context, authConstraints) {
                      final userField = TextField(
                        controller: _smtpUserController,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: (_) => _hasEditedSmtp = true,
                        decoration: buildEnterpriseFieldDecoration(
                          'SMTP Username / From',
                          context: context,
                          hint: 'ap@yourcompany.com',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                      );
                      final passField = TextField(
                        controller: _smtpPassController,
                        style: AppTypography.monoValue.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                        obscureText: !_showPassword,
                        onChanged: (_) => _hasEditedSmtp = true,
                        decoration: buildEnterpriseFieldDecoration(
                          'SMTP Password / App Key',
                          context: context,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIconConstraints:
                              const BoxConstraints(
                            minHeight: 30,
                            minWidth: 32,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _showPassword = !_showPassword,
                            ),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 15,
                              color: isDark ? Colors.white : AppColors.textSecondaryLight,
                            ),
                            tooltip: _showPassword
                                ? 'Hide password'
                                : 'Show password',
                            splashRadius: 14,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      );

                      if (authConstraints.maxWidth < 460) {
                        return Column(
                          children: [
                            userField,
                            const SizedBox(height: AppSpacing.sm),
                            passField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: userField),
                          const SizedBox(width: AppSpacing.xs + 2),
                          Expanded(child: passField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: AppColors.emeraldBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    size: 14,
                    color: isDark ? AppColors.emerald : const Color(0xFF047857),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-attaches ${DisputeDispatchService.pdfAttachmentFileName}',
                      style: AppTypography.monoBadge.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: widget.isFullScreen
                            ? (isDark ? AppColors.emerald.withValues(alpha: 0.9) : const Color(0xFF047857))
                            : AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            EnterpriseSectionCard(
              sectionTitle: 'WEBHOOK ENDPOINT',
              child: TextField(
                controller: _webhookUrlController,
                style: AppTypography.monoCitation.copyWith(
                  fontSize: 12,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
                keyboardType: TextInputType.url,
                decoration: buildEnterpriseFieldDecoration(
                  'Webhook URL',
                  context: context,
                  hint: 'https://hooks.slack.com/services/...',
                  prefixIcon: Icons.link_rounded,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EnterpriseSectionCard(
              sectionTitle: 'JSON PAYLOAD PREVIEW',
              child: Container(
                height: 156,
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.background : AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    samplePayloadJson,
                    style: AppTypography.monoCitation.copyWith(
                      fontSize: 10.5,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            EnterpriseFeedbackBanner(
              message: _errorMessage!,
              isError: true,
            ),
          ],
        ],
      ),
    );

    final footerWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevateOf(context),
        borderRadius: widget.isFullScreen
            ? BorderRadius.zero
            : const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, footerConstraints) {
          final summaryText = Text(
            '${widget.disputeState.vendorName} • ${widget.disputeState.invoiceReference}',
            style: AppTypography.bodySmall.copyWith(
              color: widget.isFullScreen
                  ? (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)
                  : (isDark ? Colors.white : AppColors.textPrimaryLight),
              fontWeight: widget.isFullScreen ? FontWeight.w500 : FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );

          final cancelBtn = OutlinedButton(
            onPressed:
                _isSending ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
              side: BorderSide(color: borderColor),
              minimumSize: const Size(80, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text('Cancel', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
          );

          final submitBtn = ElevatedButton.icon(
            onPressed: _isSending
                ? null
                : (isEmailTab ? _submitEmail : _submitWebhook),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isEmailTab ? AppColors.brandAccent : AppColors.sky,
              foregroundColor:
                  isEmailTab ? Colors.white : AppColors.background,
              minimumSize: const Size(150, 38),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: _isSending
                ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isEmailTab
                          ? Colors.white
                          : AppColors.background,
                    ),
                  )
                : Icon(
                    isEmailTab
                        ? Icons.mark_email_read_outlined
                        : Icons.webhook_rounded,
                    size: 15,
                  ),
            label: Text(
              _isSending
                  ? 'Dispatching...'
                  : (isEmailTab
                      ? 'Send Email Notice'
                      : 'Test Webhook & Send'),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isEmailTab ? Colors.white : AppColors.background,
              ),
            ),
          );

          if (footerConstraints.maxWidth < 460) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                summaryText,
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [cancelBtn, submitBtn],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: summaryText),
              const SizedBox(width: AppSpacing.sm),
              cancelBtn,
              const SizedBox(width: AppSpacing.sm),
              submitBtn,
            ],
          );
        },
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: AppColors.surfaceBackgroundOf(context),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCardOf(context),
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtleOf(context)),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                      tooltip: 'Back to Dispute Notice',
                      color: AppColors.textPrimaryOf(context),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                    padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: (isDark ? AppColors.brandAccent : AppColors.brandAccentDark).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: isDark ? AppColors.brandAccent : AppColors.brandAccentDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Dispatch Formal Notice',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: scrollContent),
              footerWidget,
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.surfaceCardOf(context),
      insetPadding: responsiveDialogInsetPadding(context),
      elevation: 18,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnterpriseDialogHeader(
              icon: Icons.send_rounded,
              accentColor: AppColors.brandAccent,
              title: 'Dispatch Formal Notice',
              subtitle:
                  'Send directly to vendor Accounts Receivable or trigger an enterprise Webhook',
              closeTooltip: 'Close Dispatch',
              onClose: _isSending ? null : () => Navigator.of(context).pop(),
            ),
            Flexible(child: scrollContent),
            footerWidget,
          ],
        ),
      ),
    );
  }
}

class _ChannelTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ChannelTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final activeBg = isDark
        ? AppColors.surfaceElevate
        : AppColors.surfacePrimaryLight;
    final activeColor = isDark
        ? (accentColor == AppColors.brandAccent ? AppColors.sky : accentColor)
        : (accentColor == AppColors.brandAccent ? AppColors.brandAccentDark : const Color(0xFF0284C7));
    final textColor = isSelected
        ? (isDark ? Colors.white : activeColor)
        : (isDark ? Colors.white70 : AppColors.textSecondaryLight);
    final iconColor = isSelected
        ? activeColor
        : (isDark ? Colors.white70 : AppColors.textSecondaryLight);

    return Material(
      color: isSelected ? activeBg : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.65)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: iconColor,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
