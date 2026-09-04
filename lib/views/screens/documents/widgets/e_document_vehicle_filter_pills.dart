import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../viewmodels/e_document_viewmodel.dart';

/// Helper to get appropriate icon based on vehicle category string.
IconData getVehicleTypeIcon(String? type) {
  if (type == null) return LucideIcons.car;
  final lower = type.toLowerCase();
  if (lower.contains('bike') ||
      lower.contains('motorcycle') ||
      lower.contains('scooter')) {
    return LucideIcons.bike;
  }
  if (lower.contains('truck') ||
      lower.contains('lorry') ||
      lower.contains('pickup')) {
    return LucideIcons.truck;
  }
  return LucideIcons.car;
}

/// Multi-vehicle filter pill row allowing the user to filter documents by individual vehicle or personal papers.
class EDocumentVehicleFilterPills extends ConsumerWidget {
  const EDocumentVehicleFilterPills({
    super.key,
    required this.vehicles,
    required this.allDocs,
    required this.selectedVehicleFilter,
  });

  final List<Vehicle> vehicles;
  final List<EDocument> allDocs;
  final int? selectedVehicleFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vehicles.isEmpty && allDocs.isEmpty) return const SizedBox.shrink();

    // Calculate document counts per vehicle
    final Map<int, int> countPerVehicle = {};
    var personalCount = 0;
    for (final doc in allDocs) {
      if (doc.vehicleId != null) {
        countPerVehicle[doc.vehicleId!] =
            (countPerVehicle[doc.vehicleId!] ?? 0) + 1;
      } else {
        personalCount++;
      }
    }

    final pills = <({int? id, String title, IconData icon, int count})>[
      (
        id: null,
        title: 'All Docs',
        icon: LucideIcons.layers,
        count: allDocs.length,
      ),
      ...vehicles.map(
        (v) => (
          id: v.id as int?,
          title: v.name,
          icon: getVehicleTypeIcon(v.type),
          count: countPerVehicle[v.id] ?? 0,
        ),
      ),
      if (personalCount > 0 || vehicles.isNotEmpty)
        (
          id: -1,
          title: 'Personal / DL',
          icon: LucideIcons.user,
          count: personalCount,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: pills.map((item) {
          final isSelected = selectedVehicleFilter == item.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                ref
                    .read(selectedEDocumentVehicleFilterProvider.notifier)
                    .state = item.id;
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.card : AppColors.control,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF7A50)
                        : AppColors.border,
                    width: isSelected ? 1.2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFFF7A50,
                            ).withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 13.5,
                      color: isSelected
                          ? const Color(0xFFFF7A50)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF7A50).withValues(alpha: 0.2)
                            : AppColors.wash,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.count}',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFFFF7A50)
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
