import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_images.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';
import '../widgets/app_outline_button.dart';
import '../widgets/outline_headline.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.next,
    this.autoNavigate = true,
    this.splashDuration = const Duration(milliseconds: 2600),
  });

  final Widget next;
  final bool autoNavigate;
  final Duration splashDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  Timer? _autoNavigateTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();

    if (widget.autoNavigate) {
      _autoNavigateTimer = Timer(widget.splashDuration, () {
        if (mounted && !_hasNavigated) {
          _continue(context);
        }
      });
    }
  }

  Future<void> _initVideoPlayer() async {
    _videoController = VideoPlayerController.asset(AppImages.fuelNozzle);
    try {
      await _videoController.initialize();
      if (!mounted) return;
      _videoController.setLooping(true);
      _videoController.setVolume(0.0);
      await _videoController.play();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (_) {
      // Fallback gracefully if video fails to load
    }
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _autoNavigateTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.slow,
        pageBuilder: (_, animation, _) => widget.next,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => _continue(context),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
          // 1. Full Screen Video Background (100% Full Screen, No Half-Screen Boundaries)
          if (_isVideoInitialized && _videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
                .animate()
                .slideX(
                  begin: -0.85,
                  end: 0,
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.easeOutCubic,
                )
                .slideY(
                  begin: -0.15,
                  end: 0,
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.easeOutCubic,
                )
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                ),

          // 2. Smooth Full Screen Dark Gradient Overlay for text readability
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x33000000),
                  Color(0xDD000000),
                  Colors.black,
                ],
                stops: [0.0, 0.45, 0.72, 1.0],
              ),
            ),
          ),

            // Foreground Content
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
                    if (!widget.autoNavigate) ...[
                      Row(
                        children: const [
                          _Dot(active: true),
                          SizedBox(width: 6),
                          _Dot(active: false),
                          SizedBox(width: 6),
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
