import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/clean_glass_panel.dart';

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

  String get _displayCode =>
      widget.joinCode.replaceAll(' ', '').split('').join(' ');

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
    SharePlus.instance.share(
      ShareParams(
        text: '🏍️ Join my FuelSync Tour Intercom!\n\n'
            'Tour: ${widget.tourName}\n'
            'Code: ${widget.joinCode}\n\n'
            'Open FuelSync → Tour Intercom → Join Tour → Enter code: ${widget.joinCode}',
        subject: 'FuelSync Tour Invite — ${widget.joinCode}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CleanGlassPanel(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite riders',
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.tourName,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.md),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  'Scan to join',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: QrImageView(
                    data: widget.joinCode,
                    version: QrVersions.auto,
                    size: 168,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF121212),
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF121212),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        'or use code',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  _displayCode,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.firaCode(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Share this code with riders on your tour',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          AppPrimaryButton(
            label: 'Share invite',
            compact: true,
            onPressed: _shareCode,
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.buttonHeightCompact,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _copyCode,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _codeCopied ? AppColors.success : AppColors.textPrimary,
                side: BorderSide(
                  color: _codeCopied
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
                shape: _buttonShape,
                textStyle: AppTextStyles.button.copyWith(fontSize: 14),
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
                label: Text('Enter tour'),
              ),
            ),
          ] else ...[
            SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightCompact,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.border),
                  shape: _buttonShape,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
