import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/clean_glass_panel.dart';
import 'dashboard_bar_metrics.dart';
import 'dashboard_nav_item.dart';

/// Floating glass bottom bar — matches [HomeDashboardAppBar] styling.
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

  static const horizontalInset = DashboardBarMetrics.horizontalInset;
  static const topFloatPad = 4.0;
  static const barHeight = DashboardBarMetrics.barHeight;
  static const innerContentHeight = DashboardBarMetrics.innerContentHeight;
  static const homeIndicatorGap = 4.0;
  static const fabGap = 44.0;

  /// Extra space so last list cards clear the docked center FAB.
  static const fabClearance = 32.0;

  /// Exact height of the bottom shell (nav pill + safe area).
  ///
  /// Uses [MediaQuery.viewPadding] only — [MediaQuery.padding.bottom] inside a
  /// Scaffold body already includes this bar and would double-count.
  static double shellHeight(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bottomInset =
        safeBottom > homeIndicatorGap ? safeBottom : homeIndicatorGap;
    return topFloatPad + barHeight + bottomInset;
  }

  /// Scroll/list padding above the shell + docked FAB.
  static double contentBottomInset(BuildContext context) {
    return shellHeight(context) + fabClearance;
  }

  /// Overlay dock (Trip map controls) — clear of the floating nav pill.
  static double overlayBottom(BuildContext context, {double gap = 16}) {
    return shellHeight(context) + gap;
  }

  @override
  State<DashboardBottomBar> createState() => _DashboardBottomBarState();
}

class _DashboardBottomBarState extends State<DashboardBottomBar> {
  static const _tabCount = 4;
  static const _swipeDistanceThreshold = 18.0;
  static const _swipeVelocityThreshold = 180.0;

  final _interactionKey = GlobalKey();
  double _dragDx = 0;

  void _resetDrag() => _dragDx = 0;

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

  void _commitSwipe(double dx, double velocity) {
    final swipeLeft = dx < -_swipeDistanceThreshold ||
        velocity < -_swipeVelocityThreshold;
    final swipeRight = dx > _swipeDistanceThreshold ||
        velocity > _swipeVelocityThreshold;

    if (swipeLeft) {
      final next = (widget.currentIndex + 1).clamp(0, _tabCount - 1);
      if (next != widget.currentIndex) {
        HapticFeedback.selectionClick();
        widget.onTabTapped(next);
      }
      return;
    }

    if (swipeRight) {
      final prev = (widget.currentIndex - 1).clamp(0, _tabCount - 1);
      if (prev != widget.currentIndex) {
        HapticFeedback.selectionClick();
        widget.onTabTapped(prev);
      }
    }
  }

  void _handleTap(Offset localPosition) {
    final box = _interactionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final tab = _tabIndexForLocalX(localPosition.dx, box.size.width);
    if (tab != null && tab != widget.currentIndex) {
      HapticFeedback.selectionClick();
      widget.onTabTapped(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DashboardBottomBar.horizontalInset,
        DashboardBottomBar.topFloatPad,
        DashboardBottomBar.horizontalInset,
        0,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(
          bottom: DashboardBottomBar.homeIndicatorGap,
        ),
        child: FrostedGlassPanel(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
          child: SizedBox(
            height: DashboardBottomBar.barHeight - 4,
            child: Stack(
              children: [
                IgnorePointer(
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: DashboardNavItem(
                                icon: Icons.home_rounded,
                                label: 'navHome'.tr(),
                                isSelected: widget.currentIndex == 0,
                              ),
                            ),
                            Expanded(
                              child: DashboardNavItem(
                                icon: Icons.route_rounded,
                                label: 'navTrip'.tr(),
                                isSelected: widget.currentIndex == 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showFabGap)
                        const SizedBox(width: DashboardBottomBar.fabGap),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: DashboardNavItem(
                                icon: Icons.bar_chart_rounded,
                                label: 'navStats'.tr(),
                                isSelected: widget.currentIndex == 2,
                              ),
                            ),
                            Expanded(
                              child: DashboardNavItem(
                                icon: Icons.settings_rounded,
                                label: 'navSettings'.tr(),
                                isSelected: widget.currentIndex == 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  key: _interactionKey,
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: <Type, GestureRecognizerFactory>{
                      HorizontalDragGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer(),
                        (HorizontalDragGestureRecognizer instance) {
                          instance.onStart = (_) => _resetDrag();
                          instance.onUpdate = (details) {
                            _dragDx += details.delta.dx;
                          };
                          instance.onEnd = (details) {
                            _commitSwipe(
                              _dragDx,
                              details.velocity.pixelsPerSecond.dx,
                            );
                            _resetDrag();
                          };
                          instance.onCancel = _resetDrag;
                        },
                      ),
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer instance) {
                          instance.onTapUp = (details) {
                            _handleTap(details.localPosition);
                          };
                        },
                      ),
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
