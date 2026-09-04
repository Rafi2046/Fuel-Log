import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../viewmodels/service_log_viewmodel.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Bottom sheet displaying detailed information for a single ServiceLog entry.
class ServiceLogDetailSheet extends ConsumerWidget {
  const ServiceLogDetailSheet({
    super.key,
    required this.log,
    this.vehicleName,
  });

  final ServiceLog log;
  final String? vehicleName;

  static bool _isOpen = false;

  static Future<void> show(
    BuildContext context, {
    required ServiceLog log,
    String? vehicleName,
  }) async {
    if (_isOpen) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (!navigator.mounted) return;

    _isOpen = true;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (sheetContext) => ServiceLogDetailSheet(
          log: log,
          vehicleName: vehicleName,
        ),
      );
    } finally {
      _isOpen = false;
    }
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return Icons.build_rounded;
    if (lower.contains('repair')) return Icons.handyman_rounded;
    if (lower.contains('parking') || lower.contains('toll')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('tax') ||
        lower.contains('legal') ||
        lower.contains('document')) {
      return Icons.description_rounded;
    }
    if (lower.contains('wash') || lower.contains('detailing')) {
      return Icons.clean_hands_rounded;
    }
    if (lower.contains('parts') || lower.contains('accessories')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return const Color(0xFF2ECC71);
    if (lower.contains('repair')) return const Color(0xFFE67E22);
    if (lower.contains('parking') || lower.contains('toll')) {
      return const Color(0xFF3498DB);
    }
    if (lower.contains('tax') || lower.contains('document')) {
      return Color(0xFF9B59B6);
    }
    if (lower.contains('wash')) return Color(0xFF00CEC9);
    if (lower.contains('parts')) return Color(0xFFF39C12);
    return AppColors.primary;
  }

  Future<void> _deleteLog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.appBar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 26,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Delete Service Log?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Are you sure you want to delete "${log.title}"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF2E2E3E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(serviceLogServiceProvider).deleteServiceLog(log.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logDeleted'.tr()),
            backgroundColor: AppColors.control,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final catColor = _getCategoryColor(log.category);
    final catIcon = _getCategoryIcon(log.category);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        bottomInset + AppSpacing.sm,
      ),
      child: CleanGlassPanel(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Header with icon, category badge, and cost
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: catColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(catIcon, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.category.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            log.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (vehicleName != null) ...[
                            SizedBox(height: 2),
                            Text(
                              vehicleName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      AppCurrency.format(log.cost),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2ECC71),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.border.withValues(alpha: 0.5)),
                const SizedBox(height: AppSpacing.sm),

                // Details grid / list
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: AppDateFormats.formatLogDate(log.date),
                ),
                const SizedBox(height: 10),
                if (log.odometer != null) ...[
                  _DetailRow(
                    icon: Icons.speed_rounded,
                    label: 'Odometer at Service',
                    value: '${log.odometer!.toStringAsFixed(0)} km',
                  ),
                  const SizedBox(height: 10),
                ],
                if (log.note != null && log.note!.isNotEmpty) ...[
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Notes / Workshop',
                    value: log.note!,
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: AppSpacing.md),

                // Actions row (Delete button)
                OutlinedButton.icon(
                  onPressed: () => _deleteLog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Delete Record',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.appBar,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF242434)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
