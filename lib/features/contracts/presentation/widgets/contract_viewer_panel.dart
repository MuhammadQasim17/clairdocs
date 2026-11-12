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
import '../../../audit/presentation/widgets/document_viewer_pane.dart';
import '../../../audit/providers/audit_provider.dart';
import '../../../disputes/providers/dispute_provider.dart';
import '../../providers/contract_providers.dart';

class ContractViewerPanel extends ConsumerStatefulWidget {
  const ContractViewerPanel({super.key});

  @override
  ConsumerState<ContractViewerPanel> createState() =>
      _ContractViewerPanelState();
}

class _ContractViewerPanelState extends ConsumerState<ContractViewerPanel> {
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey _clause42Key = GlobalKey();
  final GlobalKey _clause91Key = GlobalKey();
  final GlobalKey _clause123Key = GlobalKey();
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

  String? _matchingDemoSection(AuditFinding? finding) {
    if (finding == null) return null;
    final haystack =
        '${finding.id} ${finding.clauseReference} ${finding.searchKeyword ?? ''} ${finding.title}'
            .toLowerCase();
    if (haystack.contains('finding-01') ||
        haystack.contains('4.2') ||
        haystack.contains('architect') ||
        haystack.contains('exhibit b')) {
      return '4.2';
    }
    if (haystack.contains('finding-02') ||
        haystack.contains('9.1') ||
        haystack.contains('travel') ||
        haystack.contains('first-class')) {
      return '9.1';
    }
    if (haystack.contains('finding-03') ||
        haystack.contains('12.3') ||
        haystack.contains('volume') ||
        haystack.contains('rebate')) {
      return '12.3';
    }
    return null;
  }

  void _scrollToDemoClause(AuditFinding? finding) {
    final section = _matchingDemoSection(finding);
    final key = switch (section) {
      '4.2' => _clause42Key,
      '9.1' => _clause91Key,
      '12.3' => _clause123Key,
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
    final contractState = ref.watch(contractDocumentProvider);
    final notifier = ref.read(contractDocumentProvider.notifier);
    final doc = contractState.document;
    final hasFile = doc != null;
    final isPdf = hasFile && DocumentFileHelper.isPdfPath(doc.filePath);
    final isDemo = contractState.isDemoMode;

    ref.listen<int>(findingHighlightSequenceProvider, (_, next) {
      if (next > 0 && isDemo) {
        _scrollToDemoClause(ref.read(activeSelectedFindingProvider));
      }
    });

    final displayTitle = isDemo
        ? 'Master_Services_Agreement_2026.pdf'
        : (hasFile ? doc.fileName : 'Governing Contract');

    final zoomPct = (_zoomLevel * 100).round();

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Document Toolbar
          DocumentPaneHeader(
            icon: Icons.description_outlined,
            accentColor: AppColors.sky,
            title: displayTitle,
            isDemo: isDemo,
            hasFile: hasFile,
            isPdf: isPdf,
            sha256Hash: doc?.sha256Hash,
            formattedSize: doc?.formattedSize,
            zoomPercent: zoomPct,
            currentPage: _currentPage,
            totalPages: _totalPages,
            onSelectLiveDoc: () => notifier.setDemoMode(false),
            onSelectDemoSample: () => notifier.setDemoMode(true),
            onClearFile: () {
              notifier.clearContract();
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

          // Viewer Canvas Body with Synchronized Line/Clause Highlighting
          Expanded(
            child: DocumentViewerPane(
              role: DocumentPaneRole.contract,
              accentColor: AppColors.sky,
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
                  return _buildDemoContractMockup(
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
                          accentColor: AppColors.sky,
                          zoomLevel: _zoomLevel,
                          highlightCandidates: highlightCandidates,
                          highlightSequence: highlightSequence,
                        );
                }
                return PdfEmptyDropzone(
                  title: 'No Governing Contract Selected',
                  subtitle:
                      'Select a Master Services Agreement, SOW, or Rate Card (.pdf, .docx, .csv, .xlsx, .xls) to audit.',
                  buttonLabel: 'Select Governing Contract',
                  icon: Icons.description_outlined,
                  accentColor: AppColors.sky,
                  isLoading: contractState.isLoading,
                  errorMessage: contractState.errorMessage,
                  onSelectFile: notifier.pickAndLoadContract,
                  onToggleDemoMode: () => notifier.setDemoMode(true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoContractMockup({
    AuditFinding? activeFinding,
    double pulseStrength = 0.0,
  }) {
    final activeSection = _matchingDemoSection(activeFinding);
    final is42Active = activeSection == '4.2';
    final is91Active = activeSection == '9.1';
    final is123Active = activeSection == '12.3';

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Center(
            child: Column(
              children: [
                Text(
                  'MASTER SERVICES AGREEMENT',
                  style: AppTypography.titleMedium.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Contract Ref: ACME-APEX-2026-SOW-B • Effective Date: January 1, 2026',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'SECTION 3: SCOPE & DELIVERABLES',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            '3.1 Contractor shall render enterprise cloud engineering, architecture, and deployment automation services to Client in accordance with project milestones approved under Schedule A.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),

          // Clause Card 1 (Neutral by default; highlights on hover or finding selection)
          KeyedSubtree(
            key: _clause42Key,
            child: SelectableAuditCard(
              isSelected: is42Active,
              pulseStrength: is42Active ? pulseStrength : 0.0,
              defaultColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'SECTION 4.2: APPROVED BILLING RATE SCHEDULE',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamilySans,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: is42Active
                              ? AppColors.amber
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (is42Active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Text(
                            'SELECTED CLAUSE',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamilySans,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '"Contractor personnel shall bill strictly in accordance with Exhibit B Rate Schedule. The billable rate for Lead Cloud Architect is capped at \$185.00/hour USD, all-inclusive. Under no circumstances may Contractor unilaterally invoice rates in excess of \$185.00/hour without thirty (30) days prior written authorization executed by Client Procurement."',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilyMono,
                      fontSize: 11.5,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          const Text(
            'SECTION 5: INVOICING & PAYMENT TERMS',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            '5.1 Invoices shall be submitted monthly in arrears, itemized with individual resource hours, agreed role rates, and supporting documentation.',
            style: AppTypography.bodySmall,
          ),

          const SizedBox(height: AppSpacing.md),

          // Clause Card 2 (Neutral by default; highlights on hover or finding selection)
          KeyedSubtree(
            key: _clause91Key,
            child: SelectableAuditCard(
              isSelected: is91Active,
              pulseStrength: is91Active ? pulseStrength : 0.0,
              defaultColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'SECTION 9.1: TRAVEL & EXPENSE REIMBURSEMENT',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamilySans,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: is91Active
                              ? AppColors.amber
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (is91Active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Text(
                            'SELECTED CLAUSE',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamilySans,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '"Reimbursable travel expenses require prior written Client budget pre-approval. Domestic airfare is strictly restricted to non-refundable economy class cabins. First-class, business-class, or premium cabin surcharges are expressly non-reimbursable."',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilyMono,
                      fontSize: 11.5,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: _clause123Key,
            child: SelectableAuditCard(
              isSelected: is123Active,
              pulseStrength: is123Active ? pulseStrength : 0.0,
              defaultColor: Colors.transparent,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECTION 12.3: VOLUME DISCOUNTS & REBATES',
                    style: AppTypography.titleSmall,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Upon cumulative billing exceeding \$40,000.00 USD within any calendar quarter, Contractor shall apply a mandatory five percent (5%) volume discount against all billed services.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
