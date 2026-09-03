import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/document_categories.dart';
import '../../../../core/database/app_database.dart';
import '../../../widgets/app_card.dart';

/// Card item representing a single vehicle document or personal license.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
  });

  final VehicleDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = DocumentCategoryX.fromCode(document.category);
    final status = DocumentExpiryHelper.calculateStatus(document.expiryDate);
    final daysLeft = DocumentExpiryHelper.daysRemaining(document.expiryDate);

    final hasFront = document.frontImagePath != null &&
        document.frontImagePath!.isNotEmpty;
    final hasBack = document.backImagePath != null &&
        document.backImagePath!.isNotEmpty;
    final photoCount = (hasFront ? 1 : 0) + (hasBack ? 1 : 0);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: const Color(0xFF2E2E42),
                width: 1,
              ),
            ),
            child: Icon(
              category.icon,
              size: 20,
              color: const Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(width: 12),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (photoCount > 0) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.hairline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.image,
                              size: 10,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              photoCount.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                // Number / Subtitle
                if (document.documentNumber != null &&
                    document.documentNumber!.isNotEmpty) ...[
                  Text(
                    document.documentNumber!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                ],

                // Expiry Badge
                _buildStatusBadge(status, daysLeft),
              ],
            ),
          ),
          const SizedBox(width: 8),

          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Color(0xFF71717A),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DocumentExpiryStatus status, int? daysLeft) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case DocumentExpiryStatus.valid:
        bg = const Color(0xFF10B981).withValues(alpha: 0.12);
        fg = const Color(0xFF34D399);
        label = daysLeft != null
            ? '${'docStatusValid'.tr()} • ${'docDaysLeft'.tr(namedArgs: {'days': daysLeft.toString()})}'
            : 'docStatusValid'.tr();
        break;
      case DocumentExpiryStatus.expiringSoon:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFFBBF24);
        label = daysLeft != null
            ? 'docDaysLeft'.tr(namedArgs: {'days': daysLeft.toString()})
            : 'docStatusExpiringSoon'.tr();
        break;
      case DocumentExpiryStatus.expired:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFF87171);
        final absDays = daysLeft != null ? daysLeft.abs() : 0;
        label = 'docExpiredDaysAgo'
            .tr(namedArgs: {'days': absDays.toString()});
        break;
      case DocumentExpiryStatus.noExpiry:
        bg = const Color(0xFF27273A);
        fg = const Color(0xFF94A3B8);
        label = 'docStatusLifetime'.tr();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
