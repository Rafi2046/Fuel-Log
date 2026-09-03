import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../models/fuel_price_model.dart';
import '../../../../viewmodels/gas_station_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
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
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${s.location.latitude},${s.location.longitude}',
    );
    final geoUrl = Uri.parse(
      'geo:${s.location.latitude},${s.location.longitude}?q=${s.location.latitude},${s.location.longitude}(${Uri.encodeComponent(s.displayName)})',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }

  void _showReportChangesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
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
            SizedBox(height: AppSpacing.md),
            Text(
              'Report Station Information',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Help keep pump info up to date for ${station.displayName}.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 20),
              ),
              title: Text('Update Fuel Rates', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Submit latest pump prices', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.directions_rounded, color: AppColors.primary, size: 20),
              ),
              title: Text('Directions / Open Map', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Open in navigation', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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
      appBar: AppAppBar(
        leading: AppBackButton(),
        titleWidget: Text(
          currentStation.name,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentStation.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: currentStation.isFavorite ? Color(0xFFFBBF24) : AppColors.textSecondary,
              size: 22,
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
            icon: const Icon(Icons.directions_rounded, color: AppColors.primary, size: 22),
            onPressed: () => _openGoogleMaps(currentStation),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.appBarBodyGap,
          AppSpacing.screenPadding,
          AppSpacing.appBarBodyGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STATION HEADER ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStation.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        currentStation.address.isNotEmpty
                            ? currentStation.address
                            : 'Nearby Fuel Station',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── ACTION ROW: Report Changes & Upvote ───────────────────────────
            Row(
              children: [
                Material(
                  color: const Color(0xFF1B1B24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: InkWell(
                    onTap: () => _showReportChangesSheet(context),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(color: const Color(0xFF2C2C3A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Report changes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Sleek Upvote Button
                Material(
                  color: currentStation.isUserUpvoted
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFF1B1B24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: InkWell(
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
                                : 'Upvoted! Thank you for confirming rates 👍',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                          color: currentStation.isUserUpvoted
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : const Color(0xFF2C2C3A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentStation.isUserUpvoted
                                ? Icons.thumb_up_alt_rounded
                                : Icons.thumb_up_alt_outlined,
                            color: currentStation.isUserUpvoted
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '${currentStation.upvotes}',
                            style: TextStyle(
                              color: currentStation.isUserUpvoted
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 18),

            // ── AVAILABLE FUEL TYPES (Minimalist Chips) ───────────────────────
            Text(
              'AVAILABLE FUEL TYPES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: 8),
            FuelTypeBadges(categories: currentStation.availableCategories),

            SizedBox(height: 20),

            // ── GAS PRICES SECTION ────────────────────────────────────────────
            Text(
              'CURRENT PUMP PRICES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: 8),

            if (currentStation.prices.isEmpty)
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
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
                separatorBuilder: (context, _) => const SizedBox(height: 6),
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
