import 'dart:io';
import 'package:flutter/material.dart';
import '../../features/audit/services/pdf_extraction_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/document_file_helper.dart';

class WordDocumentPreview extends StatefulWidget {
  final String filePath;
  final Color accentColor;
  final double zoomLevel;
  final List<String> highlightCandidates;
  final int highlightSequence;

  const WordDocumentPreview({
    super.key,
    required this.filePath,
    required this.accentColor,
    this.zoomLevel = 1.0,
    this.highlightCandidates = const [],
    this.highlightSequence = 0,
  });

  @override
  State<WordDocumentPreview> createState() => _WordDocumentPreviewState();
}

class _WordDocumentPreviewState extends State<WordDocumentPreview> {
  static const _extractor = PdfExtractionService();
  final ScrollController _scrollController = ScrollController();
  late Future<String> _textFuture;
  String? _loadedText;

  @override
  void initState() {
    super.initState();
    _textFuture = _extractor.extractDocumentText(File(widget.filePath));
  }

  @override
  void didUpdateWidget(covariant WordDocumentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _loadedText = null;
      _textFuture = _extractor.extractDocumentText(File(widget.filePath));
    } else if (oldWidget.highlightSequence != widget.highlightSequence &&
        widget.highlightCandidates.isNotEmpty) {
      _scrollToFirstMatch();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ({String? query, int offset}) _findBestMatch(String text) {
    if (text.isEmpty || widget.highlightCandidates.isEmpty) {
      return (query: null, offset: -1);
    }
    final lowerText = text.toLowerCase();
    for (final candidate in widget.highlightCandidates) {
      final idx = lowerText.indexOf(candidate.toLowerCase());
      if (idx >= 0) {
        return (query: candidate, offset: idx);
      }
    }
    return (query: null, offset: -1);
  }

  void _scrollToFirstMatch() {
    final text = _loadedText;
    if (text == null || text.isEmpty || !_scrollController.hasClients) return;
    final match = _findBestMatch(text);
    if (match.offset < 0) return;

    final ratio = (match.offset / text.length).clamp(0.0, 1.0);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = (maxScroll * ratio - 40).clamp(0.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  TextSpan _buildHighlightedTextSpan(
    String text,
    TextStyle baseStyle,
    String? activeQuery,
  ) {
    if (activeQuery == null || activeQuery.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = activeQuery.toLowerCase();
    final spans = <TextSpan>[];
    var cursor = 0;

    while (cursor < text.length) {
      final hit = lowerText.indexOf(lowerQuery, cursor);
      if (hit < 0) {
        spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
        break;
      }
      if (hit > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, hit), style: baseStyle));
      }
      spans.add(
        TextSpan(
          text: text.substring(hit, hit + activeQuery.length),
          style: baseStyle.copyWith(
            backgroundColor: AppColors.amber.withValues(alpha: 0.38),
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = hit + activeQuery.length;
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  @override
  Widget build(BuildContext context) {
    final isSpreadsheet = DocumentFileHelper.isSpreadsheetPath(widget.filePath);

    return FutureBuilder<String>(
      future: _textFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: widget.accentColor),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isSpreadsheet
                      ? 'Parsing spreadsheet rows...'
                      : 'Parsing Microsoft Word XML paragraphs...',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.crimsonBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.crimson,
                      size: 28,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isSpreadsheet
                          ? 'Failed to Preview Spreadsheet'
                          : 'Failed to Preview Word Document',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error.toString(),
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final extractedText = snapshot.data?.trim() ?? '';
        _loadedText = extractedText;
        final match = _findBestMatch(extractedText);
        final textStyle = TextStyle(
          fontFamily: AppTypography.fontFamilyMono,
          fontSize: (12.5 * widget.zoomLevel).clamp(9.0, 24.0),
          height: 1.55,
          color: AppColors.textPrimary,
        );

        return Container(
          alignment: Alignment.topLeft,
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
          child: extractedText.isEmpty
              ? Center(
                  child: Text(
                    isSpreadsheet
                        ? 'No readable spreadsheet rows found in this file.'
                        : 'No readable paragraph text found in this document.',
                    style: AppTypography.bodySmall,
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    width: double.infinity,
                    child: SelectableText.rich(
                      _buildHighlightedTextSpan(
                        extractedText,
                        textStyle,
                        match.query,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
