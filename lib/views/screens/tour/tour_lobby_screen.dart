import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/p2p_voice_service.dart';
import '../../../viewmodels/intercom_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import 'tour_intercom_screen.dart';
import 'widgets/tour_join_code_sheet.dart';

/// Entry point for Tour Intercom — Create (host) or Join (discover) a tour.
/// Uses flutter_nearby_connections — NO INTERNET required.
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
  bool _isBrowsing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_isBrowsing) {
      _startBrowsing();
    }
  }

  Future<void> _startBrowsing() async {
    setState(() => _isBrowsing = true);
    await _notifier.startBrowsing('Rider');
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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

    // Step 1: Generate code immediately and show QR to share
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
        // Step 2: Start P2P hosting
        await _notifier.createTour(tourName: name, preGeneratedCode: code);
        if (!mounted) return;
        setState(() => _isLoading = false);
        _goToIntercomScreen();
      },
    );
  }

  Future<void> _onJoinTour(P2PPeer tourHost) async {
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();
    await _notifier.joinTour(tourHost);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _goToIntercomScreen();
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
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
            child: const Icon(Icons.sensors_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'TOUR INTERCOM',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 12,
      ),
      body: Column(
        children: [
          _LobbyHero(),
          const SizedBox(height: 24),
          _TabSelector(controller: _tabController),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CreateTourTab(
                  controller: _tourNameController,
                  focusNode: _tourNameFocus,
                  isLoading: _isLoading,
                  onStart: _onCreateTour,
                ),
                _JoinTourTab(
                  isLoading: _isLoading,
                  codeController: _joinCodeController,
                  codeFocusNode: _joinCodeFocus,
                  onJoin: _onJoinTour,
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

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _LobbyHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.podcasts_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline P2P Voice Chat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'WiFi Direct + Bluetooth — works with zero mobile data.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Selector ─────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        unselectedLabelStyle:
            GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '🏍️  HOST TOUR'),
          Tab(text: '📡  FIND TOUR'),
        ],
      ),
    );
  }
}

// ─── Create Tour Tab ──────────────────────────────────────────────────────────

class _CreateTourTab extends StatelessWidget {
  const _CreateTourTab({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onStart,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(icon: Icons.edit_rounded, label: 'TOUR NAME'),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLength: 40,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: "e.g. Cox's Bazar Weekend Ride",
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.textTertiary),
              prefixIcon:
                  const Icon(Icons.route_rounded, color: AppColors.textSecondary, size: 18),
              filled: true,
              fillColor: AppColors.card,
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _InfoCard(items: const [
            _InfoItem(
              icon: Icons.wifi_tethering_rounded,
              text: 'Your device broadcasts the tour over WiFi Direct. Riders auto-discover — no code needed!',
            ),
            _InfoItem(
              icon: Icons.bluetooth_rounded,
              text: 'Bluetooth + WiFi Direct means it works even without a cell signal or internet.',
            ),
            _InfoItem(
              icon: Icons.person_add_rounded,
              text: 'A QR + share code will be shown for manual invite if auto-discovery fails.',
            ),
          ]),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'START HOSTING',
            icon: Icons.wifi_tethering_rounded,
            isLoading: isLoading,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

// ─── Join Tour Tab ────────────────────────────────────────────────────────────

class _JoinTourTab extends ConsumerWidget {
  const _JoinTourTab({
    required this.isLoading,
    required this.codeController,
    required this.codeFocusNode,
    required this.onJoin,
    required this.onJoinByCode,
  });

  final bool isLoading;
  final TextEditingController codeController;
  final FocusNode codeFocusNode;
  final void Function(P2PPeer) onJoin;
  final VoidCallback onJoinByCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(intercomProvider);
    final tours = state.discoveredTours;
    final isConnecting = state.isConnecting;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. WiFi & Hotspot Auto-Discovery Status
          _WifiStatusBar(isConnecting: isConnecting, toursFound: tours.length),
          const SizedBox(height: 12),

          if (tours.isNotEmpty) ...[
            Text(
              'NEARBY ACTIVE TOURS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            ...tours.map((tour) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TourListTile(
                device: tour,
                isLoading: isLoading,
                onJoin: () => onJoin(tour),
              ),
            )),
            const SizedBox(height: 12),
          ] else ...[
            _EmptyDiscovery(isScanning: isConnecting || true),
            const SizedBox(height: 16),
          ],

          // 2. Divider with OR
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR ENTER TOUR CODE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Monospace Tour Code Input
          TextField(
            controller: codeController,
            focusNode: codeFocusNode,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '· · · · · ·',
              hintStyle: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                color: AppColors.textTertiary,
                letterSpacing: 8,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 48,
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
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                'JOIN WITH CODE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _InfoCard(items: const [
            _InfoItem(
              icon: Icons.wifi_tethering_rounded,
              text: 'Leader-এর হটস্পট চালু থাকলে আশেপাশের ট্যুর সরাসরি উপরে ভেসে উঠবে।',
            ),
            _InfoItem(
              icon: Icons.key_rounded,
              text: 'অথবা Leader-এর শেয়ার করা ৬-অক্ষরের কোড লিখেও সরাসরি জয়েন করা যাবে।',
            ),
          ]),
        ],
      ),
    );
  }
}

class _WifiStatusBar extends StatelessWidget {
  const _WifiStatusBar({required this.isConnecting, required this.toursFound});
  final bool isConnecting;
  final int toursFound;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          if (isConnecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Icon(
              toursFound > 0 ? Icons.wifi_rounded : Icons.wifi_find_rounded,
              color: toursFound > 0 ? AppColors.success : AppColors.primary,
              size: 16,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isConnecting
                  ? 'Starting discovery...'
                  : toursFound > 0
                      ? '$toursFound tour${toursFound == 1 ? '' : 's'} found nearby'
                      : 'Scanning for nearby tours via WiFi Direct & Bluetooth...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Live pulse
          if (!isConnecting)
            _ScanPulse(),
        ],
      ),
    );
  }
}

class _ScanPulse extends StatefulWidget {
  @override
  State<_ScanPulse> createState() => _ScanPulseState();
}

class _ScanPulseState extends State<_ScanPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: _anim.value),
        ),
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery({required this.isScanning});
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wifi_find_rounded,
          size: 52,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 14),
        Text(
          isScanning ? 'Searching for nearby tours...' : 'No tours found',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ask your host to start hosting,\nthen tap FIND TOUR here.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textTertiary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TourListTile extends StatelessWidget {
  const _TourListTile({
    required this.device,
    required this.isLoading,
    required this.onJoin,
  });
  final P2PPeer device;
  final bool isLoading;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final tourName = device.tourName.isNotEmpty ? device.tourName : device.name;
    final code = device.tourCode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.15),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: const Icon(Icons.podcasts_rounded,
              color: AppColors.primary, size: 20),
        ),
        title: Text(
          tourName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.success),
            ),
            const SizedBox(width: 5),
            Text(
              'LIVE • ${code.isNotEmpty ? "Code: $code" : "Local Hotspot"} • ${device.address.address}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: isLoading ? null : onJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              elevation: 0,
            ),
            child: Text(
              'JOIN',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

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
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 20),
        label: Text(
          isLoading ? 'CONNECTING...' : label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
      ),
    );
  }
}
