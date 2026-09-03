import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/reminder_viewmodel.dart';

/// Top Overview Card displaying vehicle service health score & alert counts
class ReminderHealthOverview extends StatelessWidget {
  const ReminderHealthOverview({
    super.key,
    required this.state,
    required this.vehicleName,
  });

  final RemindersState state;
  final String vehicleName;

  @override
  Widget build(BuildContext context) {
    final score = state.overallHealthScore;
    final scorePercent = (score * 100).round();
    final hasOverdue = state.overdueCount > 0;
    final hasDueSoon = state.dueSoonCount > 0;

    Color healthColor = const Color(0xFF10B981);
    String healthTitle = 'All Systems Good';
    if (hasOverdue) {
      healthColor = const Color(0xFFEF4444);
      healthTitle = '${state.overdueCount} Service Overdue!';
    } else if (hasDueSoon) {
      healthColor = const Color(0xFFF59E0B);
      healthTitle = '${state.dueSoonCount} Service Due Soon';
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF262632),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Circular Health Score Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: score,
                  strokeWidth: 5.5,
                  backgroundColor: Color(0xFF22222D),
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                ),
              ),
              Text(
                '$scorePercent%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(width: 16),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicleName,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  healthTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: healthColor,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Current Odo: ${state.currentOdometer.toStringAsFixed(0)} km • ${state.activeReminders.length} tracked',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
