import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_card.dart';

/// Logs Tab View displaying 10 dummy refueling entries.
class LogsView extends StatelessWidget {
  const LogsView({super.key});

  static final List<Map<String, String>> _dummyLogs = List.generate(
    10,
    (index) => {
      'date': '${21 - index} Aug 2026',
      'liters': '${(30 + index * 1.5).toStringAsFixed(1)} L',
      'odometer': '${45210 - index * 320} km',
      'cost': '\$${(110 + index * 4.5).toStringAsFixed(2)}',
      'type': index % 3 == 0 ? 'Octane' : 'Petrol',
    },
  );

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: _dummyLogs.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final log = _dummyLogs[index];
        return AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            title: Text(
              log['date']!,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${log['liters']} • ${log['odometer']} (${log['type']})',
              style: AppTextStyles.caption,
            ),
            trailing: Text(
              log['cost']!,
              style: AppTextStyles.title.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}
