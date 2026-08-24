import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_images.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.next,
    this.autoNavigate = true,
    this.isCheckingData = false,
    this.splashDuration = const Duration(milliseconds: 1800),
    this.getNextScreen,
  });

  final Widget next;
  final bool autoNavigate;
  final bool isCheckingData;
  final Duration splashDuration;
  final Widget Function()? getNextScreen;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late final AnimationController _entranceController;
  late final AnimationController _videoFadeController;
  late final Animation<double> _textFadeAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _dotsFadeAnimation;
  late final Animation<Offset> _dotsSlideAnimation;
  late final Animation<double> _buttonFadeAnimation;
  late final Animation<Offset> _buttonSlideAnimation;

  Timer? _autoNavigateTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _videoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));

    _dotsFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
    );

    _dotsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
    ));

    _buttonFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
    _initVideoPlayer();

    if (widget.autoNavigate && !widget.isCheckingData) {
      _startAutoNavigateTimer();
    }
  }

  void _startAutoNavigateTimer() {
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(widget.splashDuration, () {
      if (mounted && !_hasNavigated) {
        _continue(context);
      }
    });
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isCheckingData) {
      if (widget.autoNavigate && _autoNavigateTimer == null && !_hasNavigated) {
        _startAutoNavigateTimer();
      }
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      final controller = VideoPlayerController.asset(
        AppImages.fuelNozzle,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _videoController = controller;
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();

      if (mounted) {
        _videoFadeController.forward();
        setState(() {});
      }
    } catch (_) {
      // Fallback gracefully to poster image
    }
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _entranceController.dispose();
    _videoFadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _autoNavigateTimer?.cancel();

    final target = widget.getNextScreen?.call() ?? widget.next;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, secondaryAnimation) => target,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showOnboardingControls = !widget.isCheckingData && !widget.autoNavigate;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: GestureDetector(
        onTap: () => _continue(context),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Solid Base Background
            const ColoredBox(color: Color(0xFF121212)),

            // Layer 2: High-resolution static poster image (seamless instant background while video decodes)
            Positioned.fill(
              child: Image.asset(
                AppImages.onboardingHero,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),

            // Layer 3: Video Player Layer with smooth 1000ms GPU crossfade
            if (_videoController != null && _videoController!.value.isInitialized)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _videoFadeController,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              ),

            // Layer 4: Linear Gradient Overlay for perfect typography contrast
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.35, 0.65, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(0x22121212),
                      Color(0xDD121212),
                      Color(0xFF121212),
                    ],
                  ),
                ),
              ),
            ),

            // Layer 5: Foreground Content with Typography & Modern Controls
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

                    // Typography Column with smooth entrance animation
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: SlideTransition(
                        position: _textSlideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                  letterSpacing: -0.8,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Master ',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Your Mileage.',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Precision tracking for every drop of fuel and every mile you drive.',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white70,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    if (showOnboardingControls) ...[
                      // Left-aligned modern dot indicators
                      FadeTransition(
                        opacity: _dotsFadeAnimation,
                        child: SlideTransition(
                          position: _dotsSlideAnimation,
                          child: Row(
                            children: const [
                              _Dot(active: true),
                              SizedBox(width: 6),
                              _Dot(active: false),
                              SizedBox(width: 6),
                              _Dot(active: false),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Solid Neon Orange CTA spanning full width with padding
                      FadeTransition(
                        opacity: _buttonFadeAnimation,
                        child: SlideTransition(
                          position: _buttonSlideAnimation,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => _continue(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor:
                                    AppColors.primary.withValues(alpha: 0.45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'GET STARTED',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
      width: active ? 26 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.white24,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
    );
  }
}
