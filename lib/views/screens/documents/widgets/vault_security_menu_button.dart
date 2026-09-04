import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/vault_security_service.dart';
import 'vault_pin_screen.dart';

/// App bar popup menu button for vault PIN settings and locking.
class VaultSecurityMenuButton extends StatelessWidget {
  const VaultSecurityMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        LucideIcons.shieldCheck,
        color: Color(0xFF10B981),
        size: 20,
      ),
      tooltip: 'Vault Security',
      color: AppColors.control,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
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
              const Icon(
                LucideIcons.keyRound,
                size: 16,
                color: Color(0xFFFF7A50),
              ),
              const SizedBox(width: 10),
              Text(
                'Security PIN Settings',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'lock',
          child: Row(
            children: [
              const Icon(
                LucideIcons.lock,
                size: 16,
                color: Color(0xFFEF4444),
              ),
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
    );
  }
}
