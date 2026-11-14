import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/audit_provider.dart';

class AuditSkeletonLoader extends ConsumerStatefulWidget {
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AuditSkeletonLoader({
    super.key,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  ConsumerState<AuditSkeletonLoader> createState() =>
      _AuditSkeletonLoaderState();
}

class _AuditSkeletonLoaderState extends ConsumerState<AuditSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final retryStatus = ref.watch(auditStatusMessageProvider);
    final isRetryWait = retryStatus != null && retryStatus.isNotEmpty;
    final bannerAccent = isRetryWait ? AppColors.amber : AppColors.sky;
    final bannerBg = isRetryWait ? AppColors.amberBg : AppColors.skyBg;
    final bannerText = isRetryWait
        ? retryStatus
        : '${ApiConstants.defaultGeminiModelDisplayName} analyzing PDF clauses & line items...';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulseColor = Color.lerp(
          AppColors.surfaceElevate,
          AppColors.borderSubtle,
          _controller.value,
        )!;

        return ListView(
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Banner Notice (live retry wait status or standard audit banner)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: bannerBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: bannerAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: bannerAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: bannerAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // KPI Skeleton Card
            Container(
              height: 120,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevate.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(width: 140, height: 10, color: pulseColor),
                  const SizedBox(height: 12),
                  _SkeletonBar(width: 180, height: 24, color: pulseColor),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SkeletonBar(width: 90, height: 14, color: pulseColor),
                      _SkeletonBar(width: 90, height: 14, color: pulseColor),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            _SkeletonBar(width: 120, height: 10, color: pulseColor),
            const SizedBox(height: AppSpacing.sm),

            // 3 Finding Skeleton Cards
            for (var i = 0; i < 3; i++) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SkeletonBar(width: 160, height: 12, color: pulseColor),
                        _SkeletonBar(width: 48, height: 16, color: pulseColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _SkeletonBar(width: 210, height: 10, color: pulseColor),
                    const SizedBox(height: 8),
                    _SkeletonBar(
                      width: double.infinity,
                      height: 10,
                      color: pulseColor,
                    ),
                    const SizedBox(height: 6),
                    _SkeletonBar(width: 190, height: 10, color: pulseColor),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SkeletonBar(width: 80, height: 12, color: pulseColor),
                        _SkeletonBar(width: 70, height: 14, color: pulseColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _SkeletonBar({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}
