import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/clair_logo_badge.dart';
import '../../../../core/widgets/enterprise_dialog_chrome.dart';

/// Dedicated enterprise About dialog displaying version, core architecture,
/// dual-engine AI capabilities, and on-device privacy guarantee.
class AboutClairDocsDialog extends StatelessWidget {
  const AboutClairDocsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      insetPadding: responsiveDialogInsetPadding(context),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: enterpriseModalBorderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnterpriseDialogHeader(
              icon: Icons.info_outline_rounded,
              accentColor: AppColors.brandAccent,
              title: 'About ClairDocs',
              subtitle: 'Enterprise AI Vendor Contract & Invoice Auditing',
              closeTooltip: 'Close About',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const ClairLogoBadge(size: 42, borderRadius: 10),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ClairDocs',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamilySans,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enterprise Edition • Version 1.0.0',
                              style: AppTypography.monoCitation.copyWith(
                                color: AppColors.sky,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EnterpriseSectionCard(
                    sectionTitle: 'ARCHITECTURE & CAPABILITIES',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureItem(
                          icon: Icons.bolt_rounded,
                          title: 'Dual-Engine AI Audit',
                          description:
                              'Primary audit powered by Google Gemini 2.5 with sub-second failover to Groq LLaMA 3.3.',
                        ),
                        const SizedBox(height: AppSpacing.sm + 2),
                        _buildFeatureItem(
                          icon: Icons.shield_outlined,
                          title: 'Zero-Cloud Local Privacy',
                          description:
                              'Document processing, SHA-256 integrity verification, and audit history vault remain strictly on-device.',
                        ),
                        const SizedBox(height: AppSpacing.sm + 2),
                        _buildFeatureItem(
                          icon: Icons.gavel_rounded,
                          title: 'Dispute Studio & SMTP Dispatch',
                          description:
                              'Automated legal dispute notice synthesis, PDF export, and direct encrypted vendor dispatch.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      '© 2026 ClairDocs Team. Built for autonomous enterprise auditing.',
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevate,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, size: 14, color: AppColors.sky),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamilySans,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
