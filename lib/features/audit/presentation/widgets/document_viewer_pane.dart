import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/audit_models.dart';
import '../../providers/audit_provider.dart';

enum DocumentPaneRole { contract, invoice }

/// Wraps a Contract or Invoice document viewport, connecting clicks on audit
/// finding cards ([activeSelectedFindingProvider]) to programmatic PDF search
/// & highlight (`pdfViewerController.searchText`), inline preview search, and
/// a temporary pulsing edge glow around the active match.
class DocumentViewerPane extends ConsumerStatefulWidget {
  final DocumentPaneRole role;
  final Color accentColor;
  final PdfViewerController pdfController;
  final bool isPdfActive;
  final Widget Function(
    BuildContext context,
    AuditFinding? activeFinding,
    List<String> highlightCandidates,
    int highlightSequence,
    double pulseStrength,
  ) builder;

  const DocumentViewerPane({
    super.key,
    required this.role,
    required this.accentColor,
    required this.pdfController,
    required this.isPdfActive,
    required this.builder,
  });

  /// Builds prioritized searchable query phrases for a finding in either the
  /// governing contract or vendor invoice pane.
  static List<String> buildSearchCandidates(
    AuditFinding finding, {
    required DocumentPaneRole role,
  }) {
    final ordered = <String>{};

    void addCandidate(String? raw) {
      if (raw == null) return;
      final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalized.length >= 2) {
        ordered.add(normalized);
      }
    }

    final clauseCore =
        finding.clauseReference.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final parentheticalMatch =
        RegExp(r'\(([^)]+)\)').firstMatch(finding.clauseReference);
    final clauseSubLabel = parentheticalMatch?.group(1)?.trim();
    final clauseNumber =
        RegExp(r'\d+(?:\.\d+)+').firstMatch(finding.clauseReference)?.group(0);

    final keyword = finding.searchKeyword?.trim();
    final titleSubject = finding.title.contains(':')
        ? finding.title.split(':').sublist(1).join(':').trim()
        : finding.title.trim();

    final lineNumber =
        RegExp(r'#?\d+').firstMatch(finding.invoiceLineReference)?.group(0);

    if (role == DocumentPaneRole.contract) {
      addCandidate(clauseCore);
      addCandidate(keyword);
      addCandidate(clauseNumber);
      addCandidate(clauseSubLabel);
      addCandidate(titleSubject);
      addCandidate(finding.clauseReference);
    } else {
      addCandidate(keyword);
      addCandidate(titleSubject);
      addCandidate(finding.invoiceLineReference);
      if (lineNumber != null && lineNumber.startsWith('#')) {
        addCandidate(lineNumber);
      }
      addCandidate(clauseCore);
    }

    return ordered.toList(growable: false);
  }

  @override
  ConsumerState<DocumentViewerPane> createState() => _DocumentViewerPaneState();
}

class _DocumentViewerPaneState extends ConsumerState<DocumentViewerPane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _pulseCurve;

  PdfTextSearchResult? _searchResult;
  int _searchGeneration = 0;
  List<String> _activeCandidates = const [];
  int _candidateCursor = 0;
  String? _activeMatchedQuery;
  String? _statusLabel;
  int _matchCount = 0;
  int _currentMatchIndex = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseCurve = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.35)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.35, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_glowController);
  }

  @override
  void didUpdateWidget(covariant DocumentViewerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPdfActive && !widget.isPdfActive) {
      _detachSearchListener(clearPdfHighlights: true);
      if (mounted) {
        setState(() {
          _matchCount = 0;
          _currentMatchIndex = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _detachSearchListener(clearPdfHighlights: false);
    _glowController.dispose();
    super.dispose();
  }

  void _detachSearchListener({required bool clearPdfHighlights}) {
    final existing = _searchResult;
    if (existing != null) {
      existing.removeListener(_handlePdfSearchUpdate);
      if (clearPdfHighlights) {
        try {
          existing.clear();
        } catch (_) {
          // Ignore if controller is already torn down.
        }
      }
      _searchResult = null;
    }
  }

  void _clearHighlight({bool clearProviderSelection = false}) {
    _searchGeneration++;
    _detachSearchListener(clearPdfHighlights: widget.isPdfActive);
    _glowController.stop();
    _glowController.value = 0.0;
    setState(() {
      _activeCandidates = const [];
      _candidateCursor = 0;
      _activeMatchedQuery = null;
      _statusLabel = null;
      _matchCount = 0;
      _currentMatchIndex = 0;
    });
    if (clearProviderSelection) {
      ref.read(activeSelectedFindingProvider.notifier).clear();
    }
  }

  void _onFindingActivated(AuditFinding? finding) {
    if (!mounted) return;
    if (finding == null) {
      _clearHighlight();
      return;
    }

    final candidates = DocumentViewerPane.buildSearchCandidates(
      finding,
      role: widget.role,
    );
    if (candidates.isEmpty) {
      _clearHighlight();
      return;
    }

    final generation = ++_searchGeneration;
    setState(() {
      _activeCandidates = candidates;
      _candidateCursor = 0;
      _activeMatchedQuery = candidates.first;
      _statusLabel = widget.isPdfActive
          ? 'Searching "${candidates.first}"...'
          : 'Highlighted: ${candidates.first}';
      _matchCount = 0;
      _currentMatchIndex = 0;
    });

    _glowController.forward(from: 0.0);

    if (widget.isPdfActive) {
      _runPdfSearchCandidate(generation);
    }
  }

  void _runPdfSearchCandidate(int generation) {
    if (!mounted || generation != _searchGeneration) return;
    if (_candidateCursor >= _activeCandidates.length) {
      setState(() {
        _statusLabel = 'Ref: ${_activeCandidates.first}';
        _matchCount = 0;
        _currentMatchIndex = 0;
      });
      return;
    }

    final query = _activeCandidates[_candidateCursor];
    _detachSearchListener(clearPdfHighlights: false);

    try {
      final result = widget.pdfController.searchText(query);
      _searchResult = result;
      _activeMatchedQuery = query;
      result.addListener(_handlePdfSearchUpdate);
      if (result.isSearchCompleted) {
        _handlePdfSearchUpdate();
      }
    } catch (_) {
      _candidateCursor++;
      _runPdfSearchCandidate(generation);
    }
  }

  void _handlePdfSearchUpdate() {
    if (!mounted) return;
    final result = _searchResult;
    if (result == null) return;

    if (!result.isSearchCompleted) {
      if (result.totalInstanceCount > 0) {
        setState(() {
          _matchCount = result.totalInstanceCount;
          _currentMatchIndex = result.currentInstanceIndex;
          _statusLabel =
              '"${_activeMatchedQuery ?? ""}" ($_currentMatchIndex/$_matchCount)';
        });
      }
      return;
    }

    if (result.totalInstanceCount > 0) {
      setState(() {
        _matchCount = result.totalInstanceCount;
        _currentMatchIndex = result.currentInstanceIndex;
        _statusLabel =
            '"${_activeMatchedQuery ?? ""}" ($_currentMatchIndex/$_matchCount)';
      });
      return;
    }

    // Current candidate yielded zero hits in this PDF -> try next candidate
    final generation = _searchGeneration;
    _candidateCursor++;
    _runPdfSearchCandidate(generation);
  }

  @override
  Widget build(BuildContext context) {
    final activeFinding = ref.watch(activeSelectedFindingProvider);
    final highlightSeq = ref.watch(findingHighlightSequenceProvider);

    ref.listen<int>(findingHighlightSequenceProvider, (_, next) {
      if (next == 0) {
        _clearHighlight();
      } else {
        _onFindingActivated(ref.read(activeSelectedFindingProvider));
      }
    });

    ref.listen<AuditFinding?>(activeSelectedFindingProvider, (_, next) {
      if (next == null) {
        _clearHighlight();
      }
    });

    return AnimatedBuilder(
      animation: _pulseCurve,
      builder: (context, child) {
        final pulse = _pulseCurve.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.builder(
              context,
              activeFinding,
              _activeCandidates,
              highlightSeq,
              pulse,
            ),

            // Temporary glowing highlight border overlay during jump/highlight
            if (pulse > 0.02)
              IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.78 * pulse),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.25 * pulse),
                        blurRadius: 18 * pulse,
                        spreadRadius: 2 * pulse,
                      ),
                    ],
                  ),
                ),
              ),

            // Active Match / Navigation Pill
            if (activeFinding != null && _statusLabel != null)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 290),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.amber.withValues(
                        alpha: 0.45 + (0.45 * pulse),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      if (pulse > 0.05)
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.28 * pulse),
                          blurRadius: 12 * pulse,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 13,
                        color: widget.isPdfActive && _matchCount > 0
                            ? AppColors.amber
                            : widget.accentColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _statusLabel!,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamilyMono,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isPdfActive && _matchCount > 1) ...[
                        const SizedBox(width: 4),
                        _MiniStepButton(
                          icon: Icons.keyboard_arrow_up,
                          tooltip: 'Previous match',
                          onPressed: () => _searchResult?.previousInstance(),
                        ),
                        _MiniStepButton(
                          icon: Icons.keyboard_arrow_down,
                          tooltip: 'Next match',
                          onPressed: () => _searchResult?.nextInstance(),
                        ),
                      ],
                      const SizedBox(width: 4),
                      _MiniStepButton(
                        icon: Icons.close,
                        tooltip: 'Clear highlight',
                        onPressed: () =>
                            _clearHighlight(clearProviderSelection: true),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MiniStepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MiniStepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(3),
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            icon,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
