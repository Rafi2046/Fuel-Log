import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/clean_glass_panel.dart';
import 'dashboard_nav_item.dart';

/// Floating glass bottom bar — matches [HomeDashboardAppBar] styling.
///
/// Tap and horizontal swipe are handled by a top interaction layer so Android
/// child gestures cannot block tab switching.
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
  static const _swipeDistanceThreshold = 22.0;
  static const _tapSlop = 14.0;

  final _interactionKey = GlobalKey();
  double _dragDx = 0;
  double _dragDy = 0;
  double? _downLocalX;

  void _resetDrag() {
    _dragDx = 0;
    _dragDy = 0;
    _downLocalX = null;
  }

  int? _tabIndexForLocalX(double localX, double width) {
    if (widget.showFabGap) {
      final fabStart = (width - DashboardBottomBar.fabGap) / 2;
      final fabEnd = fabStart + DashboardBottomBar.fabGap;
      if (localX >= fabStart && localX <= fabEnd) return null;

      final halfWidth = width / 2;
      if (localX < halfWidth) {
        return localX < halfWidth / 2 ? 0 : 1;
      }
      final rightLocal = localX - halfWidth;
      return rightLocal < halfWidth / 2 ? 2 : 3;
    }

    final quarter = width / _tabCount;
    return (localX / quarter).floor().clamp(0, _tabCount - 1);
  }

  void _onPointerDown(PointerDownEvent event) {
    _resetDrag();
    _downLocalX = event.localPosition.dx;
  }

  void _onPointerMove(PointerMoveEvent event) {
    _dragDx += event.delta.dx;
    _dragDy += event.delta.dy;
  }

  void _onPointerUp(PointerUpEvent event) {
    final isSwipe = _dragDx.abs() >= _swipeDistanceThreshold &&
        _dragDx.abs() > _dragDy.abs();

    if (isSwipe) {
      if (_dragDx < 0) {
        final next = (widget.currentIndex + 1).clamp(0, _tabCount - 1);
        if (next != widget.currentIndex) {
          HapticFeedback.selectionClick();
          widget.onTabTapped(next);
        }
      } else {
        final prev = (widget.currentIndex - 1).clamp(0, _tabCount - 1);
        if (prev != widget.currentIndex) {
          HapticFeedback.selectionClick();
          widget.onTabTapped(prev);
        }
      }
      _resetDrag();
      return;
    }

    final isTap = _dragDx.abs() <= _tapSlop && _dragDy.abs() <= _tapSlop;
    final downX = _downLocalX;
    final box = _interactionKey.currentContext?.findRenderObject() as RenderBox?;

    if (isTap && downX != null && box != null) {
      final tab = _tabIndexForLocalX(downX, box.size.width);
      if (tab != null && tab != widget.currentIndex) {
        HapticFeedback.selectionClick();
        widget.onTabTapped(tab);
      }
    }

    _resetDrag();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            0,
            14,
            DashboardBottomBar.outerBottomPad,
          ),
          child: FrostedGlassPanel(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: SizedBox(
              height: DashboardBottomBar.barHeight,
              child: Stack(
                children: [
                  IgnorePointer(
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
                              ),
                              DashboardNavItem(
                                icon: Icons.route_rounded,
                                label: 'navTrip'.tr(),
                                isSelected: widget.currentIndex == 1,
                              ),
                            ],
                          ),
                        ),
                        if (widget.showFabGap)
                          const SizedBox(width: DashboardBottomBar.fabGap),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              DashboardNavItem(
                                icon: Icons.bar_chart_rounded,
                                label: 'navStats'.tr(),
                                isSelected: widget.currentIndex == 2,
                              ),
                              DashboardNavItem(
                                icon: Icons.settings_rounded,
                                label: 'navSettings'.tr(),
                                isSelected: widget.currentIndex == 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    key: _interactionKey,
                    child: Listener(
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerUp,
                      onPointerCancel: (_) => _resetDrag(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
