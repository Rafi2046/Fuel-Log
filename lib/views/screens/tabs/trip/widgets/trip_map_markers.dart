import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';

class TripUserLocationMarker extends StatelessWidget {
  const TripUserLocationMarker({this.isLocating = false});

  final bool isLocating;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: isLocating ? 40 : 34,
            height: isLocating ? 40 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF29B6F6).withValues(
                alpha: isLocating ? 0.35 : 0.2,
              ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0288D1),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class TripDestinationFlagMarker extends StatelessWidget {
  const TripDestinationFlagMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      LucideIcons.flag,
      size: 22,
      color: Color(0xFF00E5FF),
    );
  }
}

class TripStationPinMarker extends StatelessWidget {
  const TripStationPinMarker({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        LucideIcons.mapPin,
        size: isSelected ? 30 : 26,
        color: isSelected ? AppColors.primary : const Color(0xFF4A9EFF),
      ),
    );
  }
}

