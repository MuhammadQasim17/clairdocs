import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/audit_provider.dart';

class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _hasExistingKey = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkKeyStatus();
  }

  Future<void> _checkKeyStatus() async {
    try {
      final service = ref.read(geminiAuditServiceProvider);
      final hasKey = await service.hasConfiguredApiKey();
      if (!mounted) return;
      setState(() => _hasExistingKey = hasKey);
    } catch (_) {
      // Preserve default hint state if key status check fails.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorMessage = 'Enter a Gemini API key before saving.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(geminiAuditServiceProvider).saveApiKey(value);
      ref.read(apiKeyProvider.notifier).setKey(value);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevate,
          content: Text(
            'Gemini API key securely stored in OS credential vault.',
            style: AppTypography.bodySmall,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to save Gemini API key to OS credential vault. Please retry.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: const Row(
        children: [
          Icon(Icons.key_rounded, color: AppColors.emerald, size: 18),
          SizedBox(width: 8),
          Text('Gemini API Configuration', style: AppTypography.titleMedium),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hasExistingKey
                  ? 'A Gemini API key is currently active. Enter a new key below to override it in local OS secure storage.'
                  : 'Enter your Google AI Studio Gemini API key. It is encrypted locally using your OS Credential Vault and never leaves your machine except to query Gemini.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              style: AppTypography.monoValue,
              decoration: InputDecoration(
                labelText: 'GEMINI_API_KEY',
                labelStyle: AppTypography.labelMicro,
                hintText: 'AIzaSy...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 16,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.crimson,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _saveKey,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 15),
          label: const Text('Save Securely'),
        ),
      ],
    );
  }
}

