import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../models/fuel_price_model.dart';
import '../../../../viewmodels/gas_station_viewmodel.dart';
import 'widgets/fuel_type_badges.dart';
import 'widgets/station_price_row.dart';
import 'widgets/update_price_modal_sheet.dart';

/// Station Detail & Price Breakdown Screen styled with FuelLog luxury dark design
class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({
    super.key,
    required this.station,
  });

  final StationInfo station;

  Future<void> _openGoogleMaps(StationInfo s) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${s.location.latitude},${s.location.longitude}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showReportChangesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Report Station Information',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Help the community keep station info up to date for ${station.displayName}.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 20),
              ),
              title: const Text('Update Fuel Rates', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: const Text('Submit latest pump prices', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () {
                Navigator.of(ctx).pop();
                if (station.prices.isNotEmpty) {
                  showUpdatePriceModalSheet(
                    context,
                    station: station,
                    priceItem: station.prices.first,
                  );
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.directions_rounded, color: AppColors.primary, size: 20),
              ),
              title: const Text('Directions / Open Map', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: const Text('Open in navigation', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              onTap: () {
                Navigator.of(ctx).pop();
                _openGoogleMaps(station);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gasStationsProvider);
    final currentStation = state.allStations.firstWhere(
      (s) => s.id == station.id,
      orElse: () => station,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentStation.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: currentStation.isFavorite ? const Color(0xFFFBBF24) : AppColors.textSecondary,
              size: 26,
            ),
            onPressed: () {
              ref.read(gasStationsProvider.notifier).toggleFavorite(
                    currentStation.id,
                    fallbackStation: currentStation,
                  );
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    currentStation.isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites ⭐',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.directions_rounded, color: AppColors.primary),
            onPressed: () => _openGoogleMaps(currentStation),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STATION HEADER ────────────────────────────────────────────────
            Text(
              currentStation.displayName,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentStation.address.isNotEmpty ? currentStation.address : 'Nearby Station',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── ACTION ROW: Report Changes & Upvote ───────────────────────────
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showReportChangesSheet(context),
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Report changes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                ),

                const Spacer(),

                // Upvote Button
                InkWell(
                  onTap: () {
                    ref.read(gasStationsProvider.notifier).toggleUpvote(
                          currentStation.id,
                          fallbackStation: currentStation,
                        );
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          currentStation.isUserUpvoted
                              ? 'Upvote removed'
                              : 'Upvoted! Thank you for confirming pump rates 👍',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: currentStation.isUserUpvoted ? AppColors.primaryMuted : AppColors.card,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(
                        color: currentStation.isUserUpvoted ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentStation.isUserUpvoted
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_up_alt_outlined,
                          color: currentStation.isUserUpvoted ? AppColors.primary : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${currentStation.upvotes}',
                          style: TextStyle(
                            color: currentStation.isUserUpvoted ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── AVAILABLE FUEL TYPES (Modular Badges) ─────────────────────────
            Text(
              'AVAILABLE FUEL TYPES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FuelTypeBadges(categories: currentStation.availableCategories),

            const SizedBox(height: AppSpacing.xl),

            // ── GAS PRICES SECTION (Modular Rows) ─────────────────────────────
            Text(
              'CURRENT PUMP PRICES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (currentStation.prices.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Center(
                  child: Text(
                    'No price records available yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentStation.prices.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = currentStation.prices[index];
                  return StationPriceRow(
                    item: item,
                    onChangePressed: () {
                      showUpdatePriceModalSheet(
                        context,
                        station: currentStation,
                        priceItem: item,
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
