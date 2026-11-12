import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/enterprise_dialog_chrome.dart';
import '../../../disputes/services/dispute_dispatch_service.dart';
import '../../providers/audit_provider.dart';

/// Dedicated enterprise Settings & Credential Store dialog ("Store Room")
/// managing encrypted SMTP transport settings and Gemini AI API credentials.
class SettingsDialog extends ConsumerStatefulWidget {
  final FlutterSecureStorage? secureStorage;

  const SettingsDialog({
    super.key,
    this.secureStorage,
  });

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late final TextEditingController _smtpHostController;
  late final TextEditingController _smtpPortController;
  late final TextEditingController _smtpUserController;
  late final TextEditingController _smtpPasswordController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _groqApiKeyController;

  bool _showSmtpPassword = false;
  bool _obscureApiKey = true;
  bool _obscureGroqKey = true;
  bool _isSavingSmtp = false;
  bool _isSavingApiKey = false;
  bool _isSavingGroqKey = false;
  bool _hasSavedSmtp = false;
  bool _hasConfiguredApiKey = false;
  bool _hasConfiguredGroqKey = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final defaults = SmtpConfig.fromEnvOrDefaults();
    _smtpHostController = TextEditingController(text: defaults.host);
    _smtpPortController = TextEditingController(text: '${defaults.port}');
    _smtpUserController = TextEditingController(text: defaults.username);
    _smtpPasswordController = TextEditingController(text: defaults.password);
    _apiKeyController = TextEditingController();
    _groqApiKeyController = TextEditingController();

    _loadStoredCredentials();
  }

  SecureStorageService get _secureStorage => widget.secureStorage != null
      ? SecureStorageService(storage: widget.secureStorage)
      : ref.read(secureStorageServiceProvider);

  Future<void> _loadStoredCredentials() async {
    try {
      final savedSmtp = await _secureStorage.getSmtpCredentials();
      final savedApiKey = await _secureStorage.getApiKey();
      final savedGroqKey = await _secureStorage.getGroqApiKey();
      bool hasApiKey = savedApiKey != null && savedApiKey.trim().isNotEmpty;
      if (!hasApiKey) {
        try {
          hasApiKey =
              await ref.read(geminiAuditServiceProvider).hasConfiguredApiKey();
        } catch (_) {
          hasApiKey = await _secureStorage.hasApiKey();
        }
      }

      bool hasGroqKey = savedGroqKey != null && savedGroqKey.trim().isNotEmpty;
      if (!hasGroqKey) {
        try {
          hasGroqKey =
              await ref.read(groqAuditServiceProvider).hasConfiguredApiKey();
        } catch (_) {
          hasGroqKey = await _secureStorage.hasGroqApiKey();
        }
      }

      if (!mounted) return;
      setState(() {
        _hasSavedSmtp = savedSmtp.hasAny;
        _hasConfiguredApiKey = hasApiKey;
        _hasConfiguredGroqKey = hasGroqKey;
        if (savedSmtp.host != null) {
          _smtpHostController.text = savedSmtp.host!;
        }
        if (savedSmtp.port != null) {
          _smtpPortController.text = '${savedSmtp.port!}';
        }
        if (savedSmtp.username != null) {
          _smtpUserController.text = savedSmtp.username!;
        }
        if (savedSmtp.password != null) {
          _smtpPasswordController.text = savedSmtp.password!;
        }
        if (savedApiKey != null && savedApiKey.trim().isNotEmpty) {
          _apiKeyController.text = savedApiKey.trim();
        }
        if (savedGroqKey != null && savedGroqKey.trim().isNotEmpty) {
          _groqApiKeyController.text = savedGroqKey.trim();
        }
      });
    } catch (_) {
      // Fall back to default/environment configuration if vault is unreadable.
    }
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPasswordController.dispose();
    _apiKeyController.dispose();
    _groqApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _copySmtpPassword() async {
    final value = _smtpPasswordController.text;
    if (value.trim().isEmpty) {
      setState(() {
        _statusMessage = null;
        _errorMessage = 'Nothing to copy from Google App Password.';
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _statusMessage = 'SMTP Password copied to clipboard.';
    });
  }

  Future<void> _saveSmtpCredentials() async {
    final host = _smtpHostController.text.trim();
    final port = int.tryParse(_smtpPortController.text.trim());
    final username = _smtpUserController.text.trim();
    final password = _smtpPasswordController.text;

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _statusMessage = null;
        _errorMessage =
            'Enter SMTP Host, Username, and Google App Password before saving.';
      });
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      setState(() {
        _statusMessage = null;
        _errorMessage = 'Enter a valid SMTP Port between 1 and 65535.';
      });
      return;
    }

    setState(() {
      _isSavingSmtp = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      await _secureStorage.saveSmtpCredentials(
        host: host,
        port: port,
        username: username,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _hasSavedSmtp = true;
        _statusMessage = 'SMTP credentials saved securely to Store Room.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save SMTP credentials: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingSmtp = false);
      }
    }
  }

  Future<void> _clearSmtpCredentials() async {
    final defaults = SmtpConfig.fromEnvOrDefaults();
    setState(() {
      _isSavingSmtp = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      await _secureStorage.deleteSmtpCredentials();
      if (!mounted) return;
      setState(() {
        _hasSavedSmtp = false;
        _smtpHostController.text = defaults.host;
        _smtpPortController.text = '${defaults.port}';
        _smtpUserController.clear();
        _smtpPasswordController.clear();
        _statusMessage = 'Saved SMTP credentials cleared from Store Room.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to clear SMTP credentials: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSavingSmtp = false);
      }
    }
  }

  Future<void> _saveEngineApiKey({
    required TextEditingController controller,
    required String engineDisplayName,
    required Future<void> Function(String value) persistFn,
    required void Function(String value) setInMemoryFn,
    required void Function(bool saving) setSavingState,
    required VoidCallback onConfigured,
  }) async {
    final value = controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _statusMessage = null;
        _errorMessage = 'Enter a $engineDisplayName API Key before saving.';
      });
      return;
    }

    setState(() {
      setSavingState(true);
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      await persistFn(value);
      setInMemoryFn(value);
      if (!mounted) return;
      setState(() {
        onConfigured();
        controller.clear();
        _statusMessage =
            '$engineDisplayName API key securely stored in OS credential vault.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save $engineDisplayName API key: $e';
      });
    } finally {
      if (mounted) {
        setState(() => setSavingState(false));
      }
    }
  }

  Future<void> _saveApiKey() => _saveEngineApiKey(
        controller: _apiKeyController,
        engineDisplayName: 'Gemini',
        persistFn: _secureStorage.saveApiKey,
        setInMemoryFn: (value) => ref.read(apiKeyProvider.notifier).setKey(value),
        setSavingState: (saving) => _isSavingApiKey = saving,
        onConfigured: () => _hasConfiguredApiKey = true,
      );

  Future<void> _saveGroqApiKey() => _saveEngineApiKey(
        controller: _groqApiKeyController,
        engineDisplayName: 'Groq',
        persistFn: _secureStorage.saveGroqApiKey,
        setInMemoryFn: (value) =>
            ref.read(groqApiKeyProvider.notifier).setKey(value),
        setSavingState: (saving) => _isSavingGroqKey = saving,
        onConfigured: () => _hasConfiguredGroqKey = true,
      );

  Widget _buildStatusPill({
    required String label,
    required bool isActive,
  }) {
    final accent = isActive ? AppColors.emerald : Colors.white;
    final bg = isActive ? AppColors.emeraldBg : AppColors.background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.45)
              : enterpriseModalBorderColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamilyMono,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildEngineKeyCard({
    required String sectionTitle,
    required String labelText,
    required String emptyHint,
    required String saveButtonLabel,
    required String showTooltip,
    required String hideTooltip,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required bool isConfigured,
    required bool isSaving,
    required bool isBusy,
    required VoidCallback onSave,
  }) {
    return EnterpriseSectionCard(
      sectionTitle: sectionTitle,
      trailing: _buildStatusPill(
        label: isConfigured ? 'Configured' : 'Missing',
        isActive: isConfigured,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: AppTypography.monoValue.copyWith(
                color: Colors.white,
              ),
              decoration: buildEnterpriseFieldDecoration(
                labelText,
                hint: isConfigured ? 'Enter new key to update vault' : emptyHint,
                prefixIcon: Icons.key_rounded,
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 30,
                  minWidth: 32,
                ),
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                  tooltip: obscureText ? showTooltip : hideTooltip,
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: isBusy ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.background,
              minimumSize: const Size(0, 38),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.background,
                    ),
                  )
                : const Icon(Icons.verified_user_outlined, size: 15),
            label: Text(saveButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSavingSmtp || _isSavingApiKey || _isSavingGroqKey;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: enterpriseModalBorderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnterpriseDialogHeader(
              icon: Icons.admin_panel_settings_rounded,
              accentColor: AppColors.brandAccent,
              title: 'Settings & Credential Store',
              subtitle:
                  'Encrypted OS Store Room for SMTP dispatch & Gemini AI keys',
              closeTooltip: 'Close Settings',
              onClose: isBusy ? null : () => Navigator.of(context).pop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EnterpriseSectionCard(
                      sectionTitle: 'SMTP CREDENTIAL STORE ROOM',
                      trailing: _buildStatusPill(
                        label: _hasSavedSmtp ? 'Saved in Vault' : 'Not Saved',
                        isActive: _hasSavedSmtp,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Store SMTP credentials here once; Email Vendor dispatches auto-fill automatically.',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm + 2),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _smtpHostController,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: buildEnterpriseFieldDecoration(
                                    'SMTP Host',
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: buildEnterpriseFieldDecoration(
                                    'Port',
                                    hint: '587',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _smtpUserController,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            decoration: buildEnterpriseFieldDecoration(
                              'SMTP Username / From',
                              hint: 'ap@yourcompany.com',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _smtpPasswordController,
                                  style: AppTypography.monoValue.copyWith(
                                    color: Colors.white,
                                  ),
                                  obscureText: !_showSmtpPassword,
                                  decoration: buildEnterpriseFieldDecoration(
                                    'Google App Password / Key',
                                    hint: '16-character app password',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    suffixIconConstraints: const BoxConstraints(
                                      minHeight: 30,
                                      minWidth: 32,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _showSmtpPassword =
                                            !_showSmtpPassword,
                                      ),
                                      icon: Icon(
                                        _showSmtpPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      tooltip: _showSmtpPassword
                                          ? 'Hide password'
                                          : 'Show password',
                                      splashRadius: 14,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs + 2),
                              Container(
                                height: 38,
                                width: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: enterpriseModalBorderColor,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: isBusy ? null : _copySmtpPassword,
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: AppColors.sky,
                                  ),
                                  tooltip: 'Copy saved password',
                                  splashRadius: 16,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: isBusy ? null : _clearSmtpCredentials,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 15,
                                ),
                                label: const Text('Clear'),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              ElevatedButton.icon(
                                onPressed: isBusy ? null : _saveSmtpCredentials,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandAccent,
                                  foregroundColor: Colors.white,
                                ),
                                icon: _isSavingSmtp
                                    ? const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined, size: 15),
                                label: const Text('Save Credentials'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildEngineKeyCard(
                      sectionTitle: 'GEMINI AI ENGINE CREDENTIAL',
                      labelText: 'GEMINI_API_KEY',
                      emptyHint: 'AIzaSy...',
                      saveButtonLabel: 'Save Key',
                      showTooltip: 'Show API key',
                      hideTooltip: 'Hide API key',
                      controller: _apiKeyController,
                      obscureText: _obscureApiKey,
                      onToggleObscure: () =>
                          setState(() => _obscureApiKey = !_obscureApiKey),
                      isConfigured: _hasConfiguredApiKey,
                      isSaving: _isSavingApiKey,
                      isBusy: isBusy,
                      onSave: _saveApiKey,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildEngineKeyCard(
                      sectionTitle: 'GROQ AI ENGINE CREDENTIAL',
                      labelText: 'GROQ_API_KEY',
                      emptyHint: 'gsk_...',
                      saveButtonLabel: 'Save Groq Key',
                      showTooltip: 'Show Groq API key',
                      hideTooltip: 'Hide Groq API key',
                      controller: _groqApiKeyController,
                      obscureText: _obscureGroqKey,
                      onToggleObscure: () =>
                          setState(() => _obscureGroqKey = !_obscureGroqKey),
                      isConfigured: _hasConfiguredGroqKey,
                      isSaving: _isSavingGroqKey,
                      isBusy: isBusy,
                      onSave: _saveGroqApiKey,
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      EnterpriseFeedbackBanner(message: _statusMessage!),
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
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevate,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg),
                ),
                border: Border(
                  top: BorderSide(color: enterpriseModalBorderColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: enterpriseModalBorderColor),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
