import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../viewmodels/e_document_viewmodel.dart';
import 'e_document_vehicle_filter_pills.dart';
import 'e_document_viewer_screen.dart';

/// Card widget representing a single E-Document with validity indicators and quick actions.
class EDocumentVaultCard extends ConsumerWidget {
  const EDocumentVaultCard({
    super.key,
    required this.document,
    required this.type,
    required this.vehicle,
  });

  final EDocument document;
  final EDocumentType type;
  final Vehicle? vehicle;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EDocument document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              decoration: BoxDecoration(
                color: AppColors.appBar.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.washBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.trash2,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delete ${type.displayName}?',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will permanently remove this document and its local file copy.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.control,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final success = await ref
          .read(eDocumentControllerProvider)
          .deleteDocument(document.id);
      if (success && context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${type.displayName} deleted'),
            backgroundColor: AppColors.cardElevated,
          ),
        );
      }
    }
  }

  Widget _buildValidityInfo({
    required bool isExpired,
    required bool isExpiringSoon,
    required int? daysLeft,
    required DateTime? expiry,
  }) {
    if (expiry == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              size: 10,
              color: Color(0xFF34D399),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Permanent Document',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (isExpired) {
      final abs = daysLeft != null ? daysLeft.abs() : 0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.alertTriangle,
              size: 10,
              color: Color(0xFFF87171),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Expired ($abs days ago)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF87171),
            ),
          ),
        ],
      );
    }

    if (isExpiringSoon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.clock,
              size: 10,
              color: Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Expires in $daysLeft days',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFBBF24),
            ),
          ),
        ],
      );
    }

    final dateStr = DateFormat('dd MMM yyyy').format(expiry);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.calendarCheck,
            size: 10,
            color: Color(0xFF34D399),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Valid till $dateStr',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final expiry = document.expiryDate;
    final isExpired = expiry != null && expiry.isBefore(now);
    final daysLeft = expiry?.difference(now).inDays;
    final isExpiringSoon = expiry != null && !isExpired && daysLeft! <= 30;
    final isPdf = document.filePath.toLowerCase().endsWith('.pdf');
    final vehicleName =
        vehicle?.name ??
        (document.vehicleId != null
            ? 'Vehicle #${document.vehicleId}'
            : 'Personal Document');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.28 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => EDocumentViewerScreen.open(
            context,
            document: document,
            vehicleName: vehicleName,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                document.vehicleId != null
                                    ? getVehicleTypeIcon(vehicle?.type)
                                    : LucideIcons.user,
                                size: 12.5,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5.5),
                              Flexible(
                                child: Text(
                                  document.vehicleId != null
                                      ? (vehicle?.name ?? vehicleName)
                                      : 'Personal / Driver Paper',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (vehicle?.brand != null &&
                                  vehicle!.brand!.isNotEmpty) ...[
                                Text(
                                  ' · ${vehicle!.brand}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmDelete(context, ref, document),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.wash,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.trash2,
                            size: 15,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildValidityInfo(
                      isExpired: isExpired,
                      isExpiringSoon: isExpiringSoon,
                      daysLeft: daysLeft,
                      expiry: expiry,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A50).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(
                            0xFFFF7A50,
                          ).withValues(alpha: 0.28),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPdf ? LucideIcons.fileText : LucideIcons.eye,
                            size: 13,
                            color: const Color(0xFFFF7A50),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPdf ? 'Open PDF' : 'View Doc',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF7A50),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            LucideIcons.arrowUpRight,
                            size: 12,
                            color: Color(0xFFFF7A50),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
