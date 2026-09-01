import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../viewmodels/trip_log_viewmodel.dart';
import '../../../../widgets/app_shimmer.dart';
import 'trip_summary_card.dart';

/// Stream-driven list view displaying trips for the active vehicle with swipe-to-delete.
class TripListView extends ConsumerWidget {
  const TripListView({
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.screenPadding),
    this.physics,
    this.shrinkWrap = false,
  });

  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(vehicleTripsProvider);

    return tripsAsync.when(
      loading: () => const TripHistorySkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'errorPrefix'.tr(namedArgs: {'error': '$e'}),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return AppRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehicleTripsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.2,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181F),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2E2E38),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.route,
                            size: 32,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No trips recorded yet. Start exploring.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AppRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vehicleTripsProvider);
          },
          child: ListView.builder(
            physics: physics ?? const AlwaysScrollableScrollPhysics(),
            shrinkWrap: shrinkWrap,
            padding: padding,
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Dismissible(
                key: ValueKey(trip.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onDismissed: (_) async {
                  await ref.read(tripLogProvider.notifier).deleteTrip(trip.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip deleted'),
                      backgroundColor: Color(0xFF1E1E2C),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: TripSummaryCard(trip: trip),
              ),
            );
          },
        ),
        );
      },
    );
  }
}
