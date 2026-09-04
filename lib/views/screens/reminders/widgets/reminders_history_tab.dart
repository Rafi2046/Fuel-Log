import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../viewmodels/service_log_viewmodel.dart';
import '../../../widgets/app_shimmer.dart';

/// Cost & Service History tab in RemindersScreen.
class RemindersHistoryTab extends ConsumerWidget {
  const RemindersHistoryTab({
    super.key,
    required this.logsAsync,
  });

  final AsyncValue<List<ServiceLog>> logsAsync;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (logsAsync.isLoading && !logsAsync.hasValue) {
      return const ServicesSkeleton();
    }
    if (logsAsync.hasError && !logsAsync.hasValue) {
      return Center(
        child: Text(
          'Error: ${logsAsync.error}',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final logs = logsAsync.valueOrNull ?? [];
    if (logs.isEmpty) {
      return AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(serviceLogsProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.25,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF2ECC71),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No Cost & Service Records Yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + at the top or quick actions to record parking fees, tolls, car wash, or service bills.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
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
        ref.invalidate(serviceLogsProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: 8,
        ),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final item = logs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161620),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF242434)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF202030),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: const Color(0xFF2ECC71),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dateFormat.format(item.date)} ${item.odometer != null ? '• ${item.odometer!.toStringAsFixed(0)} km' : ''}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.note!,
                          style: TextStyle(
                            fontSize: 11,
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
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${item.cost.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2ECC71),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textTertiary,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.cardElevated,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.border),
                      ),
                      onSelected: (val) {
                        if (val == 'delete') {
                          ref
                              .read(serviceLogServiceProvider)
                              .deleteServiceLog(item.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 15,
                                color: Color(0xFFEF4444),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
