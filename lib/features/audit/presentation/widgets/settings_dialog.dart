import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/enterprise_dialog_chrome.dart';
import '../../../disputes/services/dispute_dispatch_service.dart';
import '../../providers/audit_provider.dart';

/// Dedicated enterprise Settings & Credential Store dialog ("Store Room")
/// managing encrypted SMTP transport settings and Gemini AI API credentials.
class SettingsDialog extends ConsumerStatefulWidget {
  final FlutterSecureStorage? secureStorage;
  final bool isFullScreen;
  final bool showBackButton;
  final VoidCallback? onDone;

  const SettingsDialog({
    super.key,
    this.secureStorage,
    this.isFullScreen = false,
    this.showBackButton = false,
    this.onDone,
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

  void _handleDone() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onDone?.call();
    }
  }

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

  Future<void> _clearEngineApiKey({
    required TextEditingController controller,
    required String engineDisplayName,
    required Future<void> Function() deleteFn,
    required VoidCallback onClearedMemory,
    required void Function(bool saving) setSavingState,
    required Future<bool> Function() checkConfiguredFn,
    required void Function(bool configured) setConfiguredState,
  }) async {
    setState(() {
      setSavingState(true);
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      await deleteFn();
      onClearedMemory();
      if (!mounted) return;
      controller.clear();
      final hasConfigured = await checkConfiguredFn();
      setState(() {
        setConfiguredState(hasConfigured);
        _statusMessage = '$engineDisplayName API key cleared from OS vault.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to clear $engineDisplayName API key: $e';
      });
    } finally {
      if (mounted) {
        setState(() => setSavingState(false));
      }
    }
  }

  Future<void> _clearApiKey() => _clearEngineApiKey(
        controller: _apiKeyController,
        engineDisplayName: 'Gemini',
        deleteFn: _secureStorage.deleteApiKey,
        onClearedMemory: () => ref.read(apiKeyProvider.notifier).setKey(''),
        setSavingState: (saving) => _isSavingApiKey = saving,
        checkConfiguredFn: _secureStorage.hasApiKey,
        setConfiguredState: (configured) => _hasConfiguredApiKey = configured,
      );

  Future<void> _clearGroqApiKey() => _clearEngineApiKey(
        controller: _groqApiKeyController,
        engineDisplayName: 'Groq',
        deleteFn: _secureStorage.deleteGroqApiKey,
        onClearedMemory: () => ref.read(groqApiKeyProvider.notifier).setKey(''),
        setSavingState: (saving) => _isSavingGroqKey = saving,
        checkConfiguredFn: _secureStorage.hasGroqApiKey,
        setConfiguredState: (configured) => _hasConfiguredGroqKey = configured,
      );

  Widget _buildStatusPill({
    required BuildContext context,
    required String label,
    required bool isActive,
  }) {
    final isDark = AppColors.isDark(context);
    final accent = isActive
        ? (isDark ? AppColors.emerald : const Color(0xFF047857))
        : (isDark ? Colors.white : AppColors.textSecondaryLight);
    final bg = isActive
        ? AppColors.emeraldBg
        : (isDark ? AppColors.background : AppColors.surfaceSecondaryLight);
    final borderColor =
        isDark ? enterpriseModalBorderColor : AppColors.borderSubtleLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isActive ? accent.withValues(alpha: 0.45) : borderColor,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.monoBadge.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeChoiceChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final isDark = AppColors.isDark(context);
    final activeBg = isDark
        ? AppColors.brandAccent.withValues(alpha: 0.22)
        : AppColors.brandAccent.withValues(alpha: 0.12);
    final inactiveBg = isDark
        ? AppColors.surfaceElevate
        : AppColors.surfaceSecondaryLight;
    final activeBorder = AppColors.brandAccent;
    final inactiveBorder =
        isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight;
    final textColor = isSelected
        ? (isDark ? Colors.white : AppColors.brandAccentDark)
        : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight);
    final iconColor = isSelected
        ? (isDark ? AppColors.sky : AppColors.brandAccentDark)
        : (isDark ? Colors.white70 : AppColors.textSecondaryLight);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineKeyCard({
    required BuildContext context,
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
    required VoidCallback onClear,
  }) {
    final isDark = AppColors.isDark(context);
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return EnterpriseSectionCard(
      sectionTitle: sectionTitle,
      trailing: _buildStatusPill(
        context: context,
        label: isConfigured ? 'Configured' : 'Missing',
        isActive: isConfigured,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyField = TextField(
            controller: controller,
            obscureText: obscureText,
            style: AppTypography.monoValue.copyWith(
              color: textColor,
            ),
            decoration: buildEnterpriseFieldDecoration(
              labelText,
              context: context,
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
                  color: isDark ? Colors.white : AppColors.textSecondaryLight,
                ),
                tooltip: obscureText ? showTooltip : hideTooltip,
                splashRadius: 14,
                padding: EdgeInsets.zero,
              ),
            ),
          );

          final clearBtn = TextButton.icon(
            onPressed: isBusy ? null : onClear,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondaryOf(context),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(80, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 15),
            label: Text('Clear', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
          );

          final saveBtn = ElevatedButton.icon(
            onPressed: isBusy ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user_outlined, size: 15),
            label: Text(saveButtonLabel, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
          );

          final actionRow = Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              clearBtn,
              saveBtn,
            ],
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                keyField,
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: Alignment.centerRight, child: actionRow),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: keyField),
              const SizedBox(width: AppSpacing.sm),
              actionRow,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSavingSmtp || _isSavingApiKey || _isSavingGroqKey;
    final currentTheme = ref.watch(themeModeProvider);
    final isDark = AppColors.isDark(context);

    final scrollContent = SingleChildScrollView(
      padding: EdgeInsets.all(
        widget.isFullScreen ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                    EnterpriseSectionCard(
                      sectionTitle: 'SMTP CREDENTIAL STORE ROOM',
                      trailing: _buildStatusPill(
                        context: context,
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
                              color: widget.isFullScreen
                                  ? (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)
                                  : (isDark ? Colors.white : AppColors.textSecondaryLight),
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
                                    color: AppColors.textPrimaryOf(context),
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                    color: AppColors.textPrimaryOf(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  keyboardType: TextInputType.number,
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
                          TextField(
                            controller: _smtpUserController,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w500,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            decoration: buildEnterpriseFieldDecoration(
                              'SMTP Username / From',
                              context: context,
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
                                    color: AppColors.textPrimaryOf(context),
                                  ),
                                  obscureText: !_showSmtpPassword,
                                  decoration: buildEnterpriseFieldDecoration(
                                    'Google App Password / Key',
                                    context: context,
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
                                        color: isDark ? Colors.white : AppColors.textSecondaryLight,
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
                                  color: AppColors.surfaceElevateOf(context),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: enterpriseBorderColor(context),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: isBusy ? null : _copySmtpPassword,
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                                  ),
                                  tooltip: 'Copy saved password',
                                  splashRadius: 16,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              TextButton.icon(
                                onPressed: isBusy ? null : _clearSmtpCredentials,
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      AppColors.textSecondaryOf(context),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  minimumSize: const Size(80, 38),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 15,
                                ),
                                label: Text('Clear', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
                              ),
                              ElevatedButton.icon(
                                onPressed: isBusy ? null : _saveSmtpCredentials,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandAccent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(140, 38),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
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
                                label: Text('Save Credentials', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildEngineKeyCard(
                      context: context,
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
                      onClear: _clearApiKey,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildEngineKeyCard(
                      context: context,
                      sectionTitle: 'GROQ AI ENGINE CREDENTIAL',
                      labelText: 'GROQ_API_KEY',
                      emptyHint: 'gsk_...',
                      saveButtonLabel: 'Save Key',
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
                      onClear: _clearGroqApiKey,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EnterpriseSectionCard(
                      sectionTitle: 'APPLICATION THEME',
                      trailing: _buildStatusPill(
                        context: context,
                        label: currentTheme == ThemeMode.dark
                            ? 'Dark'
                            : (currentTheme == ThemeMode.light
                                ? 'Light'
                                : 'System'),
                        isActive: true,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Select appearance theme for the ClairDocs interface.',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: widget.isFullScreen
                                  ? (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)
                                  : (isDark ? Colors.white : AppColors.textSecondaryLight),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _buildThemeChoiceChip(
                                context: context,
                                label: 'Dark (Default)',
                                icon: Icons.dark_mode_outlined,
                                isSelected: currentTheme == ThemeMode.dark,
                                onSelected: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(ThemeMode.dark),
                              ),
                              _buildThemeChoiceChip(
                                context: context,
                                label: 'Light',
                                icon: Icons.light_mode_outlined,
                                isSelected: currentTheme == ThemeMode.light,
                                onSelected: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(ThemeMode.light),
                              ),
                              _buildThemeChoiceChip(
                                context: context,
                                label: 'System',
                                icon: Icons.brightness_auto_outlined,
                                isSelected: currentTheme == ThemeMode.system,
                                onSelected: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(ThemeMode.system),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: (widget.showBackButton || Navigator.of(context).canPop())
                      ? AppSpacing.xs
                      : (AppSpacing.sm + 4),
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCardOf(context),
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtleOf(context)),
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.showBackButton || Navigator.of(context).canPop()) ...[
                      IconButton(
                        onPressed: isBusy ? null : _handleDone,
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        tooltip: 'Back',
                        color: AppColors.textPrimaryOf(context),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
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
                        Icons.settings_outlined,
                        size: 16,
                        color: isDark ? AppColors.brandAccent : AppColors.brandAccentDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Settings & Credential Store',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: isBusy ? null : _handleDone,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : AppColors.brandAccentDark,
                        side: BorderSide(
                          color: isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: const Size(60, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: scrollContent),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.surfaceCardOf(context),
      insetPadding: responsiveDialogInsetPadding(context),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: enterpriseBorderColor(context)),
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
            Flexible(child: scrollContent),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevateOf(context),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg),
                ),
                border: Border(
                  top: BorderSide(color: enterpriseBorderColor(context)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryOf(context),
                      side: BorderSide(color: enterpriseBorderColor(context)),
                    ),
                    child: Text('Done', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryOf(context))),
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
