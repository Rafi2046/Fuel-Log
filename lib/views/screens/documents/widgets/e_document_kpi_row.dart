import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../viewmodels/e_document_viewmodel.dart';
import '../../../widgets/app_card.dart';

/// Interactive KPI card row that serves as the primary filter bar in EDocumentVaultScreen.
class EDocumentKpiRow extends ConsumerWidget {
  const EDocumentKpiRow({
    super.key,
    required this.activeTab,
    required this.total,
    required this.valid,
    required this.expiring,
    required this.expired,
  });

  final EDocumentFilterTab activeTab;
  final int total;
  final int valid;
  final int expiring;
  final int expired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildInteractiveStatItem(
              ref: ref,
              tab: EDocumentFilterTab.all,
              activeTab: activeTab,
              title: 'Total',
              value: total.toString(),
              color: AppColors.textPrimary,
              activeBorderColor: const Color(0xFFFF7A50),
              activeBgColor: const Color(0xFFFF7A50).withValues(alpha: 0.12),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.hairline),
          Expanded(
            child: _buildInteractiveStatItem(
              ref: ref,
              tab: EDocumentFilterTab.valid,
              activeTab: activeTab,
              title: 'Valid',
              value: valid.toString(),
              color: const Color(0xFF34D399),
              activeBorderColor: const Color(0xFF10B981),
              activeBgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.hairline),
          Expanded(
            child: _buildInteractiveStatItem(
              ref: ref,
              tab: EDocumentFilterTab.expiring,
              activeTab: activeTab,
              title: 'Expiring',
              value: expiring.toString(),
              color: const Color(0xFFFBBF24),
              activeBorderColor: const Color(0xFFF59E0B),
              activeBgColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.hairline),
          Expanded(
            child: _buildInteractiveStatItem(
              ref: ref,
              tab: EDocumentFilterTab.expired,
              activeTab: activeTab,
              title: 'Expired',
              value: expired.toString(),
              color: const Color(0xFFF87171),
              activeBorderColor: const Color(0xFFEF4444),
              activeBgColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveStatItem({
    required WidgetRef ref,
    required EDocumentFilterTab tab,
    required EDocumentFilterTab activeTab,
    required String title,
    required String value,
    required Color color,
    required Color activeBorderColor,
    required Color activeBgColor,
  }) {
    final isSelected = activeTab == tab;

    return InkWell(
      onTap: () {
        ref.read(selectedEDocumentTabProvider.notifier).state = tab;
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeBorderColor.withValues(alpha: 0.7)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? color : color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
