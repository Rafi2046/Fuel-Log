import 'dart:io';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/document_categories.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../viewmodels/document_vault_viewmodel.dart';
import 'add_edit_document_sheet.dart';
import 'document_image_viewer.dart';

/// Full detail modal sheet for viewing, sharing, editing and managing a document.
class DocumentDetailSheet extends ConsumerWidget {
  const DocumentDetailSheet({
    super.key,
    required this.document,
  });

  final VehicleDocument document;

  static Future<void> show(BuildContext context, VehicleDocument document) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DocumentDetailSheet(document: document),
    );
  }

  void _shareDocument(BuildContext context) {
    final files = <XFile>[];
    if (document.frontImagePath != null &&
        File(document.frontImagePath!).existsSync()) {
      files.add(XFile(document.frontImagePath!));
    }
    if (document.backImagePath != null &&
        File(document.backImagePath!).existsSync()) {
      files.add(XFile(document.backImagePath!));
    }

    final shareText = '${document.title}'
        '${document.documentNumber != null ? ' (${document.documentNumber})' : ''}'
        '${document.expiryDate != null ? ' - Expiry: ${DateFormat('dd MMM yyyy').format(document.expiryDate!)}' : ''}';

    if (files.isNotEmpty) {
      Share.shareXFiles(
        files,
        text: shareText,
        subject: document.title,
      );
    } else {
      Share.share(
        shareText,
        subject: document.title,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
                    'deleteDocument'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'deleteDocConfirm'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF94A3B8),
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
                              color: const Color(0xFF222232),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'cancel'.tr(),
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
                              'delete'.tr(),
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
      await ref
          .read(documentVaultControllerProvider)
          .deleteDocument(document.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = DocumentCategoryX.fromCode(document.category);
    final status = DocumentExpiryHelper.calculateStatus(document.expiryDate);
    final daysLeft = DocumentExpiryHelper.daysRemaining(document.expiryDate);

    final hasFront = document.frontImagePath != null &&
        File(document.frontImagePath!).existsSync();
    final hasBack = document.backImagePath != null &&
        File(document.backImagePath!).existsSync();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333348),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      size: 24,
                      color: const Color(0xFFA1A1AA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (document.documentNumber != null &&
                            document.documentNumber!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            document.documentNumber!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x,
                        size: 20, color: Color(0xFFA1A1AA)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Status Banner
              _buildStatusBanner(status, daysLeft),
              const SizedBox(height: 20),

              // 4. Photo Attachments
              if (hasFront || hasBack) ...[
                Text(
                  'DOCUMENT PHOTOS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF71717A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (hasFront)
                      Expanded(
                        child: _buildPhotoPreview(
                          context: context,
                          label: 'docFrontPhoto'.tr(),
                          imagePath: document.frontImagePath!,
                        ),
                      ),
                    if (hasFront && hasBack) const SizedBox(width: 12),
                    if (hasBack)
                      Expanded(
                        child: _buildPhotoPreview(
                          context: context,
                          label: 'docBackPhoto'.tr(),
                          imagePath: document.backImagePath!,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // 5. Metadata Group
              Text(
                'DETAILS & VALIDITY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF71717A),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B27),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: const Color(0xFF262638), width: 1),
                ),
                child: Column(
                  children: [
                    _buildMetaRow(
                      label: 'docCategoryField'.tr(),
                      value: category.localizedName,
                    ),
                    if (document.issueDate != null) ...[
                      const Divider(height: 16, color: Color(0xFF262638)),
                      _buildMetaRow(
                        label: 'docIssueDateField'.tr(),
                        value: DateFormat('dd MMMM yyyy')
                            .format(document.issueDate!),
                      ),
                    ],
                    const Divider(height: 16, color: Color(0xFF262638)),
                    _buildMetaRow(
                      label: 'docExpiryDateField'.tr(),
                      value: document.expiryDate != null
                          ? DateFormat('dd MMMM yyyy')
                              .format(document.expiryDate!)
                          : 'docStatusLifetime'.tr(),
                      isBold: true,
                    ),
                    if (document.issuingAuthority != null &&
                        document.issuingAuthority!.isNotEmpty) ...[
                      const Divider(height: 16, color: Color(0xFF262638)),
                      _buildMetaRow(
                        label: 'Authority',
                        value: document.issuingAuthority!,
                      ),
                    ],
                    if (document.cost != null && document.cost! > 0) ...[
                      const Divider(height: 16, color: Color(0xFF262638)),
                      _buildMetaRow(
                        label: 'Cost / Fees',
                        value: AppCurrency.format(document.cost!),
                      ),
                    ],
                    if (document.note != null &&
                        document.note!.isNotEmpty) ...[
                      const Divider(height: 16, color: Color(0xFF262638)),
                      _buildMetaRow(
                        label: 'docNoteField'.tr(),
                        value: document.note!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Action Buttons (Share, Edit, Delete)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareDocument(context),
                      icon: const Icon(LucideIcons.share2, size: 16),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Color(0xFF2E2E42)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await AddEditDocumentSheet.show(
                          context,
                          vehicleId: document.vehicleId,
                          existingDoc: document,
                        );
                      },
                      icon: const Icon(LucideIcons.fileEdit, size: 16),
                      label: Text('editDocument'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF2E2E42)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(LucideIcons.trash2,
                        color: Color(0xFFEF4444), size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFEF4444).withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        side: const BorderSide(
                            color: Color(0xFFEF4444), width: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(DocumentExpiryStatus status, int? daysLeft) {
    Color bg;
    Color border;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case DocumentExpiryStatus.valid:
        bg = const Color(0xFF10B981).withValues(alpha: 0.1);
        border = const Color(0xFF10B981).withValues(alpha: 0.3);
        icon = LucideIcons.shieldCheck;
        title = 'docStatusValid'.tr();
        subtitle = daysLeft != null
            ? '${daysLeft.toString()} days remaining until expiration'
            : 'Document is active';
        break;
      case DocumentExpiryStatus.expiringSoon:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        border = const Color(0xFFF59E0B).withValues(alpha: 0.4);
        icon = LucideIcons.alertTriangle;
        title = 'docStatusExpiringSoon'.tr();
        subtitle = daysLeft != null
            ? 'Expires in ${daysLeft.toString()} days — renew soon'
            : 'Document is expiring soon';
        break;
      case DocumentExpiryStatus.expired:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        border = const Color(0xFFEF4444).withValues(alpha: 0.4);
        icon = LucideIcons.alertCircle;
        title = 'docStatusExpired'.tr();
        final abs = daysLeft != null ? daysLeft.abs() : 0;
        subtitle = 'Expired $abs days ago — renew immediately';
        break;
      case DocumentExpiryStatus.noExpiry:
        bg = const Color(0xFF1E1E2A);
        border = const Color(0xFF2E2E42);
        icon = LucideIcons.infinity;
        title = 'docStatusLifetime'.tr();
        subtitle = 'No expiration date recorded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: border.withValues(alpha: 1.0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview({
    required BuildContext context,
    required String label,
    required String imagePath,
  }) {
    return InkWell(
      onTap: () => DocumentImageViewer.show(
        context,
        imagePath: imagePath,
        title: document.title,
        subtitle: label,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B27),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: const Color(0xFF262638), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(LucideIcons.imageOff, color: Color(0xFF71717A)),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(LucideIcons.maximize2,
                          size: 11, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
