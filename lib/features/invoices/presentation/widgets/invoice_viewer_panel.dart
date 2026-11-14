import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/document_file_helper.dart';
import '../../../../core/widgets/clair_pdf_viewer.dart';
import '../../../../core/widgets/document_pane_header.dart';
import '../../../../core/widgets/pdf_empty_dropzone.dart';
import '../../../../core/widgets/selectable_audit_card.dart';
import '../../../../core/widgets/word_document_preview.dart';
import '../../../audit/models/audit_models.dart';
import '../../../audit/presentation/widgets/discrepancy_item_card.dart';
import '../../../audit/presentation/widgets/document_viewer_pane.dart';
import '../../../audit/providers/audit_provider.dart';
import '../../../disputes/providers/dispute_provider.dart';
import '../../providers/invoice_providers.dart';

class InvoiceViewerPanel extends ConsumerStatefulWidget {
  const InvoiceViewerPanel({super.key});

  @override
  ConsumerState<InvoiceViewerPanel> createState() => _InvoiceViewerPanelState();
}

class _InvoiceViewerPanelState extends ConsumerState<InvoiceViewerPanel> {
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey _line01Key = GlobalKey();
  final GlobalKey _line03Key = GlobalKey();
  final GlobalKey _line05Key = GlobalKey();
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _zoomIn({required bool isPdf}) {
    final nextZoom = (_zoomLevel + 0.25).clamp(0.5, 3.0);
    if (isPdf) {
      _pdfController.zoomLevel = nextZoom;
    }
    setState(() => _zoomLevel = nextZoom);
  }

  void _zoomOut({required bool isPdf}) {
    final nextZoom = (_zoomLevel - 0.25).clamp(0.5, 3.0);
    if (isPdf) {
      _pdfController.zoomLevel = nextZoom;
    }
    setState(() => _zoomLevel = nextZoom);
  }

  void _resetZoom({required bool isPdf}) {
    if (isPdf) {
      _pdfController.zoomLevel = 1.0;
    }
    setState(() => _zoomLevel = 1.0);
  }

  String? _matchingDemoLine(AuditFinding? finding) {
    if (finding == null) return null;
    final haystack =
        '${finding.id} ${finding.invoiceLineReference} ${finding.searchKeyword ?? ''} ${finding.title}'
            .toLowerCase();
    if (haystack.contains('finding-01') ||
        haystack.contains('#01') ||
        haystack.contains('architect') ||
        haystack.contains('210')) {
      return '01';
    }
    if (haystack.contains('finding-02') ||
        haystack.contains('#03') ||
        haystack.contains('first-class') ||
        haystack.contains('flight') ||
        haystack.contains('airfare')) {
      return '03';
    }
    if (haystack.contains('finding-03') ||
        haystack.contains('#05') ||
        haystack.contains('volume') ||
        haystack.contains('rebate')) {
      return '05';
    }
    return null;
  }

  void _scrollToDemoLine(AuditFinding? finding) {
    final line = _matchingDemoLine(finding);
    final key = switch (line) {
      '01' => _line01Key,
      '03' => _line03Key,
      '05' => _line05Key,
      _ => null,
    };
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.25,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceDocumentProvider);
    final notifier = ref.read(invoiceDocumentProvider.notifier);
    final doc = invoiceState.document;
    final hasFile = doc != null;
    final isPdf = hasFile && DocumentFileHelper.isPdfPath(doc.filePath);
    final isDemo = invoiceState.isDemoMode;

    ref.listen<int>(findingHighlightSequenceProvider, (_, next) {
      if (next > 0 && isDemo) {
        _scrollToDemoLine(ref.read(activeSelectedFindingProvider));
      }
    });

    final displayTitle = isDemo
        ? 'Apex_Tech_Invoice_INV-2026-889.pdf'
        : (hasFile ? doc.fileName : 'Vendor Invoice');

    final zoomPct = (_zoomLevel * 100).round();

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Toolbar
          DocumentPaneHeader(
            icon: Icons.receipt_outlined,
            accentColor: AppColors.crimson,
            title: displayTitle,
            isDemo: isDemo,
            hasFile: hasFile,
            isPdf: isPdf,
            sha256Hash: doc?.sha256Hash,
            formattedSize: doc?.formattedSize,
            demoStatusLabel: '3 DISPUTES FLAGGED',
            zoomPercent: zoomPct,
            currentPage: _currentPage,
            totalPages: _totalPages,
            onSelectLiveDoc: () => notifier.setDemoMode(false),
            onSelectDemoSample: () => notifier.setDemoMode(true),
            onClearFile: () {
              notifier.clearInvoice();
              ref.read(auditProvider.notifier).resetAudit();
              ref.read(disputeProvider.notifier).reset();
              setState(() {
                _currentPage = 1;
                _totalPages = 0;
                _zoomLevel = 1.0;
              });
            },
            onZoomOut: () => _zoomOut(isPdf: isPdf),
            onZoomIn: () => _zoomIn(isPdf: isPdf),
            onResetZoom: () => _resetZoom(isPdf: isPdf),
            onPreviousPage:
                _currentPage > 1 ? () => _pdfController.previousPage() : null,
            onNextPage: _currentPage < _totalPages
                ? () => _pdfController.nextPage()
                : null,
          ),

          // Viewer Canvas Body with Synchronized Line Highlighting
          Expanded(
            child: DocumentViewerPane(
              role: DocumentPaneRole.invoice,
              accentColor: AppColors.crimson,
              pdfController: _pdfController,
              isPdfActive: !isDemo && hasFile && isPdf,
              builder: (
                context,
                activeFinding,
                highlightCandidates,
                highlightSequence,
                pulseStrength,
              ) {
                if (isDemo) {
                  return _buildDemoInvoiceMockup(
                    activeFinding: activeFinding,
                    pulseStrength: pulseStrength,
                  );
                }
                if (hasFile) {
                  return isPdf
                      ? ClairPdfViewer(
                          filePath: doc.filePath,
                          viewerKey: ValueKey('${doc.id}:${doc.filePath}'),
                          controller: _pdfController,
                          onDocumentLoaded: (details) {
                            if (!mounted) return;
                            final count = details.document.pages.count;
                            setState(() {
                              _totalPages = count;
                              _currentPage = 1;
                              _zoomLevel = _pdfController.zoomLevel;
                            });
                            notifier.updatePageCount(count);
                          },
                          onPageChanged: (details) {
                            if (!mounted) return;
                            setState(() {
                              _currentPage = details.newPageNumber;
                            });
                          },
                          onZoomLevelChanged: (details) {
                            if (!mounted) return;
                            setState(() {
                              _zoomLevel = details.newZoomLevel;
                            });
                          },
                          onDocumentLoadFailed: (details) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.crimson,
                                content: Text(
                                  'Failed to render PDF: ${details.description}',
                                ),
                              ),
                            );
                          },
                        )
                      : WordDocumentPreview(
                          key: ValueKey('${doc.id}:${doc.filePath}'),
                          filePath: doc.filePath,
                          accentColor: AppColors.crimson,
                          zoomLevel: _zoomLevel,
                          highlightCandidates: highlightCandidates,
                          highlightSequence: highlightSequence,
                        );
                }
                return PdfEmptyDropzone(
                  title: 'No Vendor Invoice Selected',
                  subtitle:
                      'Select an itemized vendor invoice (.pdf, .docx, .csv, .xlsx, .xls) to cross-audit line items and rates.',
                  buttonLabel: 'Select Vendor Invoice',
                  icon: Icons.receipt_long_outlined,
                  accentColor: AppColors.crimson,
                  isLoading: invoiceState.isLoading,
                  errorMessage: invoiceState.errorMessage,
                  onSelectFile: notifier.pickAndLoadInvoice,
                  onToggleDemoMode: () => notifier.setDemoMode(true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoInvoiceMockup({
    AuditFinding? activeFinding,
    double pulseStrength = 0.0,
  }) {
    final activeLine = _matchingDemoLine(activeFinding);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < AppBreakpoints.compactPhone;
        return Container(
          margin: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
          padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListView(
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APEX TECHNOLOGIES INC.',
                      style: AppTypography.titleMedium.copyWith(
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '450 Mission St, San Francisco, CA 94105\nTax ID: 94-8829103 • billing@apextech.io',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'INVOICE',
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 20,
                        color: AppColors.crimson,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'INV-2026-889',
                      style: AppTypography.monoValue,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Date: Oct 28, 2026 • Terms: Net 30',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.sm),

          // Line Items Table Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevate,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text('Line', style: AppTypography.labelMicro),
                ),
                SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: Text('Description', style: AppTypography.labelMicro),
                ),
                SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Hours',
                      style: AppTypography.labelMicro,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Rate',
                      style: AppTypography.labelMicro,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Amount',
                      style: AppTypography.labelMicro,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          _buildInvoiceLineRow(
            rowKey: _line01Key,
            lineNumber: '01',
            description: 'Cloud Architecture & Infrastructure Delivery',
            hours: '120.0',
            rate: '\$210.00',
            total: '\$25,200.00',
            disputeTag:
                'BREACH: Rate exceeds \$185/hr cap by +\$25/hr (Variance: +\$3,000.00)',
            severity: DiscrepancyCardSeverity.breach,
            isActiveHighlight: activeLine == '01',
            pulseStrength: pulseStrength,
          ),

          _buildInvoiceLineRow(
            lineNumber: '02',
            description: 'Backend Microservices Engineering',
            hours: '80.0',
            rate: '\$135.00',
            total: '\$10,800.00',
            disputeTag: 'MATCH: Rate verified compliant with Schedule B',
            severity: DiscrepancyCardSeverity.info,
          ),

          _buildInvoiceLineRow(
            rowKey: _line03Key,
            lineNumber: '03',
            description: 'Domestic Flight & Ground Transit Reimbursement',
            hours: '—',
            rate: '—',
            total: '\$1,250.00',
            disputeTag:
                'BREACH: First-class cabin violates Clause 9.1 (Variance: +\$1,250.00)',
            severity: DiscrepancyCardSeverity.breach,
            isActiveHighlight: activeLine == '03',
            pulseStrength: pulseStrength,
          ),

          _buildInvoiceLineRow(
            lineNumber: '04',
            description: 'CI/CD Pipeline Automation & Testing',
            hours: '60.0',
            rate: '\$110.00',
            total: '\$6,600.00',
            disputeTag: 'MATCH: Rate compliant',
            severity: DiscrepancyCardSeverity.info,
          ),

          _buildInvoiceLineRow(
            rowKey: _line05Key,
            lineNumber: '05',
            description: 'Quarterly Volume Rebate Tier (> \$40k)',
            hours: '—',
            rate: '0.0%',
            total: '\$0.00',
            disputeTag:
                'CAP WARNING: 5% volume discount omitted per Clause 12.3 (+\$600.00)',
            severity: DiscrepancyCardSeverity.warning,
            isActiveHighlight: activeLine == '05',
            pulseStrength: pulseStrength,
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.sm),

          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Column(
                children: [
                  _buildSummaryRow('Billed Total:', '\$48,250.00', false),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    'Contract Approved:',
                    '\$43,400.00',
                    false,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    'Disputed Withhold:',
                    '+\$4,850.00',
                    true,
                    color: AppColors.crimson,
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceLineRow({
    Key? rowKey,
    required String lineNumber,
    required String description,
    required String hours,
    required String rate,
    required String total,
    required String disputeTag,
    required DiscrepancyCardSeverity severity,
    bool isActiveHighlight = false,
    double pulseStrength = 0.0,
  }) {
    final isBreach = severity == DiscrepancyCardSeverity.breach;
    final isWarning = severity == DiscrepancyCardSeverity.warning;

    final activeStatusColor = isBreach
        ? AppColors.crimson
        : (isWarning ? AppColors.amber : AppColors.emerald);
    final statusColor =
        isActiveHighlight ? activeStatusColor : AppColors.textSecondary;

    return KeyedSubtree(
      key: rowKey,
      child: SelectableAuditCard(
        isSelected: isActiveHighlight,
        pulseStrength: isActiveHighlight ? pulseStrength : 0.0,
        defaultColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(lineNumber, style: AppTypography.monoCitation),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      hours,
                      style: AppTypography.monoCitation,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      rate,
                      style: AppTypography.monoCitation,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      total,
                      style: AppTypography.monoValue.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isActiveHighlight && isBreach
                            ? AppColors.crimson
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isBreach
                      ? Icons.warning_amber_rounded
                      : (isWarning
                          ? Icons.info_outline
                          : Icons.check_circle_outline),
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    disputeTag,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 10,
                      fontWeight:
                          isActiveHighlight ? FontWeight.w600 : FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isBold, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.monoValue.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
