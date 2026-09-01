import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

/// Compact leading icon for list cards — vertically centered in rows.
class ListLeadIcon extends StatelessWidget {
  const ListLeadIcon({
    super.key,
    required this.icon,
    this.iconSize = 16,
    this.padding = 6,
  });

  final IconData icon;
  final double iconSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: const Color(0xFF2A2A3C),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFFA1A1AA),
        size: iconSize,
      ),
    );
  }
}
