import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Bottom sheet showing QR code + join code for the host to share with riders.
class TourJoinCodeSheet extends StatefulWidget {
  const TourJoinCodeSheet({
    super.key,
    required this.joinCode,
    required this.tourName,
    this.onEnterTour,
  });

  final String joinCode;
  final String tourName;

  /// If provided (create flow), shows an "Enter tour" CTA button at the bottom.
  final VoidCallback? onEnterTour;

  static Future<void> show(
    BuildContext context, {
    required String joinCode,
    required String tourName,
    VoidCallback? onEnterTour,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: onEnterTour == null,
      enableDrag: onEnterTour == null,
      backgroundColor: Colors.transparent,
      builder: (_) => TourJoinCodeSheet(
        joinCode: joinCode,
        tourName: tourName,
        onEnterTour: onEnterTour,
      ),
    );
  }

  @override
  State<TourJoinCodeSheet> createState() => _TourJoinCodeSheetState();
}

class _TourJoinCodeSheetState extends State<TourJoinCodeSheet> {
  bool _codeCopied = false;

  static final _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  );

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.joinCode));
    HapticFeedback.lightImpact();
    setState(() => _codeCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _shareCode() {
    HapticFeedback.lightImpact();
    Share.share(
      '🏍️ Join my FuelSync Tour Intercom!\n\n'
      'Tour: ${widget.tourName}\n'
      'Code: ${widget.joinCode}\n\n'
      'Open FuelSync → Tour Intercom → Join Tour → Enter code: ${widget.joinCode}',
      subject: 'FuelSync Tour Invite — ${widget.joinCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite riders',
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                    Text(
                      widget.tourName,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: widget.joinCode,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF121212),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF121212),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Join code',
            style: AppTextStyles.label.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              widget.joinCode,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 8,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeightCompact,
                  child: OutlinedButton.icon(
                    onPressed: _copyCode,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _codeCopied ? AppColors.success : AppColors.primary,
                      side: BorderSide(
                        color: _codeCopied
                            ? AppColors.success.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                      shape: _buttonShape,
                      textStyle: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    icon: Icon(
                      _codeCopied
                          ? Icons.check_rounded
                          : Icons.content_copy_rounded,
                      size: 16,
                    ),
                    label: Text(_codeCopied ? 'Copied' : 'Copy code'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeightCompact,
                  child: ElevatedButton.icon(
                    onPressed: _shareCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: _buttonShape,
                      textStyle: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Share'),
                  ),
                ),
              ),
            ],
          ),

          if (widget.onEnterTour != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightCompact,
              child: ElevatedButton.icon(
                onPressed: widget.onEnterTour,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: _buttonShape,
                  textStyle: AppTextStyles.button.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                icon: const Icon(Icons.sensors_rounded, size: 18),
                label: const Text('Enter tour'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
