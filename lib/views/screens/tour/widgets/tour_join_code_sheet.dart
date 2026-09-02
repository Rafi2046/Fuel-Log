import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

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
  /// If provided (create flow), shows an "ENTER TOUR" CTA button at the bottom.
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
      isDismissible: onEnterTour == null, // prevent swipe-dismiss when enter tour required
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        20,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVITE RIDERS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      widget.tourName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
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
              ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
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

          const SizedBox(height: 20),

          // Code display
          Text(
            'JOIN CODE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              widget.joinCode,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Copy + Share row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyCode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _codeCopied ? AppColors.success : AppColors.primary,
                    side: BorderSide(
                      color: _codeCopied
                          ? AppColors.success.withValues(alpha: 0.6)
                          : AppColors.primary.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  icon: Icon(
                    _codeCopied ? Icons.check_rounded : Icons.content_copy_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _codeCopied ? 'COPIED!' : 'COPY CODE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    'SHARE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ENTER TOUR button — shown only in create flow
          if (widget.onEnterTour != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: widget.onEnterTour,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.sensors_rounded, size: 18),
                label: Text(
                  'ENTER TOUR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
