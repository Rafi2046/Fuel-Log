import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Theme-aware shimmer effect controller & shader.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  static Color defaultBase(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF16161E) : const Color(0xFFE6E8EE);
  }

  static Color defaultHighlight(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF282836) : const Color(0xFFF5F6F8);
  }

  static Color bone(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF1E1E28) : const Color(0xFFD0D4DC);
  }

  static Color cardFill(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF15151D) : const Color(0xFFF0F1F5);
  }

  static Color cardBorder(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? const Color(0xFF242430) : const Color(0xFFE2E5EC);
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppShimmer.defaultBase(context);
    final highlight =
        widget.highlightColor ?? AppShimmer.defaultHighlight(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.0 - 1.0),
      0.0,
      0.0,
    );
  }
}

/// Basic shimmer building blocks
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.color,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppShimmer.bone(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({
    super.key,
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppShimmer.bone(context),
        shape: BoxShape.circle,
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppSpacing.radiusLg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppShimmer.cardFill(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppShimmer.cardBorder(context),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Standard App RefreshIndicator wrapper with theme colors
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
      strokeWidth: 2.5,
      displacement: 36,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Screen-Specific Shimmer Skeletons
// ---------------------------------------------------------------------------

/// Home Tab Skeleton (Efficiency Gauge + Weather Card + Metric Cards + Recent Log)
class HomeTabSkeleton extends StatelessWidget {
  const HomeTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          100,
        ),
        children: [
          // Gauge Skeleton
          Center(
            child: ShimmerCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              borderRadius: AppSpacing.radiusXl,
              child: Column(
                children: const [
                  ShimmerCircle(size: 140),
                  SizedBox(height: 16),
                  ShimmerBox(width: 90, height: 16, borderRadius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 130, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Weather Banner Skeleton
          ShimmerCard(
            borderRadius: AppSpacing.radiusLg,
            child: Row(
              children: const [
                ShimmerCircle(size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 120, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 180, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4-KPI Grid Skeleton
          Row(
            children: const [
              Expanded(
                child: ShimmerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 60, height: 11, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 80, height: 16, borderRadius: 4),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShimmerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 60, height: 11, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 80, height: 16, borderRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: const [
              Expanded(
                child: ShimmerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 60, height: 11, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 80, height: 16, borderRadius: 4),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShimmerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 60, height: 11, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 80, height: 16, borderRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Vehicle Vitals Skeleton
          ShimmerCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 140, height: 13, borderRadius: 4),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(width: 100, height: 28, borderRadius: 4)),
                    SizedBox(width: 16),
                    Expanded(child: ShimmerBox(width: 100, height: 28, borderRadius: 4)),
                  ],
                ),
              ],
            ),
          ),
          // Dual Quick Action Cards Skeleton
          Row(
            children: const [
              Expanded(
                child: ShimmerCard(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      ShimmerBox(width: 28, height: 28, borderRadius: 6),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 60, height: 12, borderRadius: 4),
                            SizedBox(height: 4),
                            ShimmerBox(width: 80, height: 9, borderRadius: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShimmerCard(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      ShimmerBox(width: 28, height: 28, borderRadius: 6),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 60, height: 12, borderRadius: 4),
                            SizedBox(height: 4),
                            ShimmerBox(width: 80, height: 9, borderRadius: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Recent Activity Card Skeleton
          ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 130, height: 14, borderRadius: 4),
                SizedBox(height: 12),
                ShimmerBox(width: double.infinity, height: 44, borderRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Logs Tab Skeleton
class LogsTabSkeleton extends StatelessWidget {
  const LogsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          100,
        ),
        children: [
          // Nav Header Card
          ShimmerCard(
            child: Row(
              children: const [
                ShimmerCircle(size: 38),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 200, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ShimmerBox(width: 110, height: 14, borderRadius: 4),
          ),
          const SizedBox(height: AppSpacing.sm),

          // List Items
          for (var i = 0; i < 4; i++) ...[
            ShimmerCard(
              child: Row(
                children: const [
                  ShimmerBox(width: 44, height: 44, borderRadius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 130, height: 15, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 180, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  ShimmerBox(width: 50, height: 18, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Garage Tab Skeleton
class GarageTabSkeleton extends StatelessWidget {
  const GarageTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Slots count header
          ShimmerCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 120, height: 16, borderRadius: 4),
                ShimmerBox(width: 40, height: 16, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Vehicle Cards
          for (var i = 0; i < 2; i++) ...[
            ShimmerCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      ShimmerCircle(size: 42),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 140, height: 16, borderRadius: 4),
                            SizedBox(height: 6),
                            ShimmerBox(width: 100, height: 12, borderRadius: 4),
                          ],
                        ),
                      ),
                      ShimmerBox(width: 60, height: 24, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const ShimmerBox(width: double.infinity, height: 40, borderRadius: 8),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// Stats Tab Skeleton
class StatsTabSkeleton extends StatelessWidget {
  const StatsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          100,
        ),
        children: [
          // Analytics Carousel Card
          ShimmerCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 16),
                ShimmerBox(width: double.infinity, height: 120, borderRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Tiles
          ShimmerCard(
            child: Row(
              children: const [
                ShimmerCircle(size: 32),
                SizedBox(width: 12),
                ShimmerBox(width: 140, height: 14, borderRadius: 4),
                Spacer(),
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ShimmerCard(
            child: Row(
              children: const [
                ShimmerCircle(size: 32),
                SizedBox(width: 12),
                ShimmerBox(width: 110, height: 14, borderRadius: 4),
                Spacer(),
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cost Breakdown Skeleton
          ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 160, height: 14, borderRadius: 4),
                SizedBox(height: 14),
                ShimmerBox(width: double.infinity, height: 90, borderRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reminders Screen Skeleton
class RemindersSkeleton extends StatelessWidget {
  const RemindersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          for (var i = 0; i < 3; i++) ...[
            ShimmerCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      ShimmerCircle(size: 36),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 130, height: 15, borderRadius: 4),
                            SizedBox(height: 6),
                            ShimmerBox(width: 90, height: 11, borderRadius: 4),
                          ],
                        ),
                      ),
                      ShimmerBox(width: 50, height: 20, borderRadius: 10),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const ShimmerBox(width: double.infinity, height: 6, borderRadius: 3),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// Notifications Screen Skeleton
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          for (var i = 0; i < 4; i++) ...[
            ShimmerCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerCircle(size: 34),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 140, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: double.infinity, height: 11, borderRadius: 4),
                        SizedBox(height: 4),
                        ShimmerBox(width: 180, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Mileage Log Screen Skeleton
class MileageLogSkeleton extends StatelessWidget {
  const MileageLogSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Summary card
          ShimmerCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: const [
                ShimmerBox(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 12),
                ShimmerBox(width: double.infinity, height: 70, borderRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Log items
          for (var i = 0; i < 3; i++) ...[
            ShimmerCard(
              child: Row(
                children: const [
                  ShimmerCircle(size: 38),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 110, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 160, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  ShimmerBox(width: 45, height: 18, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Services & Maintenance Skeleton
class ServicesSkeleton extends StatelessWidget {
  const ServicesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          for (var i = 0; i < 4; i++) ...[
            ShimmerCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: const [
                  ShimmerBox(width: 40, height: 40, borderRadius: 8),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 160, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  ShimmerBox(width: 55, height: 16, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Reports Screen Skeleton
class ReportsSkeleton extends StatelessWidget {
  const ReportsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          ShimmerCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                ShimmerCircle(size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 130, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 3; i++) ...[
            ShimmerCard(
              child: Row(
                children: const [
                  ShimmerBox(width: 36, height: 36, borderRadius: 8),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 140, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 190, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Trip History Skeleton
class TripHistorySkeleton extends StatelessWidget {
  const TripHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          for (var i = 0; i < 3; i++) ...[
            ShimmerCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 120, height: 15, borderRadius: 4),
                      ShimmerBox(width: 60, height: 15, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const ShimmerBox(width: 180, height: 12, borderRadius: 4),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      ShimmerBox(width: 70, height: 12, borderRadius: 4),
                      SizedBox(width: 16),
                      ShimmerBox(width: 70, height: 12, borderRadius: 4),
                      Spacer(),
                      ShimmerBox(width: 50, height: 16, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
