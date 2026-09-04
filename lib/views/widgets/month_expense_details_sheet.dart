import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';

/// Monthly cost breakdown dialog — theme-aware for light & dark.
class MonthExpenseDetailsSheet extends StatelessWidget {
  const MonthExpenseDetailsSheet({
    super.key,
    required this.monthLabel,
    required this.fuelLogs,
    required this.serviceLogs,
  });

  final String monthLabel;
  final List<FuelLog> fuelLogs;
  final List<ServiceLog> serviceLogs;

  static Future<void> show(
    BuildContext context, {
    required String monthLabel,
    required List<FuelLog> fuelLogs,
    required List<ServiceLog> serviceLogs,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Month Expense Details',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => MonthExpenseDetailsSheet(
        monthLabel: monthLabel,
        fuelLogs: fuelLogs,
        serviceLogs: serviceLogs,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  double get _totalFuelCost =>
      fuelLogs.fold(0.0, (sum, item) => sum + item.cost);

  double get _totalServiceCost =>
      serviceLogs.fold(0.0, (sum, item) => sum + item.cost);

  double get _grandTotal => _totalFuelCost + _totalServiceCost;

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return Icons.build_rounded;
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

  String _formatOdo(double km) =>
      '${NumberFormat('#,###').format(km.round())} km';

  @override
  Widget build(BuildContext context) {
    // Keep palette in sync when this dialog opens (esp. light mode).
    AppColors.setBrightness(Theme.of(context).brightness);

    final dateFormat = DateFormat('dd MMM yyyy');
    const serviceAccent = Color(0xFF38BDF8);

    final List<_ExpenseItem> combinedItems = [
      ...fuelLogs.map((f) => _ExpenseItem(
            date: f.date,
            title:
                '${'refuelingTitle'.tr()} (${f.amount.toStringAsFixed(1)} L)',
            subtitle: '${dateFormat.format(f.date)} • ${_formatOdo(f.odometer)}',
            cost: f.cost,
            icon: Icons.local_gas_station_rounded,
            iconColor: AppColors.primary,
          )),
      ...serviceLogs.map((s) => _ExpenseItem(
            date: s.date,
            title: s.title,
            subtitle: s.odometer != null
                ? '${dateFormat.format(s.date)} • ${_formatOdo(s.odometer!)}'
                : '${dateFormat.format(s.date)} • ${s.category}',
            cost: s.cost,
            icon: _getCategoryIcon(s.category),
            iconColor: serviceAccent,
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final maxPopupHeight = MediaQuery.of(context).size.height * 0.75;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: maxPopupHeight,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthLabel ${'breakdown'.tr()}',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'monthEntriesRecorded'.tr(
                              namedArgs: {'count': '${combinedItems.length}'},
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.hairline, height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'fuelCosts'.tr(),
                        value: AppCurrency.format(_totalFuelCost),
                        accent: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        label: 'serviceCosts'.tr(),
                        value: AppCurrency.format(_totalServiceCost),
                        accent: serviceAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'totalMonthlySpend'.tr(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            AppCurrency.format(_grandTotal),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: combinedItems.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'noLogsYet'.tr(),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final item in combinedItems)
                              _ExpenseRow(item: item),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'close'.tr(),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.wash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
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

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.item});

  final _ExpenseItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.wash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.control,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppCurrency.format(item.cost),
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: item.iconColor,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseItem {
  const _ExpenseItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.icon,
    required this.iconColor,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final double cost;
  final IconData icon;
  final Color iconColor;
}
