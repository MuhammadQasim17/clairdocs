import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../theme/app_colors.dart';

/// Shared high-resolution PDF viewport used identically by Contract and Invoice panes.
///
/// Ensures a minimum 2.5x rasterization multiplier on standard-DPI desktop screens
/// and a consistent `maxZoomLevel` of `3.0` so small invoice typography stays sharp.
class ClairPdfViewer extends StatelessWidget {
  static const double minRasterScale = 2.5;
  static const double maxScale = 3.0;

  final String filePath;
  final Key? viewerKey;
  final PdfViewerController controller;
  final PdfDocumentLoadedCallback? onDocumentLoaded;
  final PdfPageChangedCallback? onPageChanged;
  final PdfZoomLevelChangedCallback? onZoomLevelChanged;
  final PdfDocumentLoadFailedCallback? onDocumentLoadFailed;

  const ClairPdfViewer({
    super.key,
    required this.filePath,
    required this.controller,
    this.viewerKey,
    this.onDocumentLoaded,
    this.onPageChanged,
    this.onZoomLevelChanged,
    this.onDocumentLoadFailed,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final effectiveDpr = math.max(mediaQuery.devicePixelRatio, minRasterScale);

    return MediaQuery(
      data: mediaQuery.copyWith(devicePixelRatio: effectiveDpr),
      child: SfPdfViewer.file(
        File(filePath),
        key: viewerKey,
        controller: controller,
        maxZoomLevel: maxScale,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        pageSpacing: 6,
        currentSearchTextHighlightColor: AppColors.amber.withValues(alpha: 0.45),
        otherSearchTextHighlightColor: AppColors.sky.withValues(alpha: 0.22),
        onDocumentLoaded: onDocumentLoaded,
        onPageChanged: onPageChanged,
        onZoomLevelChanged: onZoomLevelChanged,
        onDocumentLoadFailed: onDocumentLoadFailed,
      ),
    );
  }
}
