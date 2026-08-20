import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_images.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';
import '../widgets/app_outline_button.dart';
import '../widgets/outline_headline.dart';

/// Premium onboarding splash matching the reference fuel-app look.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.next});

  final Widget next;

  void _continue(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.slow,
        pageBuilder: (_, animation, _) => next,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppImages.onboardingHero,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00121212),
                  Color(0x99121212),
                  AppColors.background,
                  AppColors.background,
                ],
                stops: [0.0, 0.35, 0.62, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 5),
                  const OutlineHeadline(accent: 'Track ', outline: '& Save')
                      .animate()
                      .fadeIn(duration: AppMotion.slow, curve: AppMotion.entrance)
                      .moveY(
                        begin: 18,
                        end: 0,
                        duration: AppMotion.slow,
                        curve: AppMotion.entrance,
                      ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Log fuel, watch mileage, and keep every trip offline.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  )
                      .animate()
                      .fadeIn(
                        delay: AppMotion.fast,
                        duration: AppMotion.normal,
                      ),
                  const Spacer(),
                  Row(
                    children: [
                      _Dot(active: true),
                      const SizedBox(width: 6),
                      _Dot(active: false),
                      const SizedBox(width: 6),
                      _Dot(active: false),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppOutlineButton(
                    label: 'Get Started',
                    onPressed: () => _continue(context),
                  )
                      .animate()
                      .fadeIn(
                        delay: AppMotion.normal,
                        duration: AppMotion.normal,
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

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.textTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
    );
  }
}
