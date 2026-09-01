import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/vault_security_service.dart';
import '../../../viewmodels/e_document_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_card.dart';
import 'widgets/add_e_document_sheet.dart';
import 'widgets/e_document_viewer_screen.dart';
import 'widgets/vault_pin_screen.dart';

/// E-Document Vault Screen for managing mandatory driving & vehicle documents.
class EDocumentVaultScreen extends ConsumerWidget {
  const EDocumentVaultScreen({super.key});

  /// Opens the E-Document Vault with mandatory Biometric (Face / Fingerprint) & PIN security authentication.
  static Future<void> open(BuildContext context) async {
    const security = VaultSecurityService();
    final canBiometrics = await security.canAuthenticateWithBiometrics();
    final isBiometricsEnabled = await security.isBiometricsEnabled();
    final isPinSet = await security.isPinSet();

    // 1. Try Biometrics (Fingerprint / Face ID / Face Unlock) first
    if (canBiometrics && isBiometricsEnabled) {
      final authenticated = await security.authenticateWithBiometrics(
        reason: 'Scan fingerprint or Face to unlock E-Document Vault',
      );
      if (authenticated && context.mounted) {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => const EDocumentVaultScreen(),
          ),
        );
        return;
      }
    }

    // 2. If PIN is configured, show PIN screen (with biometric retry option)
    if (isPinSet && context.mounted) {
      final unlocked = await VaultPinScreen.open(
        context,
        mode: VaultPinMode.unlock,
      );
      if (unlocked == true && context.mounted) {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => const EDocumentVaultScreen(),
          ),
        );
      }
      return;
    }

    // 3. If device biometrics was canceled or not available and no PIN is set, open directly
    if (context.mounted) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const EDocumentVaultScreen(),
        ),
      );
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

    final selectedVehicleFilter =
        ref.watch(selectedEDocumentVehicleFilterProvider);

    // Build vehicle ID to Vehicle object lookup map
    final vehicleObjectMap = {for (final v in vehicles) v.id: v};
    final selectedVehicle = selectedVehicleFilter != null && selectedVehicleFilter != -1
        ? vehicleObjectMap[selectedVehicleFilter]
        : null;

    // Filter documents by selected vehicle to calculate dynamic KPI status counts
    final vehicleDocs = allDocs.where((doc) {
      if (selectedVehicleFilter != null) {
        if (selectedVehicleFilter == -1) {
          return doc.vehicleId == null;
        } else {
          return doc.vehicleId == selectedVehicleFilter;
        }
      }
      return true;
    }).toList();

    // Calculate Summary Stats based on the currently filtered vehicle scope
    final now = DateTime.now();
    var validCount = 0;
    var expiringSoonCount = 0;
    var expiredCount = 0;
    for (final d in vehicleDocs) {
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
          PopupMenuButton<String>(
            icon: const Icon(
              LucideIcons.shieldCheck,
              color: Color(0xFF10B981),
              size: 20,
            ),
            tooltip: 'Vault Security',
            color: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF2E2E42)),
            ),
            onSelected: (val) async {
              const security = VaultSecurityService();
              final isPinSet = await security.isPinSet();
              if (!context.mounted) return;

              if (val == 'pin') {
                await VaultPinScreen.open(
                  context,
                  mode: isPinSet ? VaultPinMode.change : VaultPinMode.setup,
                );
              } else if (val == 'lock') {
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    const Icon(LucideIcons.keyRound, size: 16, color: Color(0xFFFF7A50)),
                    const SizedBox(width: 10),
                    Text(
                      'Security PIN Settings',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lock',
                child: Row(
                  children: [
                    const Icon(LucideIcons.lock, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 10),
                    Text(
                      'Lock Vault Now',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            // 1. Interactive KPI Status Filter Row
            _buildInteractiveKpiRow(
              ref: ref,
              activeTab: activeTab,
              total: vehicleDocs.length,
              valid: validCount,
              expiring: expiringSoonCount,
              expired: expiredCount,
            ),
            const SizedBox(height: 12),

            // 2. Multi-Vehicle Horizontal Filter Selector
            _buildVehicleFilterPills(
              ref: ref,
              vehicles: vehicles,
              allDocs: allDocs,
              selectedVehicleFilter: selectedVehicleFilter,
            ),
            const SizedBox(height: 14),

            // 3. Document Content (Empty State or List)
            if (allDocs.isEmpty)
              _buildEmptyState(context, activeVehicle?.id)
            else if (docs.isEmpty)
              _buildFilterEmptyState(
                context: context,
                ref: ref,
                activeTab: activeTab,
                selectedVehicleFilter: selectedVehicleFilter,
                selectedVehicle: selectedVehicle,
              )
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
                  final vehicle = doc.vehicleId != null
                      ? vehicleObjectMap[doc.vehicleId]
                      : null;

                  return _buildDocumentCard(
                    context: context,
                    ref: ref,
                    document: doc,
                    type: type,
                    vehicle: vehicle,
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

  IconData _getVehicleTypeIcon(String? type) {
    if (type == null) return LucideIcons.car;
    final lower = type.toLowerCase();
    if (lower.contains('bike') || lower.contains('motorcycle') || lower.contains('scooter')) {
      return LucideIcons.bike;
    }
    if (lower.contains('truck') || lower.contains('lorry') || lower.contains('pickup')) {
      return LucideIcons.truck;
    }
    return LucideIcons.car;
  }

  /// Multi-vehicle filter pill row allowing the user to filter documents by individual vehicle or personal papers
  Widget _buildVehicleFilterPills({
    required WidgetRef ref,
    required List<Vehicle> vehicles,
    required List<EDocument> allDocs,
    required int? selectedVehicleFilter,
  }) {
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
      (id: null, title: 'All Docs', icon: LucideIcons.layers, count: allDocs.length),
      ...vehicles.map((v) => (
            id: v.id as int?,
            title: v.name,
            icon: _getVehicleTypeIcon(v.type),
            count: countPerVehicle[v.id] ?? 0,
          )),
      if (personalCount > 0 || vehicles.isNotEmpty)
        (id: -1, title: 'Personal / DL', icon: LucideIcons.user, count: personalCount),
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
                ref.read(selectedEDocumentVehicleFilterProvider.notifier).state =
                    item.id;
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF222234)
                      : const Color(0xFF14141E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF7A50)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7A50).withValues(alpha: 0.25),
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
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF94A3B8),
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
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.count}',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFFFF7A50)
                              : const Color(0xFF71717A),
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

  Widget _buildFilterEmptyState({
    required BuildContext context,
    required WidgetRef ref,
    required EDocumentFilterTab activeTab,
    required int? selectedVehicleFilter,
    required Vehicle? selectedVehicle,
  }) {
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
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B24),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFF262638), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A50).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7A50).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              LucideIcons.fileSearch,
              size: 32,
              color: Color(0xFFFF7A50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
              onPressed: () => AddEDocumentSheet.show(
                context,
                initialVehicleId: null,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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

  Widget _buildDocumentCard({
    required BuildContext context,
    required WidgetRef ref,
    required EDocument document,
    required EDocumentType type,
    required Vehicle? vehicle,
  }) {
    final now = DateTime.now();
    final expiry = document.expiryDate;
    final isExpired = expiry != null && expiry.isBefore(now);
    final daysLeft = expiry?.difference(now).inDays;
    final isExpiringSoon = expiry != null && !isExpired && daysLeft! <= 30;
    final isPdf = document.filePath.toLowerCase().endsWith('.pdf');
    final vehicleName = vehicle?.name ??
        (document.vehicleId != null
            ? 'Vehicle #${document.vehicleId}'
            : 'Personal Document');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
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
                // Top Header Row: Document Name & Vehicle Tag (Left) + Trash (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Document Title & Vehicle Association
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                document.vehicleId != null
                                    ? _getVehicleTypeIcon(vehicle?.type)
                                    : LucideIcons.user,
                                size: 12.5,
                                color: const Color(0xFF94A3B8),
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
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (vehicle?.brand != null && vehicle!.brand!.isNotEmpty) ...[
                                Text(
                                  ' · ${vehicle.brand}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _confirmDelete(context, ref, document),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            size: 15,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Subtle hairline
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),

                const SizedBox(height: 10),

                // Bottom Metadata & Action Row: Validity + "Open PDF / View" Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Validity Status
                    _buildValidityInfo(
                      isExpired: isExpired,
                      isExpiringSoon: isExpiringSoon,
                      daysLeft: daysLeft,
                      expiry: expiry,
                    ),

                    // Open / View Pill Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A50).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF7A50).withValues(alpha: 0.28),
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

  Widget _buildValidityInfo({
    required bool isExpired,
    required bool isExpiringSoon,
    required int? daysLeft,
    required DateTime? expiry,
  }) {
    if (expiry == null) {
      // Clean, elegant Permanent/No Expiry indicator without bulky box
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
              color: const Color(0xFF94A3B8),
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

    // Valid with expiry date
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
            color: const Color(0xFFCBD5E1),
          ),
        ),
      ],
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
