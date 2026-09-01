import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../viewmodels/e_document_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_card.dart';
import 'widgets/add_e_document_sheet.dart';
import 'widgets/e_document_viewer_screen.dart';

/// E-Document Vault Screen for managing mandatory driving & vehicle documents.
class EDocumentVaultScreen extends ConsumerWidget {
  const EDocumentVaultScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const EDocumentVaultScreen(),
      ),
    );
  }

  IconData _getDocumentIcon(String docType) {
    switch (docType) {
      case 'driving_license':
        return LucideIcons.idCard;
      case 'tax_token':
        return LucideIcons.receipt;
      case 'registration':
        return LucideIcons.fileText;
      case 'fitness':
        return LucideIcons.shieldCheck;
      case 'insurance':
        return LucideIcons.shieldAlert;
      case 'route_permit':
        return LucideIcons.mapPin;
      default:
        return LucideIcons.fileText;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EDocument document,
  ) async {
    final type = EDocumentType.fromCode(document.docType);
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
                color: const Color(0xFF161622).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
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
                  // Glowing circular warning icon
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

                  // Title
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

                  // Message
                  Text(
                    'This will permanently remove this document and its local file copy.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),

                  // Actions row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222232),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFA1A1AA),
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
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
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
      final success = await ref
          .read(eDocumentControllerProvider)
          .deleteDocument(document.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.displayName} deleted'),
            backgroundColor: AppColors.cardElevated,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(filteredEDocumentsProvider);
    final allDocsAsync = ref.watch(allEDocumentsStreamProvider);
    final allDocs = allDocsAsync.valueOrNull ?? [];
    final activeTab = ref.watch(selectedEDocumentTabProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];

    final activeVehicle = ref.watch(activeVehicleProvider).valueOrNull;

    // Build vehicle ID to Name lookup map
    final vehicleMap = {for (final v in vehicles) v.id: v.name};

    // Calculate Summary Stats
    final now = DateTime.now();
    var validCount = 0;
    var expiringSoonCount = 0;
    var expiredCount = 0;
    for (final d in allDocs) {
      if (d.expiryDate == null) {
        validCount++;
      } else if (d.expiryDate!.isBefore(now)) {
        expiredCount++;
      } else {
        final days = d.expiryDate!.difference(now).inDays;
        if (days <= 30) {
          expiringSoonCount++;
        } else {
          validCount++;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        leading: const AppBackButton(),
        title: 'E-Document Vault',
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.plus,
              color: Color(0xFFFF7A50),
              size: 22,
            ),
            tooltip: 'Add Document',
            onPressed: () => AddEDocumentSheet.show(
              context,
              initialVehicleId: activeVehicle?.id,
            ),
          ),
        ],
      ),
      // Only show bottom FAB if documents exist to avoid duplication with empty state CTA
      floatingActionButton: docs.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFF7A50),
              icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
              label: Text(
                'Add Document',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: () => AddEDocumentSheet.show(
                context,
                initialVehicleId: activeVehicle?.id,
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive KPI Filter Row
            _buildInteractiveKpiRow(
              ref: ref,
              activeTab: activeTab,
              total: allDocs.length,
              valid: validCount,
              expiring: expiringSoonCount,
              expired: expiredCount,
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Document Content (Empty State or List)
            if (allDocs.isEmpty)
              _buildEmptyState(context, activeVehicle?.id)
            else if (docs.isEmpty)
              _buildFilterEmptyState(ref, activeTab)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, index) {
                  final doc = docs[index];
                  final type = EDocumentType.fromCode(doc.docType);
                  final vehicleName = doc.vehicleId != null
                      ? vehicleMap[doc.vehicleId] ?? 'Vehicle #${doc.vehicleId}'
                      : 'Personal Document';

                  return _buildDocumentCard(
                    context: context,
                    ref: ref,
                    document: doc,
                    type: type,
                    vehicleName: vehicleName,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Interactive KPI card row that serves as the primary filter bar
  Widget _buildInteractiveKpiRow({
    required WidgetRef ref,
    required EDocumentFilterTab activeTab,
    required int total,
    required int valid,
    required int expiring,
    required int expired,
  }) {
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
          Container(width: 1, height: 32, color: const Color(0xFF262638)),
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
          Container(width: 1, height: 32, color: const Color(0xFF262638)),
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
          Container(width: 1, height: 32, color: const Color(0xFF262638)),
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
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(WidgetRef ref, EDocumentFilterTab activeTab) {
    String message;
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              size: 32,
              color: Color(0xFF34D399),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () {
              ref.read(selectedEDocumentTabProvider.notifier).state =
                  EDocumentFilterTab.all;
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A50).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF7A50).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Show All Documents',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
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

  Widget _buildDocumentCard({
    required BuildContext context,
    required WidgetRef ref,
    required EDocument document,
    required EDocumentType type,
    required String vehicleName,
  }) {
    final now = DateTime.now();
    final expiry = document.expiryDate;
    final isExpired = expiry != null && expiry.isBefore(now);
    final daysLeft = expiry?.difference(now).inDays;
    final isExpiringSoon = expiry != null && !isExpired && daysLeft! <= 30;
    final isPdf = document.filePath.toLowerCase().endsWith('.pdf');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B1B28),
            Color(0xFF13131D),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 14,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Title/Vehicle + Delete Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sleek Compact Document Icon Box
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2A2A3E),
                            Color(0xFF1E1E2C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getDocumentIcon(document.docType),
                          size: 16,
                          color: const Color(0xFFF1F5F9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),

                    // Title & Vehicle Association
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                document.vehicleId != null
                                    ? LucideIcons.car
                                    : LucideIcons.user,
                                size: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  vehicleName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete Icon Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmDelete(context, ref, document),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222232),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Hairline Separator
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                const SizedBox(height: 12),

                // Bottom Row: Status Badge & Tap to Inspect Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Pill
                    _buildExpiryBadge(
                      isExpired,
                      isExpiringSoon,
                      daysLeft,
                      expiry,
                    ),

                    // Right "View Document" Indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPdf ? 'PDF' : 'View',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF7A50),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.arrowUpRight,
                          size: 14,
                          color: Color(0xFFFF7A50),
                        ),
                      ],
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

  Widget _buildExpiryBadge(
    bool isExpired,
    bool isExpiringSoon,
    int? daysLeft,
    DateTime? expiry,
  ) {
    Color bg;
    Color fg;
    Color dotColor;
    String label;

    if (expiry == null) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.12);
      fg = const Color(0xFF34D399);
      dotColor = const Color(0xFF10B981);
      label = 'Lifetime Document';
    } else if (isExpired) {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
      fg = const Color(0xFFF87171);
      dotColor = const Color(0xFFEF4444);
      final abs = daysLeft != null ? daysLeft.abs() : 0;
      label = 'Expired ($abs days ago)';
    } else if (isExpiringSoon) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
      fg = const Color(0xFFFBBF24);
      dotColor = const Color(0xFFF59E0B);
      label = 'Expires in $daysLeft days';
    } else {
      bg = const Color(0xFF10B981).withValues(alpha: 0.12);
      fg = const Color(0xFF34D399);
      dotColor = const Color(0xFF10B981);
      final dateStr = DateFormat('dd MMM yyyy').format(expiry);
      label = 'Valid until $dateStr';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dotColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int? activeVehicleId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B24),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFF262638), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A50).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7A50).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 40,
              color: Color(0xFFFF7A50),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Never lose your papers again.',
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Add Driving License, Tax Token, Registration, or Fitness.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
