import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../viewmodels/e_document_viewmodel.dart';
import 'add_e_document_sheet.dart';

/// Full vault empty state when no documents have been added yet.
class EDocumentVaultEmptyState extends StatelessWidget {
  const EDocumentVaultEmptyState({
    super.key,
    this.activeVehicleId,
  });

  final int? activeVehicleId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A50).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7A50).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 28,
              color: Color(0xFFFF7A50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Never lose your papers again.',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Add Driving License, Tax Token, Registration, or Fitness.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => AddEDocumentSheet.show(
              context,
              initialVehicleId: activeVehicleId,
            ),
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
            label: const Text('Add First Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A50),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter empty state when active tab/vehicle filters yield no matching documents.
class EDocumentFilterEmptyState extends ConsumerWidget {
  const EDocumentFilterEmptyState({
    super.key,
    required this.activeTab,
    required this.selectedVehicleFilter,
    required this.selectedVehicle,
  });

  final EDocumentFilterTab activeTab;
  final int? selectedVehicleFilter;
  final Vehicle? selectedVehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String message;
    if (selectedVehicleFilter != null) {
      if (selectedVehicleFilter == -1) {
        message = 'No personal documents (License/NID) found.';
      } else {
        final vName = selectedVehicle?.name ?? 'this vehicle';
        message = 'No documents added for $vName yet.';
      }
    } else {
      switch (activeTab) {
        case EDocumentFilterTab.valid:
          message = 'No valid documents found.';
          break;
        case EDocumentFilterTab.expiring:
          message = 'No documents expiring soon (within 30 days).';
          break;
        case EDocumentFilterTab.expired:
          message = 'No expired documents. All your papers are up to date!';
          break;
        case EDocumentFilterTab.all:
          message = 'No documents in vault.';
          break;
      }
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A50).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7A50).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: const Icon(
              LucideIcons.fileSearch,
              size: 26,
              color: Color(0xFFFF7A50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Primary Action: Add document for this specific vehicle or personal
          if (selectedVehicleFilter != null && selectedVehicleFilter != -1) ...[
            ElevatedButton.icon(
              onPressed: () => AddEDocumentSheet.show(
                context,
                initialVehicleId: selectedVehicleFilter,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A50),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(
                'Add Document for ${selectedVehicle?.name ?? 'Vehicle'}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else if (selectedVehicleFilter == -1) ...[
            ElevatedButton.icon(
              onPressed: () =>
                  AddEDocumentSheet.show(context, initialVehicleId: null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A50),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(
                'Add Personal Document',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Secondary Action: Reset Filters
          InkWell(
            onTap: () {
              ref.read(selectedEDocumentTabProvider.notifier).state =
                  EDocumentFilterTab.all;
              ref.read(selectedEDocumentVehicleFilterProvider.notifier).state =
                  null;
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Show All Documents',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF7A50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
