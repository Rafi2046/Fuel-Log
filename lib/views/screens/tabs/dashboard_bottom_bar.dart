import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/clean_glass_panel.dart';
import 'dashboard_nav_item.dart';

/// Floating glass bottom bar — matches [HomeDashboardAppBar] styling.
///
/// On iOS uses real backdrop blur ([FrostedGlassPanel]). Swipe left/right on
/// the bar to move between tabs (Home → Trip → Stats → Settings).
class DashboardBottomBar extends StatefulWidget {
  const DashboardBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
    this.showFabGap = true,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTapped;
  final bool showFabGap;

  static const barHeight = 52.0;
  static const outerBottomPad = 8.0;
  static const fabGap = 56.0;

  /// Extra scroll padding so content clears the floating bar + safe area.
  static double contentBottomInset(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return barHeight + outerBottomPad + safeBottom + 12;
  }

  @override
  State<DashboardBottomBar> createState() => _DashboardBottomBarState();
}

class _DashboardBottomBarState extends State<DashboardBottomBar> {
  static const _tabCount = 4;
  static const _swipeDistanceThreshold = 36.0;
  static const _swipeVelocityThreshold = 120.0;

  double _dragDx = 0;

  void _onHorizontalDragStart(DragStartDetails _) => _dragDx = 0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    final swipeLeft = _dragDx < -_swipeDistanceThreshold ||
        velocity < -_swipeVelocityThreshold;
    final swipeRight = _dragDx > _swipeDistanceThreshold ||
        velocity > _swipeVelocityThreshold;

    if (swipeLeft) {
      final next = (widget.currentIndex + 1).clamp(0, _tabCount - 1);
      if (next != widget.currentIndex) widget.onTabTapped(next);
      return;
    }

    if (swipeRight) {
      final prev = (widget.currentIndex - 1).clamp(0, _tabCount - 1);
      if (prev != widget.currentIndex) widget.onTabTapped(prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, DashboardBottomBar.outerBottomPad),
          child: GestureDetector(
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: FrostedGlassPanel(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: SizedBox(
                height: DashboardBottomBar.barHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          DashboardNavItem(
                            icon: Icons.home_rounded,
                            label: 'navHome'.tr(),
                            isSelected: widget.currentIndex == 0,
                            onTap: () => widget.onTabTapped(0),
                          ),
                          DashboardNavItem(
                            icon: Icons.route_rounded,
                            label: 'navTrip'.tr(),
                            isSelected: widget.currentIndex == 1,
                            onTap: () => widget.onTabTapped(1),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showFabGap) const SizedBox(width: DashboardBottomBar.fabGap),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          DashboardNavItem(
                            icon: Icons.bar_chart_rounded,
                            label: 'navStats'.tr(),
                            isSelected: widget.currentIndex == 2,
                            onTap: () => widget.onTabTapped(2),
                          ),
                          DashboardNavItem(
                            icon: Icons.settings_rounded,
                            label: 'navSettings'.tr(),
                            isSelected: widget.currentIndex == 3,
                            onTap: () => widget.onTabTapped(3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
