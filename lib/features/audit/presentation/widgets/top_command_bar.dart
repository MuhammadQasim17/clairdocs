import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clair_logo_badge.dart';
import '../../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../../contracts/providers/contract_providers.dart';
import '../../../history/presentation/widgets/audit_vault_dialog.dart';
import '../../../invoices/providers/invoice_providers.dart';
import '../../models/audit_models.dart';
import '../../providers/audit_provider.dart';
import 'settings_dialog.dart';

class TopCommandBar extends ConsumerWidget {
  static const TextStyle _badgeBaseTextStyle = TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  const TopCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractState = ref.watch(contractDocumentProvider);
    final invoiceState = ref.watch(invoiceDocumentProvider);
    final auditAsync = ref.watch(auditProvider);
    final retryStatus = ref.watch(auditStatusMessageProvider);
    final cooldownSeconds = ref.watch(auditCooldownProvider);

    final hasContractLoaded =
        contractState.document != null || contractState.isDemoMode;
    final hasInvoiceLoaded =
        invoiceState.document != null || invoiceState.isDemoMode;
    final contractName = contractState.document?.fileName ??
        (contractState.isDemoMode ? 'MSA_2026 (Demo)' : 'No Contract');
    final invoiceName = invoiceState.document?.fileName ??
        (invoiceState.isDemoMode ? 'INV-2026-889 (Demo)' : 'No Invoice');

    final isAuditing = auditAsync.isLoading;
    final hasAnyDocument = hasContractLoaded || hasInvoiceLoaded;
    final isAuditButtonDisabled =
        !hasAnyDocument || isAuditing || cooldownSeconds > 0;

    final runAuditLabel = isAuditing
        ? 'Auditing...'
        : (cooldownSeconds > 0 ? 'Wait ${cooldownSeconds}s' : 'Run AI Audit');

    final settingsButton = _buildMobileIconButton(
      icon: Icons.settings_outlined,
      tooltip: 'Settings & Credential Store',
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) => const SettingsDialog(),
        );
      },
    );

    final actionSpecs = <_TopBarActionSpec>[
      _TopBarActionSpec(
        icon: Icons.inventory_2_outlined,
        label: 'Audit Vault',
        flex: 3,
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => const AuditVaultDialog(),
          );
        },
      ),
      _TopBarActionSpec(
        icon: Icons.insights_rounded,
        label: 'Analytics & Savings',
        flex: 4,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AnalyticsDashboardScreen(),
            ),
          );
        },
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, barConstraints) {
          final isPhoneBar =
              barConstraints.maxWidth < AppBreakpoints.compactPhone;
          final isTightBar = barConstraints.maxWidth < 1040;
          final isCompactButtons = barConstraints.maxWidth < 960;
          final pinVaultIntrinsic = barConstraints.maxWidth >= 600;
          final horizontalPad = isCompactButtons ? 6.0 : 9.0;
          final ctaHorizontalPad = isCompactButtons ? 8.0 : 11.0;
          final gap = isCompactButtons ? 4.0 : 6.0;
          final iconSize = isCompactButtons ? 13.0 : 14.0;
          final iconGap = isCompactButtons ? 3.0 : 5.0;
          final labelFontSize = isCompactButtons ? 11.0 : 12.0;

          final brandBadge = Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 9, 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevate,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.brandAccent.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandAccent.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClairLogoBadge(
                  size: 22,
                  borderRadius: 5,
                ),
                SizedBox(width: 6),
                Text(
                  'ClairDocs',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamilySans,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );

          final compactOutlinedStyle = OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPad,
              vertical: 6,
            ),
            minimumSize: const Size(0, 34),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: TextStyle(
              fontFamily: AppTypography.fontFamilySans,
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
            ),
          );

          final compactPrimaryStyle = ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: ctaHorizontalPad,
              vertical: 6,
            ),
            minimumSize: const Size(0, 34),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: TextStyle(
              fontFamily: AppTypography.fontFamilySans,
              fontSize: labelFontSize,
              fontWeight: FontWeight.w700,
            ),
          );

          final ctaButton = Tooltip(
            message: runAuditLabel,
            child: ElevatedButton(
              style: compactPrimaryStyle,
              onPressed: isAuditButtonDisabled
                  ? null
                  : () => ref.read(auditProvider.notifier).runAudit(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAuditing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      cooldownSeconds > 0
                          ? Icons.hourglass_bottom_rounded
                          : Icons.auto_awesome_rounded,
                      size: iconSize,
                    ),
                  SizedBox(width: iconGap),
                  Flexible(
                    child: Text(
                      runAuditLabel,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (isPhoneBar) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: 6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: brandBadge,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      settingsButton,
                      for (final spec in actionSpecs) ...[
                        const SizedBox(width: 4),
                        _buildMobileIconButton(
                          icon: spec.icon,
                          tooltip: spec.label,
                          onPressed: spec.onPressed,
                        ),
                      ],
                      const SizedBox(width: 6),
                      ctaButton,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        fit: FlexFit.loose,
                        child: _buildBreadcrumbFileSegment(
                          name: contractName,
                          isLoaded: hasContractLoaded,
                        ),
                      ),
                      _buildBreadcrumbChevron(),
                      Flexible(
                        flex: 2,
                        fit: FlexFit.loose,
                        child: _buildBreadcrumbFileSegment(
                          name: invoiceName,
                          isLoaded: hasInvoiceLoaded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 3,
                        fit: FlexFit.loose,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _buildStatusPill(
                              auditAsync,
                              retryStatus,
                              hasAnyDocument: hasAnyDocument,
                              allowCompactShrink: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final trailWidget = Expanded(
            flex: isTightBar ? 5 : 1,
            child: LayoutBuilder(
              builder: (context, trailConstraints) {
                final isSpaciousTrail = trailConstraints.maxWidth >= 700;
                final segmentFlex = isSpaciousTrail ? 1 : 2;

                final statusWidget = _buildStatusPill(
                  auditAsync,
                  retryStatus,
                  hasAnyDocument: hasAnyDocument,
                  allowCompactShrink: !isSpaciousTrail,
                );

                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (trailConstraints.maxWidth < 260)
                      Flexible(
                        flex: 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: brandBadge,
                        ),
                      )
                    else
                      brandBadge,
                    _buildBreadcrumbChevron(),
                    Flexible(
                      flex: segmentFlex,
                      fit: FlexFit.loose,
                      child: _buildBreadcrumbFileSegment(
                        name: contractName,
                        isLoaded: hasContractLoaded,
                      ),
                    ),
                    _buildBreadcrumbChevron(),
                    Flexible(
                      flex: segmentFlex,
                      fit: FlexFit.loose,
                      child: _buildBreadcrumbFileSegment(
                        name: invoiceName,
                        isLoaded: hasInvoiceLoaded,
                      ),
                    ),
                    _buildBreadcrumbChevron(),
                    if (isSpaciousTrail)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: statusWidget,
                      )
                    else
                      Flexible(
                        flex: 6,
                        fit: FlexFit.loose,
                        child: trailConstraints.maxWidth < 500
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  child: statusWidget,
                                ),
                              )
                            : statusWidget,
                      ),
                  ],
                );
              },
            ),
          );

          final rightRow = Row(
            mainAxisSize: isTightBar ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              settingsButton,
              for (var i = 0; i < actionSpecs.length; i++) ...[
                SizedBox(width: gap),
                (() {
                  final spec = actionSpecs[i];
                  final actionButton = _buildCompactOutlinedAction(
                    style: compactOutlinedStyle,
                    icon: spec.icon,
                    iconSize: iconSize,
                    iconGap: iconGap,
                    label: spec.label,
                    onPressed: spec.onPressed,
                  );
                  if (!isTightBar || (i == 0 && pinVaultIntrinsic)) {
                    return actionButton;
                  }
                  return Flexible(
                    flex: spec.flex,
                    fit: FlexFit.loose,
                    child: actionButton,
                  );
                })(),
              ],
              SizedBox(width: gap),
              if (isTightBar)
                Flexible(
                  flex: 3,
                  fit: FlexFit.loose,
                  child: ctaButton,
                )
              else
                ctaButton,
            ],
          );

          return Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
            child: Row(
              children: [
                trailWidget,
                const SizedBox(width: 8),
                if (isTightBar) Expanded(flex: 6, child: rightRow) else rightRow,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumbChevron() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textPrimary.withValues(alpha: 0.68),
        size: 14,
      ),
    );
  }

  Widget _buildBreadcrumbFileSegment({
    required String name,
    required bool isLoaded,
  }) {
    return Tooltip(
      message: name,
      child: Text(
        name,
        style: _badgeBaseTextStyle.copyWith(
          fontWeight: isLoaded ? FontWeight.w600 : FontWeight.w500,
          color: isLoaded
              ? AppColors.sky
              : AppColors.textPrimary.withValues(alpha: 0.78),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  Widget _buildMobileIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 17, color: Colors.white),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.surfaceElevate.withValues(alpha: 0.72),
        side: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        minimumSize: const Size(32, 32),
        fixedSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      splashRadius: 16,
    );
  }

  Widget _buildCompactOutlinedAction({
    required ButtonStyle style,
    required IconData icon,
    required double iconSize,
    required double iconGap,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: label,
      child: OutlinedButton(
        style: style,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize),
            SizedBox(width: iconGap),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillChip({
    required Color backgroundColor,
    required Color borderColor,
    required Widget leading,
    required String label,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: _badgeBaseTextStyle.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    AsyncValue<AuditResult?> auditAsync,
    String? retryStatus, {
    required bool hasAnyDocument,
    required bool allowCompactShrink,
  }) {
    return auditAsync.when(
      loading: () {
        final isRetryWait = retryStatus != null && retryStatus.isNotEmpty;
        final accent = isRetryWait ? AppColors.amber : AppColors.sky;
        final bg = isRetryWait ? AppColors.amberBg : AppColors.skyBg;
        final label = isRetryWait ? retryStatus : 'Auditing Documents...';

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _buildPillChip(
            backgroundColor: bg,
            borderColor: accent.withValues(alpha: 0.4),
            leading: SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            ),
            label: label,
            textColor: accent,
          ),
        );
      },
      error: (error, _) {
        final isRateLimit = error is GeminiRateLimitException;
        final isServerBusy = error is GeminiServerBusyException;
        final isDualEngine = error is DualEngineAuditException;
        final isTransientWarning = isRateLimit || isServerBusy || isDualEngine;

        final accent = isTransientWarning ? AppColors.amber : AppColors.crimson;
        final bg = isTransientWarning ? AppColors.amberBg : AppColors.crimsonBg;
        final label = isRateLimit
            ? 'Free Tier Limit Reached'
            : (isServerBusy
                ? 'Servers Busy (503)'
                : (isDualEngine
                    ? 'All Engines Busy'
                    : 'Audit Attention Required'));

        return _buildPillChip(
          backgroundColor: bg,
          borderColor: accent.withValues(alpha: 0.4),
          leading: Icon(
            isRateLimit
                ? Icons.speed_rounded
                : (isServerBusy
                    ? Icons.cloud_off_rounded
                    : Icons.error_outline),
            size: 13,
            color: accent,
          ),
          label: label,
          textColor: accent,
        );
      },
      data: (result) {
        if (result == null) {
          final accentColor = hasAnyDocument
              ? AppColors.sky
              : AppColors.textPrimary.withValues(alpha: 0.72);
          final bgColor =
              hasAnyDocument ? AppColors.skyBg : AppColors.surfaceElevate;
          final borderColor = hasAnyDocument
              ? AppColors.sky.withValues(alpha: 0.4)
              : const Color(0xFF475569);
          final textColor = hasAnyDocument ? AppColors.sky : Colors.white;
          final statusLabel =
              hasAnyDocument ? 'Ready for Audit' : 'Awaiting Documents';

          return _buildPillChip(
            backgroundColor: bgColor,
            borderColor: borderColor,
            leading: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            label: statusLabel,
            textColor: textColor,
          );
        }

        final count = result.findings.length;
        final engineBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevate,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.sky.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            result.auditEngine,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamilyMono,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.sky,
            ),
            softWrap: false,
          ),
        );

        final Widget statusChip;
        if (count == 0) {
          statusChip = _buildPillChip(
            backgroundColor: AppColors.emeraldBg,
            borderColor: AppColors.emerald.withValues(alpha: 0.4),
            leading: const Icon(
              Icons.check_circle_outline,
              size: 13,
              color: AppColors.emerald,
            ),
            label: '0 Discrepancies — Compliant',
            textColor: AppColors.emerald,
          );
        } else {
          final hasHigh = result.findings.any((f) => f.severity == 'high');
          final accent = hasHigh ? AppColors.crimson : AppColors.amber;
          final bg = hasHigh ? AppColors.crimsonBg : AppColors.amberBg;
          final label =
              '$count ${count == 1 ? 'Discrepancy' : 'Discrepancies'} Detected';

          statusChip = _buildPillChip(
            backgroundColor: bg,
            borderColor: accent.withValues(alpha: 0.4),
            leading: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            label: label,
            textColor: accent,
          );
        }

        if (!allowCompactShrink) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: statusChip,
              ),
              const SizedBox(width: 6),
              engineBadge,
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 3,
              fit: FlexFit.loose,
              child: statusChip,
            ),
            const SizedBox(width: 6),
            Flexible(
              flex: 3,
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: engineBadge,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBarActionSpec {
  final IconData icon;
  final String label;
  final int flex;
  final VoidCallback? onPressed;

  const _TopBarActionSpec({
    required this.icon,
    required this.label,
    required this.flex,
    required this.onPressed,
  });
}
