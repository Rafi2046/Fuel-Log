import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/mileage_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_shimmer.dart';
import '../refueling_form_screen.dart';
import 'widgets/mileage_empty_state.dart';
import 'widgets/mileage_log_tile.dart';
import 'widgets/mileage_summary_card.dart';

/// Dedicated Mileage Log screen showing computed vehicle fuel efficiency history & summary.
class MileageLogScreen extends ConsumerWidget {
  const MileageLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final processedEntries = ref.watch(processedMileageEntriesProvider);
    final activeVehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final isEV = activeVehicle?.isElectric ?? false;
    final unit = isEV ? 'kWh' : 'L';

    return AppScaffold(
      leading: const AppBackButton(),
      title: 'Mileage Log',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
          tooltip: 'Add Refueling',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RefuelingFormScreen(),
              ),
            );
          },
        ),
      ],
      body: Builder(
        builder: (context) {
          if (logsAsync.isLoading && !logsAsync.hasValue) {
            return const MileageLogSkeleton();
          }
          if (logsAsync.hasError && !logsAsync.hasValue) {
            return Center(
              child: Text('Error loading mileage logs: ${logsAsync.error}'),
            );
          }

          final logs = logsAsync.valueOrNull ?? [];
          if (logs.isEmpty || processedEntries.isEmpty) {
            return AppRefreshIndicator(
              onRefresh: () async {
                ref.invalidate(vehicleLogsProvider);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.25,
                  ),
                  const MileageEmptyState(),
                ],
              ),
            );
          }

          return AppRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehicleLogsProvider);
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.appBarBodyGap,
                      AppSpacing.screenPadding,
                      AppSpacing.listGap,
                    ),
                    child: MileageSummaryCard(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.listGap,
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = processedEntries[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.listGap),
                          child: MileageLogTile(
                            entry: entry,
                            unit: unit,
                            isEV: isEV,
                          ),
                        );
                      },
                      childCount: processedEntries.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
