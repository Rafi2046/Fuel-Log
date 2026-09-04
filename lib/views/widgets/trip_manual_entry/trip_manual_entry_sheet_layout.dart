import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'trip_manual_entry_header.dart';
import 'trip_save_footer.dart';

/// Modal scaffold layout for TripManualEntrySheet with blur backdrop and header.
class TripManualEntrySheetLayout extends StatelessWidget {
  const TripManualEntrySheetLayout({
    super.key,
    required this.formKey,
    required this.onClose,
    required this.onSave,
    required this.isSaving,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final bool isSaving;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: maxHeight,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TripManualEntryHeader(onClose: onClose),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                          AppSpacing.screenPadding,
                          AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                    TripSaveFooter(
                      isSaving: isSaving,
                      onSave: onSave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
