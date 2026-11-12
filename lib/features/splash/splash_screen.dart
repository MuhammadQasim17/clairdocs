import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/clair_logo_badge.dart';
import '../audit/presentation/screens/audit_workbench_screen.dart';

/// Animated startup splash screen displaying the ClairDocs enterprise emblem,
/// a 1.5-second fade + scale (0.85 -> 1.0) entrance, and a subtle glowing halo
/// pulse before smoothly transitioning to [AuditWorkbenchScreen] at 2.0 seconds.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    final curvedEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedEntrance);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      curvedEntrance,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _entranceController.forward();
    _navigationTimer = Timer(const Duration(seconds: 2), _transitionToWorkbench);
  }

  void _transitionToWorkbench() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const AuditWorkbenchScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle ambient obsidian radial depth
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  AppColors.brandAccentDark.withValues(alpha: 0.14),
                  AppColors.background,
                ],
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                key: const ValueKey('splash_entrance_scale'),
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final pulse = _pulseAnimation.value;
                        return ClairLogoBadge(
                          size: 96,
                          borderRadius: 22,
                          borderColor: Color.lerp(
                            AppColors.brandAccent.withValues(alpha: 0.45),
                            AppColors.sky.withValues(alpha: 0.75),
                            pulse,
                          ),
                          shadows: [
                            BoxShadow(
                              color: AppColors.brandAccent.withValues(
                                alpha: 0.22 + (0.20 * pulse),
                              ),
                              blurRadius: 24 + (16 * pulse),
                              spreadRadius: 2 + (5 * pulse),
                            ),
                            BoxShadow(
                              color: AppColors.sky.withValues(
                                alpha: 0.10 + (0.14 * pulse),
                              ),
                              blurRadius: 40 + (18 * pulse),
                              spreadRadius: 1 + (3 * pulse),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.appTagline,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
