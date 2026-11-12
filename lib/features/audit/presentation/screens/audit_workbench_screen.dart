import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../contracts/presentation/widgets/contract_viewer_panel.dart';
import '../../../contracts/providers/contract_providers.dart';
import '../../../invoices/presentation/widgets/invoice_viewer_panel.dart';
import '../../../invoices/providers/invoice_providers.dart';
import '../../providers/audit_provider.dart';
import '../widgets/top_command_bar.dart';
import '../widgets/action_studio_panel.dart';

class AuditWorkbenchScreen extends ConsumerWidget {
  const AuditWorkbenchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractDoc = ref.watch(contractDocumentProvider).document;
    final invoiceDoc = ref.watch(invoiceDocumentProvider).document;

    final contractHashLabel = contractDoc != null
        ? 'Contract SHA-256: ${contractDoc.sha256Hash.substring(0, 12)}...'
        : 'Contract: Ready for ingestion';
    final invoiceHashLabel = invoiceDoc != null
        ? 'Invoice SHA-256: ${invoiceDoc.sha256Hash.substring(0, 12)}...'
        : 'Invoice: Ready for ingestion';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
        ),
      ),
    );
  }
}
