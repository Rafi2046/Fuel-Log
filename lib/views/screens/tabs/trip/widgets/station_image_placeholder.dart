import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';

class StationImagePlaceholder extends StatelessWidget {
  const StationImagePlaceholder({super.key, this.fuelTypes = ''});

  final String fuelTypes;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(fuelTypes);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ),
      ),
      child: Center(
        child: Icon(
          style.icon,
          color: style.iconColor,
          size: 22,
        ),
      ),
    );
  }

  static _PlaceholderStyle _styleFor(String fuelTypes) {
    final fuels = fuelTypes.toLowerCase();
    if (fuels.contains('cng') && !fuels.contains('octane')) {
      return const _PlaceholderStyle(
        colors: [Color(0xFF1B3D2F), Color(0xFF0F2419)],
        icon: LucideIcons.flame,
        iconColor: Color(0xFF81C784),
      );
    }
    if (fuels.contains('lpg')) {
      return const _PlaceholderStyle(
        colors: [Color(0xFF2A2340), Color(0xFF171222)],
        icon: LucideIcons.fuel,
        iconColor: Color(0xFFCE93D8),
      );
    }
    if (fuels.contains('ev')) {
      return const _PlaceholderStyle(
        colors: [Color(0xFF1A2B3D), Color(0xFF0E1824)],
        icon: LucideIcons.zap,
        iconColor: Color(0xFF64B5F6),
      );
    }
    return const _PlaceholderStyle(
      colors: [Color(0xFF2A2418), Color(0xFF17140E)],
      icon: LucideIcons.fuel,
      iconColor: AppColors.textTertiary,
    );
  }
}

class _PlaceholderStyle {
  const _PlaceholderStyle({
    required this.colors,
    required this.icon,
    required this.iconColor,
  });

  final List<Color> colors;
  final IconData icon;
  final Color iconColor;
}
