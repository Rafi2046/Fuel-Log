import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../viewmodels/service_log_viewmodel.dart';
import '../../../widgets/app_shimmer.dart';
import 'service_category_utils.dart';
import 'service_log_detail_sheet.dart';

/// History tab in ServicesScreen.
class ServicesHistoryTab extends ConsumerStatefulWidget {
  const ServicesHistoryTab({
    super.key,
    required this.logs,
    this.vehicleName,
  });

  final List<ServiceLog> logs;
  final String? vehicleName;

  @override
  ConsumerState<ServicesHistoryTab> createState() => _ServicesHistoryTabState();
}

class _ServicesHistoryTabState extends ConsumerState<ServicesHistoryTab> {
  String _selectedCategoryFilter = 'All';

  static const List<String> _categories = [
    'All',
    'Maintenance',
    'Repair',
    'Parking/Toll',
    'Tax/Docs',
    'Washing',
    'Parts',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _selectedCategoryFilter == 'All'
        ? widget.logs
        : widget.logs.where((l) {
            final cat = l.category.toLowerCase();
            final sel = _selectedCategoryFilter.toLowerCase();
            return cat.contains(sel) || sel.contains(cat);
          }).toList();

    final filteredSpend =
        filteredLogs.fold<double>(0.0, (sum, l) => sum + l.cost);

    return Column(
      children: [
        // Category Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 6,
          ),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategoryFilter = cat);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.hairline,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ),

        // Filter Summary Info
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredLogs.length} Records Found',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Total: ${AppCurrency.format(filteredSpend)}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(serviceLogsProvider);
            },
            child: filteredLogs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.18,
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 38,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Service Logs Found',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap + to log your maintenance or repair expense.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      6,
                      AppSpacing.screenPadding,
                      80,
                    ),
                    itemCount: filteredLogs.length,
                    itemBuilder: (ctx, idx) {
                      final log = filteredLogs[idx];
                      final catIcon =
                          ServiceCategoryUtils.getCategoryIcon(log.category);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: ValueKey(log.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onDismissed: (_) async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref
                                .read(serviceLogServiceProvider)
                                .deleteServiceLog(log.id);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('logDeleted'.tr()),
                                backgroundColor: AppColors.control,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: InkWell(
                            onTap: () => ServiceLogDetailSheet.show(
                              context,
                              log: log,
                              vehicleName: widget.vehicleName,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.wash,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Icon(
                                      catIcon,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${AppDateFormats.formatLogDate(log.date)}${log.odometer != null ? ' · ${log.odometer!.toStringAsFixed(0)} km' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        if (log.note != null &&
                                            log.note!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            log.note!,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppCurrency.format(log.cost),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
