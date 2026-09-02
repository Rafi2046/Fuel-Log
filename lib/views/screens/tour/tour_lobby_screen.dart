import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/intercom_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import 'tour_intercom_screen.dart';
import 'widgets/tour_join_code_sheet.dart';

/// Entry point for Tour Intercom — Create (host) or Join (discover) a tour.
/// Uses Google Nearby Connections — 100% OFFLINE ZERO-DATA P2P MESH.
class TourLobbyScreen extends ConsumerStatefulWidget {
  const TourLobbyScreen({super.key});

  @override
  ConsumerState<TourLobbyScreen> createState() => _TourLobbyScreenState();
}

class _TourLobbyScreenState extends ConsumerState<TourLobbyScreen>
    with SingleTickerProviderStateMixin {
  IntercomViewModel get _notifier => ref.read(intercomProvider.notifier);
  late final TabController _tabController;

  final _tourNameController = TextEditingController(text: 'My Bike Tour');
  final _joinCodeController = TextEditingController();
  final _tourNameFocus = FocusNode();
  final _joinCodeFocus = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tourNameController.dispose();
    _joinCodeController.dispose();
    _tourNameFocus.dispose();
    _joinCodeFocus.dispose();
    super.dispose();
  }

  Future<void> _onCreateTour() async {
    final name = _tourNameController.text.trim();
    if (name.isEmpty) {
      _tourNameFocus.requestFocus();
      return;
    }
    HapticFeedback.heavyImpact();

    final code = IntercomViewModel.generateJoinCode();
    _notifier.setTourCodeAndName(tourName: name, joinCode: code);

    if (!mounted) return;

    await TourJoinCodeSheet.show(
      context,
      joinCode: code,
      tourName: name,
      onEnterTour: () async {
        Navigator.of(context).pop();
        setState(() => _isLoading = true);
        await _notifier.createTour(tourName: name, preGeneratedCode: code);
        if (!mounted) return;
        setState(() => _isLoading = false);
        _goToIntercomScreen();
      },
    );
  }

  Future<void> _onJoinByCode() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length < 4) {
      _joinCodeFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter the 6-character tour join code.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();
    await _notifier.joinByCode(code);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _goToIntercomScreen();
  }

  void _goToIntercomScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TourIntercomScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: const AppBackButton(),
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.offline_bolt_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'NEARBY P2P MESH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tactical Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.add_circle_outline_rounded, size: 16),
                  text: 'HOST TOUR',
                ),
                Tab(
                  icon: Icon(Icons.group_add_rounded, size: 16),
                  text: 'JOIN TOUR',
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Host Tour
                _HostTourTab(
                  tourNameController: _tourNameController,
                  tourNameFocus: _tourNameFocus,
                  isLoading: _isLoading,
                  onCreateTour: _onCreateTour,
                ),

                // Tab 2: Join Tour
                _JoinTourTab(
                  joinCodeController: _joinCodeController,
                  joinCodeFocus: _joinCodeFocus,
                  isLoading: _isLoading,
                  onJoinByCode: _onJoinByCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Host Tour
// ─────────────────────────────────────────────────────────────────────────────

class _HostTourTab extends StatelessWidget {
  const _HostTourTab({
    required this.tourNameController,
    required this.tourNameFocus,
    required this.isLoading,
    required this.onCreateTour,
  });

  final TextEditingController tourNameController;
  final FocusNode tourNameFocus;
  final bool isLoading;
  final VoidCallback onCreateTour;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.podcasts_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start a Tour Mesh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nearby riders auto-connect over Wi-Fi Direct. 100% offline with zero data cost.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Text(
            'TOUR NAME',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: tourNameController,
            focusNode: tourNameFocus,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.two_wheeler_rounded,
                  color: AppColors.primary, size: 20),
              hintText: 'e.g. Sylhet Highway Tour',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onCreateTour,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                elevation: 0,
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rocket_launch_rounded, size: 20),
              label: Text(
                isLoading ? 'STARTING MESH...' : 'HOST TOUR NOW',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          _InfoCard(items: const [
            _InfoItem(
              icon: Icons.bluetooth_audio_rounded,
              text: 'Google Nearby Connections uses Bluetooth + Wi-Fi Direct automatically.',
            ),
            _InfoItem(
              icon: Icons.cell_wifi_rounded,
              text: 'No Personal Hotspot setup required — devices connect automatically.',
            ),
            _InfoItem(
              icon: Icons.shield_rounded,
              text: 'End-to-end encrypted local P2P audio streaming.',
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Join Tour
// ─────────────────────────────────────────────────────────────────────────────

class _JoinTourTab extends StatelessWidget {
  const _JoinTourTab({
    required this.joinCodeController,
    required this.joinCodeFocus,
    required this.isLoading,
    required this.onJoinByCode,
  });

  final TextEditingController joinCodeController;
  final FocusNode joinCodeFocus;
  final bool isLoading;
  final VoidCallback onJoinByCode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Join by Code Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join via Tour Code',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Enter the 6-character code from your host',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: joinCodeController,
                  focusNode: joinCodeFocus,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.firaCode(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: AppColors.primary,
                  ),
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '• • • • • •',
                    hintStyle: GoogleFonts.firaCode(
                      fontSize: 20,
                      letterSpacing: 6,
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onJoinByCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      elevation: 0,
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login_rounded, size: 18),
                    label: Text(
                      isLoading ? 'JOINING MESH...' : 'JOIN WITH CODE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _InfoCard(items: const [
            _InfoItem(
              icon: Icons.near_me_rounded,
              text: 'Host এবং Rider উভয়ের Bluetooth ও Wi-Fi অন থাকলে নিজে থেকেই Mesh যুক্ত হবে।',
            ),
            _InfoItem(
              icon: Icons.signal_cellular_off_rounded,
              text: 'কোনো ইন্টারনেট ডাটা বা মোবাইল নেটওয়ার্কের প্রয়োজন নেই।',
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Info Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoItem {
  const _InfoItem({required this.icon, required this.text});
  final IconData icon;
  final String text;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
