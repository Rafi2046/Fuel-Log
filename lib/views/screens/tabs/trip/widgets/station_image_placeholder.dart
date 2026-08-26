import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';

class StationImagePlaceholder extends StatelessWidget {
  const StationImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF20202A),
      child: const Center(
        child: Icon(
          LucideIcons.fuel,
          color: AppColors.textTertiary,
          size: 22,
        ),
      ),
    );
  }
}

