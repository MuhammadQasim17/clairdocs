import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/clair_logo_badge.dart';
import '../../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../../contracts/models/contract_document.dart';
import '../../../contracts/presentation/widgets/contract_viewer_panel.dart';
import '../../../contracts/providers/contract_providers.dart';
import '../../../history/presentation/widgets/audit_vault_dialog.dart';
import '../../../invoices/models/invoice_document.dart';
import '../../../invoices/presentation/widgets/invoice_viewer_panel.dart';
import '../../../invoices/providers/invoice_providers.dart';
import '../../models/audit_models.dart';
import '../../providers/audit_provider.dart';
import '../widgets/top_command_bar.dart';
import '../widgets/action_studio_panel.dart';
import '../widgets/settings_dialog.dart';
import 'mobile_audit_results_screen.dart';

class AuditWorkbenchScreen extends ConsumerStatefulWidget {
  const AuditWorkbenchScreen({super.key});

  @override
  ConsumerState<AuditWorkbenchScreen> createState() =>
      _AuditWorkbenchScreenState();
}

class _AuditWorkbenchScreenState extends ConsumerState<AuditWorkbenchScreen> {
  int _mobileNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final contractState = ref.watch(contractDocumentProvider);
    final invoiceState = ref.watch(invoiceDocumentProvider);
    final auditAsync = ref.watch(auditProvider);
    final retryStatus = ref.watch(auditStatusMessageProvider);
    final cooldownSeconds = ref.watch(auditCooldownProvider);

    final contractDoc = contractState.document;
    final invoiceDoc = invoiceState.document;

    final contractHashLabel = contractDoc != null
        ? 'Contract SHA-256: ${contractDoc.sha256Hash.substring(0, 12)}...'
        : 'Contract: Ready for ingestion';
    final invoiceHashLabel = invoiceDoc != null
        ? 'Invoice SHA-256: ${invoiceDoc.sha256Hash.substring(0, 12)}...'
        : 'Invoice: Ready for ingestion';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;
        if (isDesktop) {
          // Desktop UI remains 100% untouched
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: _buildDesktopWorkspace(
                contractHashLabel: contractHashLabel,
                invoiceHashLabel: invoiceHashLabel,
              ),
            ),
          );
        }

        // Mobile workspace with theme-reactive background, no double bottom padding
        return Scaffold(
          backgroundColor: AppColors.surfaceBackgroundOf(context),
          body: SafeArea(
            bottom: false,
            child: _buildMobileWorkspace(
              contractState: contractState,
              invoiceState: invoiceState,
              auditAsync: auditAsync,
              retryStatus: retryStatus,
              cooldownSeconds: cooldownSeconds,
            ),
          ),
          bottomNavigationBar: _buildMobileBottomNavBar(),
        );
      },
    );
  }

  Widget _buildDesktopWorkspace({
    required String contractHashLabel,
    required String invoiceHashLabel,
  }) {
    return Column(
      children: [
        // Top Command Bar
        const TopCommandBar(),

        // Main 3-Column Split Viewport (Equal 1:1 Contract & Invoice = 75%, Studio = 25%)
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(
                      flex: 1,
                      child: ClipRect(
                        child: ContractViewerPanel(),
                      ),
                    ),
                    Container(
                      width: 1,
                      color: AppColors.borderSubtle,
                    ),
                    const Expanded(
                      flex: 1,
                      child: ClipRect(
                        child: InvoiceViewerPanel(),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                color: AppColors.borderSubtle,
              ),

              // Right Pane: Discrepancy & Action Studio (25%)
              const Expanded(
                flex: 1,
                child: ClipRect(
                  child: ActionStudioPanel(),
                ),
              ),
            ],
          ),
        ),

        // Enterprise Desktop Status Bar
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 6, height: 6),
                ),
                const SizedBox(width: 6),
                Builder(
                  builder: (context) {
                    final completedEngine =
                        ref.watch(auditProvider).asData?.value?.auditEngine;
                    final defaultEngine = ref
                        .watch(geminiAuditServiceProvider)
                        .activeModelDisplayName;
                    final label = completedEngine == null
                        ? 'AI Engine: $defaultEngine'
                        : (completedEngine.startsWith('Engine:')
                            ? completedEngine
                            : 'AI Engine: $completedEngine');
                    return Text(label, style: AppTypography.labelMicro);
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                const Text('•', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(width: AppSpacing.md),
                Text(
                  contractHashLabel,
                  style: AppTypography.monoCitation,
                ),
                const SizedBox(width: AppSpacing.md),
                const Text('•', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(width: AppSpacing.md),
                Text(
                  invoiceHashLabel,
                  style: AppTypography.monoCitation,
                ),
                const SizedBox(width: AppSpacing.xl),
                const Text(
                  'ClairDocs Desktop Enterprise v1.0.0',
                  style: AppTypography.labelMicro,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileWorkspace({
    required ContractState contractState,
    required InvoiceState invoiceState,
    required AsyncValue<AuditResult?> auditAsync,
    required String? retryStatus,
    required int cooldownSeconds,
  }) {
    final contractDoc = contractState.document;
    final invoiceDoc = invoiceState.document;
    final hasContract = contractDoc != null || contractState.isDemoMode;
    final hasInvoice = invoiceDoc != null || invoiceState.isDemoMode;
    final hasAnyDocument = hasContract || hasInvoice;
    final isAuditing = auditAsync.isLoading;
    final isAuditButtonDisabled =
        !hasAnyDocument || isAuditing || cooldownSeconds > 0;
    final activeResult = auditAsync.asData?.value;

    final contractName = contractDoc?.fileName ??
        (contractState.isDemoMode
            ? 'Master_Services_Agreement_2026.pdf'
            : 'No Contract');
    final invoiceName = invoiceDoc?.fileName ??
        (invoiceState.isDemoMode
            ? 'Apex_Tech_Invoice_INV-2026-889.pdf'
            : 'No Invoice');

    return IndexedStack(
      index: _mobileNavIndex,
      children: [
        // Tab 0: Home (Unified Document & Audit Setup Screen)
        _buildMobileHomeTab(
          contractState: contractState,
          invoiceState: invoiceState,
          auditAsync: auditAsync,
          retryStatus: retryStatus,
          cooldownSeconds: cooldownSeconds,
          hasContract: hasContract,
          hasInvoice: hasInvoice,
          hasAnyDocument: hasAnyDocument,
          contractName: contractName,
          invoiceName: invoiceName,
          isAuditing: isAuditing,
          isAuditButtonDisabled: isAuditButtonDisabled,
          activeResult: activeResult,
        ),

        // Tab 1: Audit Vault (Dedicated Full-Screen Screen)
        AuditVaultDialog(
          isFullScreen: true,
          onReload: () {
            setState(() => _mobileNavIndex = 0);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MobileAuditResultsScreen(),
              ),
            );
          },
        ),

        // Tab 2: Analytics (Dedicated Full-Screen Dashboard)
        const AnalyticsDashboardScreen(showBackButton: false),

        // Tab 3: Settings (Dedicated Full-Screen Store Room & Theme)
        SettingsDialog(
          isFullScreen: true,
          onDone: () => setState(() => _mobileNavIndex = 0),
        ),
      ],
    );
  }

  Widget _buildMobileHomeTab({
    required ContractState contractState,
    required InvoiceState invoiceState,
    required AsyncValue<AuditResult?> auditAsync,
    required String? retryStatus,
    required int cooldownSeconds,
    required bool hasContract,
    required bool hasInvoice,
    required bool hasAnyDocument,
    required String contractName,
    required String invoiceName,
    required bool isAuditing,
    required bool isAuditButtonDisabled,
    required AuditResult? activeResult,
  }) {
    final isDark = AppColors.isDark(context);

    return Column(
      children: [
        // 1. Clean Mobile Top Header
        _buildMobileTopHeader(
          auditAsync: auditAsync,
          retryStatus: retryStatus,
          hasAnyDocument: hasAnyDocument,
          activeResult: activeResult,
        ),

        // 2. Unified Document & Audit Setup Screen (Scrollable Body)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Relocated Discrepancies Status Banner
                if (activeResult != null && activeResult.findings.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.crimson.withValues(alpha: 0.4),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 15,
                            color: AppColors.crimson,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${activeResult.findings.length} Discrepanc${activeResult.findings.length == 1 ? 'y' : 'ies'} Detected',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamilySans,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.crimson,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Governing Contract Card
                _buildMobileContractCard(
                  contractState: contractState,
                  contractName: contractName,
                  hasContract: hasContract,
                ),
                const SizedBox(height: AppSpacing.sm + 2),

                // Vendor Invoice Card
                _buildMobileInvoiceCard(
                  invoiceState: invoiceState,
                  invoiceName: invoiceName,
                  hasInvoice: hasInvoice,
                ),
                const SizedBox(height: AppSpacing.sm + 2),

                // Explicit "Run AI Audit" Button
                _buildMobileRunAuditButton(
                  isAuditButtonDisabled: isAuditButtonDisabled,
                  isAuditing: isAuditing,
                  cooldownSeconds: cooldownSeconds,
                  onRunAudit: () {
                    ref.read(auditProvider.notifier).runAudit();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MobileAuditResultsScreen(),
                      ),
                    );
                  },
                ),

                // Dedicated Findings or Progress Actions
                if (activeResult != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MobileAuditResultsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment_outlined, size: 16),
                    label: Text(
                      'View Audit Findings (${activeResult.findings.length})',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevateOf(context),
                      foregroundColor:
                          isDark ? AppColors.sky : AppColors.brandAccentDark,
                      side: BorderSide(
                        color: (isDark
                                ? AppColors.sky
                                : AppColors.brandAccent)
                            .withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ] else if (isAuditing) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MobileAuditResultsScreen(),
                        ),
                      );
                    },
                    icon: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sky,
                      ),
                    ),
                    label: const Text('View Active Audit Progress...'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sky,
                      side: BorderSide(
                        color: AppColors.sky.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ] else if (auditAsync.hasError) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MobileAuditResultsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AppColors.crimson,
                    ),
                    label: const Text('View Audit Error & Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.crimson,
                      side: BorderSide(
                        color: AppColors.crimson.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTopHeader({
    required AsyncValue<AuditResult?> auditAsync,
    required String? retryStatus,
    required bool hasAnyDocument,
    required AuditResult? activeResult,
  }) {
    final isDark = AppColors.isDark(context);
    final brandBadge = Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevateOf(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: (isDark ? AppColors.brandAccent : AppColors.brandAccentDark)
              .withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.brandAccent : AppColors.brandAccentDark)
                .withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClairLogoBadge(
            size: 20,
            borderRadius: 5,
          ),
          const SizedBox(width: 5),
          Text(
            'ClairDocs',
            style: TextStyle(
              fontFamily: AppTypography.fontFamilySans,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceCardOf(context),
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtleOf(context)),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: brandBadge,
            ),
          ),
          Center(
            child: _buildCenteredMobileStatusBadge(
              auditAsync: auditAsync,
              retryStatus: retryStatus,
              hasAnyDocument: hasAnyDocument,
              activeResult: activeResult,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredMobileStatusBadge({
    required AsyncValue<AuditResult?> auditAsync,
    required String? retryStatus,
    required bool hasAnyDocument,
    required AuditResult? activeResult,
  }) {
    if (auditAsync.isLoading) {
      final isRetryWait = retryStatus != null && retryStatus.isNotEmpty;
      final accent = isRetryWait ? AppColors.amber : AppColors.sky;
      final bg = isRetryWait ? AppColors.amberBg : AppColors.skyBg;
      final label = isRetryWait ? retryStatus : 'Auditing...';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamilySans,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      );
    }

    if (auditAsync.hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.crimsonBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 12, color: AppColors.crimson),
            SizedBox(width: 5),
            Text(
              '• Attention Required',
              style: TextStyle(
                fontFamily: AppTypography.fontFamilySans,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.crimson,
              ),
            ),
          ],
        ),
      );
    }

    final isDark = AppColors.isDark(context);
    if (activeResult == null) {
      if (!hasAnyDocument) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevateOf(context),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.borderSubtleOf(context)),
          ),
          child: Text(
            '• Awaiting Documents',
            style: TextStyle(
              fontFamily: AppTypography.fontFamilySans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.skyBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.sky.withValues(alpha: 0.4)),
        ),
        child: Text(
          '• Ready for Audit',
          style: TextStyle(
            fontFamily: AppTypography.fontFamilySans,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.sky : AppColors.brandAccentDark,
          ),
        ),
      );
    }

    final count = activeResult.findings.length;
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.emeraldBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
        ),
        child: const Text(
          '• 100% Compliant',
          style: TextStyle(
            fontFamily: AppTypography.fontFamilySans,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.emerald,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emeraldBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
      ),
      child: const Text(
        '• Audit Complete',
        style: TextStyle(
          fontFamily: AppTypography.fontFamilySans,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.emerald,
        ),
      ),
    );
  }

  Widget _buildMobileContractCard({
    required ContractState contractState,
    required String contractName,
    required bool hasContract,
  }) {
    final contractDoc = contractState.document;
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCardOf(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtleOf(context)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppColors.sky,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Governing Contract',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: hasContract
                      ? AppColors.skyBg
                      : (isDark
                          ? AppColors.surfaceElevate
                          : AppColors.surfaceSecondaryLight),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: hasContract
                        ? AppColors.sky.withValues(alpha: 0.35)
                        : AppColors.borderSubtleOf(context),
                  ),
                ),
                child: Text(
                  hasContract
                      ? (contractState.isDemoMode ? 'Demo Active' : 'Live Doc')
                      : 'Required',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamilySans,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasContract
                        ? (isDark ? AppColors.sky : AppColors.brandAccentDark)
                        : (isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasContract) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevate
                    : AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderSubtleOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.file_present_rounded,
                        size: 16,
                        color: AppColors.sky,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contractName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamilySans,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contractDoc != null
                        ? 'SHA-256: ${contractDoc.sha256Hash.substring(0, 16)}... • ${contractDoc.formattedSize}'
                        : 'Sample Master Services Agreement (MSA 2026)',
                    style: AppTypography.monoCitation.copyWith(
                      color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(contractDocumentProvider.notifier)
                        .pickAndLoadContract(),
                    icon: const Icon(Icons.file_upload_outlined, size: 14),
                    label: const Text('Replace Contract'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryOf(context),
                      side: BorderSide(color: AppColors.borderSubtleOf(context)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          backgroundColor:
                              AppColors.surfaceBackgroundOf(context),
                          body: SafeArea(
                            child: Column(
                              children: [
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCardOf(context),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.borderSubtleOf(context),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        tooltip: 'Back',
                                        color:
                                            AppColors.textPrimaryOf(context),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.skyBg,
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: const Icon(
                                          Icons.description_outlined,
                                          size: 16,
                                          color: AppColors.sky,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Governing Contract Viewer',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            color: AppColors.textPrimaryOf(context),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Expanded(child: ContractViewerPanel()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryOf(context),
                    side: BorderSide(color: AppColors.borderSubtleOf(context)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () => ref
                      .read(contractDocumentProvider.notifier)
                      .clearContract(),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.crimson,
                  tooltip: 'Clear Contract',
                  splashRadius: 16,
                ),
              ],
            ),
          ] else ...[
            Text(
              'Upload the governing Master Services Agreement (MSA) or Rate Card specifying agreed pricing terms.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(contractDocumentProvider.notifier)
                        .pickAndLoadContract(),
                    icon: const Icon(Icons.upload_file_rounded, size: 15),
                    label: const Text('Upload Contract'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sky,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(contractDocumentProvider.notifier)
                        .setDemoMode(true),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Demo Sample'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryOf(context),
                      side: BorderSide(color: AppColors.borderSubtleOf(context)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Supports PDF, Word (.docx), or Spreadsheet (.xlsx, .csv)',
                style: AppTypography.labelMicro.copyWith(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileInvoiceCard({
    required InvoiceState invoiceState,
    required String invoiceName,
    required bool hasInvoice,
  }) {
    final invoiceDoc = invoiceState.document;
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCardOf(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtleOf(context)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vendor Invoice',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: hasInvoice
                      ? AppColors.emeraldBg
                      : (isDark
                          ? AppColors.surfaceElevate
                          : AppColors.surfaceSecondaryLight),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: hasInvoice
                        ? AppColors.emerald.withValues(alpha: 0.35)
                        : AppColors.borderSubtleOf(context),
                  ),
                ),
                child: Text(
                  hasInvoice
                      ? (invoiceState.isDemoMode ? 'Demo Active' : 'Live Doc')
                      : 'Required',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamilySans,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasInvoice
                        ? AppColors.emerald
                        : (isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasInvoice) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevate
                    : AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderSubtleOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          invoiceName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamilySans,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoiceDoc != null
                        ? 'SHA-256: ${invoiceDoc.sha256Hash.substring(0, 16)}... • ${invoiceDoc.formattedSize}'
                        : 'Sample Vendor Invoice (INV-2026-889)',
                    style: AppTypography.monoCitation.copyWith(
                      color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(invoiceDocumentProvider.notifier)
                        .pickAndLoadInvoice(),
                    icon: const Icon(Icons.file_upload_outlined, size: 14),
                    label: const Text('Replace Invoice'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryOf(context),
                      side: BorderSide(color: AppColors.borderSubtleOf(context)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          backgroundColor:
                              AppColors.surfaceBackgroundOf(context),
                          body: SafeArea(
                            child: Column(
                              children: [
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCardOf(context),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.borderSubtleOf(context),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        tooltip: 'Back',
                                        color:
                                            AppColors.textPrimaryOf(context),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldBg,
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 16,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Vendor Invoice Viewer',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            color: AppColors.textPrimaryOf(context),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Expanded(child: InvoiceViewerPanel()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryOf(context),
                    side: BorderSide(color: AppColors.borderSubtleOf(context)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () => ref
                      .read(invoiceDocumentProvider.notifier)
                      .clearInvoice(),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.crimson,
                  tooltip: 'Clear Invoice',
                  splashRadius: 16,
                ),
              ],
            ),
          ] else ...[
            Text(
              'Upload the vendor billing invoice to cross-examine line items against contract terms.',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(invoiceDocumentProvider.notifier)
                        .pickAndLoadInvoice(),
                    icon: const Icon(Icons.upload_file_rounded, size: 15),
                    label: const Text('Upload Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(invoiceDocumentProvider.notifier)
                        .setDemoMode(true),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Demo Sample'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryOf(context),
                      side: BorderSide(color: AppColors.borderSubtleOf(context)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Supports PDF, Word (.docx), or Spreadsheet (.xlsx, .csv)',
                style: AppTypography.labelMicro.copyWith(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileRunAuditButton({
    required bool isAuditButtonDisabled,
    required bool isAuditing,
    required int cooldownSeconds,
    required VoidCallback onRunAudit,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isAuditButtonDisabled ? null : onRunAudit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceElevateOf(context),
          disabledForegroundColor: AppColors.textMutedOf(context),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: isAuditButtonDisabled ? 0 : 4,
          shadowColor: AppColors.brandAccent.withValues(alpha: 0.35),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAuditing) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Auditing Documents...',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamilySans,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else ...[
              Icon(
                cooldownSeconds > 0
                    ? Icons.hourglass_bottom_rounded
                    : Icons.auto_awesome_rounded,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                cooldownSeconds > 0
                    ? 'Wait ${cooldownSeconds}s'
                    : 'Run AI Audit',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamilySans,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBottomNavBar() {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.surfaceCardOf(context);
    final elevateBg = AppColors.surfaceElevateOf(context);
    final borderCol = AppColors.borderSubtleOf(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(color: borderCol),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: cardBg,
          indicatorColor: elevateBg,
          height: 62,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontFamily: AppTypography.fontFamilySans,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.textPrimaryOf(context)
                  : (isDark ? AppColors.textMuted : AppColors.textSecondaryLight),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 20,
              color: isSelected
                  ? (isDark ? AppColors.sky : AppColors.brandAccentDark)
                  : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _mobileNavIndex,
          onDestinationSelected: (index) {
            setState(() => _mobileNavIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon:
                  Icon(Icons.home_rounded, color: AppColors.sky),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon:
                  Icon(Icons.inventory_2_rounded, color: AppColors.sky),
              label: 'Audit Vault',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon:
                  Icon(Icons.insights_rounded, color: AppColors.sky),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon:
                  Icon(Icons.settings_rounded, color: AppColors.sky),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
