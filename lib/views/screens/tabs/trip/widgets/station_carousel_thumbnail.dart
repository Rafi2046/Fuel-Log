import 'package:flutter/material.dart';

import '../../../../../models/mock_gas_station.dart';
import 'station_image_placeholder.dart';

/// Left thumbnail + OPEN badge for a nearby-station carousel card.
class StationCarouselThumbnail extends StatelessWidget {
  const StationCarouselThumbnail({super.key, required this.station});

  final MockGasStation station;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 78,
        height: double.infinity,
        color: const Color(0xFF20202A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (station.imageUrl != null)
              station.imageUrl!.startsWith('http')
                  ? Image.network(
                      station.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const StationImagePlaceholder(),
                    )
                  : Image.asset(
                      station.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const StationImagePlaceholder(),
                    )
            else
              const StationImagePlaceholder(),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF101014).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'OPEN',
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
