import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/vault_security_service.dart';
import '../../../viewmodels/e_document_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import 'widgets/add_e_document_sheet.dart';
import 'widgets/e_document_kpi_row.dart';
import 'widgets/e_document_vault_card.dart';
import 'widgets/e_document_vault_empty_states.dart';
import 'widgets/e_document_vehicle_filter_pills.dart';
import 'widgets/vault_pin_screen.dart';
import 'widgets/vault_security_menu_button.dart';

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
          MaterialPageRoute(builder: (_) => const EDocumentVaultScreen()),
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
          MaterialPageRoute(builder: (_) => const EDocumentVaultScreen()),
        );
      }
      return;
    }

    // 3. If device biometrics was canceled or not available and no PIN is set, open directly
    if (context.mounted) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const EDocumentVaultScreen()),
      );
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
    final selectedVehicleFilter = ref.watch(
      selectedEDocumentVehicleFilterProvider,
    );

    // Build vehicle ID to Vehicle object lookup map
    final vehicleObjectMap = {for (final v in vehicles) v.id: v};
    final selectedVehicle =
        selectedVehicleFilter != null && selectedVehicleFilter != -1
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
          const VaultSecurityMenuButton(),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.appBarBodyGap,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive KPI Status Filter Row
            EDocumentKpiRow(
              activeTab: activeTab,
              total: vehicleDocs.length,
              valid: validCount,
              expiring: expiringSoonCount,
              expired: expiredCount,
            ),
            const SizedBox(height: 12),

            // 2. Multi-Vehicle Horizontal Filter Selector
            EDocumentVehicleFilterPills(
              vehicles: vehicles,
              allDocs: allDocs,
              selectedVehicleFilter: selectedVehicleFilter,
            ),
            const SizedBox(height: 14),

            // 3. Document Content (Empty State or List)
            if (allDocs.isEmpty)
              Expanded(
                child: Center(
                  child: EDocumentVaultEmptyState(
                    activeVehicleId: activeVehicle?.id,
                  ),
                ),
              )
            else if (docs.isEmpty)
              Expanded(
                child: Center(
                  child: EDocumentFilterEmptyState(
                    activeTab: activeTab,
                    selectedVehicleFilter: selectedVehicleFilter,
                    selectedVehicle: selectedVehicle,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, index) {
                    final doc = docs[index];
                    final type = EDocumentType.fromCode(doc.docType);
                    final vehicle = doc.vehicleId != null
                        ? vehicleObjectMap[doc.vehicleId]
                        : null;

                    return EDocumentVaultCard(
                      document: doc,
                      type: type,
                      vehicle: vehicle,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
