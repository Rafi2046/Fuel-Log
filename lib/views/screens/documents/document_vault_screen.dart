import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/document_categories.dart';
import '../../../viewmodels/document_vault_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_card.dart';
import 'widgets/add_edit_document_sheet.dart';
import 'widgets/document_card.dart';
import 'widgets/document_detail_sheet.dart';
import 'widgets/vault_pin_screen.dart';

/// Main Document Vault screen protected with 4-digit PIN lock.
class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const DocumentVaultScreen(),
      ),
    );
  }

  @override
  ConsumerState<DocumentVaultScreen> createState() =>
      _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinAndUnlock();
    });
  }

  Future<void> _checkPinAndUnlock() async {
    final isUnlocked = ref.read(isVaultUnlockedProvider);
    if (isUnlocked) return;

    final isPinSet = await ref.read(isVaultPinSetProvider.future);
    if (!mounted) return;

    if (!isPinSet) {
      // First time PIN setup
      final result = await VaultPinScreen.open(
        context,
        mode: VaultPinMode.setup,
      );
      if (result != true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // Unlock with existing PIN
      final result = await VaultPinScreen.open(
        context,
        mode: VaultPinMode.unlock,
      );
      if (result != true && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showSecurityMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1B27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.keyRound,
                      color: Color(0xFF38BDF8)),
                  title: Text(
                    'documentVaultChangePin'.tr(),
                    style: AppTextStyles.body,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    VaultPinScreen.open(context, mode: VaultPinMode.change);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.lock,
                      color: Color(0xFFEF4444)),
                  title: Text(
                    'documentVaultLockNow'.tr(),
                    style: AppTextStyles.body
                        .copyWith(color: const Color(0xFFEF4444)),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(documentVaultControllerProvider).lockVault();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = ref.watch(isVaultUnlockedProvider);
    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final docs = ref.watch(filteredDocumentsProvider);
    final summary = ref.watch(documentVaultSummaryProvider);
    final tabFilter = ref.watch(selectedDocumentTabFilterProvider);
    final selectedCategory =
        ref.watch(selectedDocumentCategoryFilterProvider);

    if (!isUnlocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F17),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0F0F17),
      appBar: AppBar(
        backgroundColor: Color(0xFF0F0F17),
        elevation: 0,
        title: Text(
          'documentVaultTitle'.tr(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.shieldAlert,
                size: 20, color: Color(0xFFA1A1AA)),
            tooltip: 'Security Settings',
            onPressed: () => _showSecurityMenu(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
        label: Text(
          'addDocument'.tr(),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          if (vehicle != null) {
            AddEditDocumentSheet.show(context, vehicleId: vehicle.id);
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.appBarBodyGap,
          AppSpacing.screenPadding,
          90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Summary Metrics Header Card
            _buildSummaryCard(summary),
            const SizedBox(height: AppSpacing.md),

            // 2. Tab Filter Segment (All / Vehicle / Personal / Expiring)
            _buildTabSegment(tabFilter),
            const SizedBox(height: AppSpacing.sm),

            // 3. Category Filter Chips
            _buildCategoryChips(selectedCategory),
            const SizedBox(height: AppSpacing.md),

            // 4. Documents List
            if (docs.isEmpty)
              _buildEmptyState(context, vehicle?.id)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, index) {
                  final doc = docs[index];
                  return DocumentCard(
                    document: doc,
                    onTap: () => DocumentDetailSheet.show(context, doc),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(DocumentVaultSummary summary) {
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCol(
            title: 'Total Docs',
            value: summary.totalDocs.toString(),
            color: AppColors.textPrimary,
          ),
          Container(width: 1, height: 28, color: AppColors.hairline),
          _buildStatCol(
            title: 'Valid',
            value: summary.validDocs.toString(),
            color: Color(0xFF34D399),
          ),
          Container(width: 1, height: 28, color: AppColors.hairline),
          _buildStatCol(
            title: 'Expiring Soon',
            value: summary.expiringSoonDocs.toString(),
            color: Color(0xFFFBBF24),
          ),
          Container(width: 1, height: 28, color: AppColors.hairline),
          _buildStatCol(
            title: 'Expired',
            value: summary.expiredDocs.toString(),
            color: const Color(0xFFF87171),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSegment(DocumentTabFilter activeTab) {
    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.appBar,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            label: 'documentTabAll'.tr(),
            filter: DocumentTabFilter.all,
            activeTab: activeTab,
          ),
          _buildSegmentItem(
            label: 'documentTabVehicle'.tr(),
            filter: DocumentTabFilter.vehicle,
            activeTab: activeTab,
          ),
          _buildSegmentItem(
            label: 'documentTabPersonal'.tr(),
            filter: DocumentTabFilter.personal,
            activeTab: activeTab,
          ),
          _buildSegmentItem(
            label: 'documentTabExpiring'.tr(),
            filter: DocumentTabFilter.expiring,
            activeTab: activeTab,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required String label,
    required DocumentTabFilter filter,
    required DocumentTabFilter activeTab,
  }) {
    final isSelected = filter == activeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref
            .read(selectedDocumentTabFilterProvider.notifier)
            .state = filter,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.hairline : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(DocumentCategory? selected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text('All Types'),
              selected: selected == null,
              onSelected: (_) => ref
                  .read(selectedDocumentCategoryFilterProvider.notifier)
                  .state = null,
              selectedColor: Color(0xFF2E2E42),
              backgroundColor: AppColors.appBar,
              labelStyle: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: selected == null ? FontWeight.w600 : FontWeight.w500,
                color: selected == null ? Colors.white : Color(0xFF94A3B8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: selected == null
                      ? Color(0xFF3F3F56)
                      : AppColors.hairline,
                ),
              ),
            ),
          ),
          ...DocumentCategory.values.map((cat) {
            final isSelected = cat == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon,
                        size: 13,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF94A3B8)),
                    SizedBox(width: 4),
                    Text(cat.localizedName),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  ref
                      .read(selectedDocumentCategoryFilterProvider.notifier)
                      .state = isSelected ? null : cat;
                },
                selectedColor: Color(0xFF2E2E42),
                backgroundColor: AppColors.appBar,
                labelStyle: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Color(0xFF94A3B8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? Color(0xFF3F3F56)
                        : AppColors.hairline,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, int? vehicleId) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.appBar,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF2A2A3C), width: 1),
            ),
            child: Icon(
              LucideIcons.fileLock2,
              size: 36,
              color: Color(0xFF10B981),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'docEmptyTitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'docEmptySubtitle'.tr(),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (vehicleId != null) {
                AddEditDocumentSheet.show(context, vehicleId: vehicleId);
              }
            },
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
            label: Text('addDocument'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
