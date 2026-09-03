import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/intercom_rider_role.dart';
import '../../../viewmodels/intercom_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import 'tour_intercom_screen.dart';
import 'widgets/intercom_rider_role_selector.dart';
import 'widgets/tour_join_code_sheet.dart';
import 'widgets/tour_qr_scanner_sheet.dart';

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
  IntercomRiderRole _selectedRole = IntercomRiderRole.groupRider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectedRole = ref.read(intercomProvider).riderRole;
      setState(() {});
    });
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
    await _notifier.setRiderRole(_selectedRole);

    setState(() => _isLoading = true);
    try {
      // 1. Host enters and starts tour session immediately
      await _notifier.createTour(tourName: name, preGeneratedCode: code).timeout(
        const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('[TourLobby] createTour error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;
    // 2. Navigate host to the live Intercom room
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            TourJoinCodeSheet.show(ctx, joinCode: code, tourName: name);
          });
          return const TourIntercomScreen();
        },
      ),
    );
  }

  Future<void> _onScanQr() async {
    final scannedCode = await TourQrScannerSheet.show(context);
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _joinCodeController.text = scannedCode;
      await _onJoinByCode();
    }
  }

  Future<void> _onJoinByCode() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length < 4) {
      _joinCodeFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter the 6-character tour join code.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();
    try {
      await _notifier.setRiderRole(_selectedRole);
      await _notifier.joinByCode(code).timeout(
        const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('[TourLobby] joinByCode error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    _goToIntercomScreen();
  }

  Future<void> _onRejoinRecentTour() async {
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();
    try {
      _selectedRole = ref.read(intercomProvider).riderRole;
      await _notifier.rejoinRecentTour().timeout(
        const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('[TourLobby] rejoinRecentTour error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    _goToIntercomScreen();
  }

  void _goToIntercomScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TourIntercomScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intercomState = ref.watch(intercomProvider);

    return AppScaffold(
      leading: const AppBackButton(),
      title: 'Tour intercom',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.appBarBodyGap,
              AppSpacing.screenPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (intercomState.hasRecentTour) ...[
                  _RecentTourRejoinBanner(
                    tourName: intercomState.lastTourName ?? 'Recent tour',
                    tourCode: intercomState.lastTourCode!,
                    isHost: intercomState.lastTourIsHost,
                    isLoading: _isLoading,
                    onRejoin: _onRejoinRecentTour,
                    onDismiss: () => _notifier.clearRecentTourSession(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14141B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF282836),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => HapticFeedback.selectionClick(),
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.75),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 12,
                          spreadRadius: -1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: const Color(0xFF8E8EA0),
                    labelStyle: AppTextStyles.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelStyle: AppTextStyles.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        height: 38,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.podcasts_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Host'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 38,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_add_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Join'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _tabController.index == 0
                      ? _HostTourTab(
                          key: const ValueKey('host-tab'),
                          tourNameController: _tourNameController,
                          tourNameFocus: _tourNameFocus,
                          isLoading: _isLoading,
                          selectedRole: _selectedRole,
                          onRoleChanged: (role) =>
                              setState(() => _selectedRole = role),
                          onCreateTour: _onCreateTour,
                        )
                      : _JoinTourTab(
                          key: const ValueKey('join-tab'),
                          joinCodeController: _joinCodeController,
                          joinCodeFocus: _joinCodeFocus,
                          isLoading: _isLoading,
                          selectedRole: _selectedRole,
                          onRoleChanged: (role) =>
                              setState(() => _selectedRole = role),
                          onJoinByCode: _onJoinByCode,
                          onScanQr: _onScanQr,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _TourHowItWorksCard(),
                const SizedBox(height: AppSpacing.md),
                const _TourRequirementsCard(),
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
    super.key,
    required this.tourNameController,
    required this.tourNameFocus,
    required this.isLoading,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onCreateTour,
  });

  final TextEditingController tourNameController;
  final FocusNode tourNameFocus;
  final bool isLoading;
  final IntercomRiderRole selectedRole;
  final ValueChanged<IntercomRiderRole> onRoleChanged;
  final VoidCallback onCreateTour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.podcasts_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nearby riders connect offline over Bluetooth and Wi‑Fi Direct. No mobile data needed.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tour name',
          style: AppTextStyles.label.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: tourNameController,
          focusNode: tourNameFocus,
          style: AppTextStyles.body.copyWith(fontSize: 15),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.two_wheeler_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            hintText: 'e.g. Sylhet highway tour',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntercomRiderRoleSelector(
          selectedRole: selectedRole,
          onRoleChanged: onRoleChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.buttonHeightCompact,
          child: ElevatedButton(
            onPressed: isLoading ? null : onCreateTour,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Host tour',
                    style: AppTextStyles.button.copyWith(fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Join Tour
// ─────────────────────────────────────────────────────────────────────────────

class _JoinTourTab extends StatelessWidget {
  const _JoinTourTab({
    super.key,
    required this.joinCodeController,
    required this.joinCodeFocus,
    required this.isLoading,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onJoinByCode,
    required this.onScanQr,
  });

  final TextEditingController joinCodeController;
  final FocusNode joinCodeFocus;
  final bool isLoading;
  final IntercomRiderRole selectedRole;
  final ValueChanged<IntercomRiderRole> onRoleChanged;
  final VoidCallback onJoinByCode;
  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.buttonHeightCompact,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onScanQr,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
            label: Text(
              'Scan host QR code',
              style: AppTextStyles.button.copyWith(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'or enter code',
                style: AppTextStyles.caption,
              ),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join via tour code',
                style: AppTextStyles.title.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                'Enter the 6-character code from your host',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: joinCodeController,
                focusNode: joinCodeFocus,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: GoogleFonts.firaCode(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 6,
                  color: AppColors.textPrimary,
                ),
                maxLength: 6,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: AppSpacing.buttonHeightCompact,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onJoinByCode,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Join tour',
                          style: AppTextStyles.button.copyWith(fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntercomRiderRoleSelector(
          selectedRole: selectedRole,
          onRoleChanged: onRoleChanged,
        ),
      ],
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
  const _InfoCard({required this.title, required this.items});

  final String title;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((item) {
            final isLast = item == items.last;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, size: 15, color: AppColors.textTertiary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item.text,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TourHowItWorksCard extends StatelessWidget {
  const _TourHowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'How it works',
      items: const [
        _InfoItem(
          icon: Icons.add_circle_outline,
          text: 'Host creates a tour and shares the join code or QR.',
        ),
        _InfoItem(
          icon: Icons.group_outlined,
          text: 'Riders join with the code — no internet needed.',
        ),
        _InfoItem(
          icon: Icons.mic_none_outlined,
          text: 'Push to talk with your group while riding.',
        ),
      ],
    );
  }
}

class _TourRequirementsCard extends StatelessWidget {
  const _TourRequirementsCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Before you start',
      items: const [
        _InfoItem(
          icon: Icons.bluetooth_outlined,
          text: 'Turn on Bluetooth on every phone.',
        ),
        _InfoItem(
          icon: Icons.wifi_outlined,
          text: 'Keep Wi‑Fi on — used for nearby device discovery.',
        ),
        _InfoItem(
          icon: Icons.shield_outlined,
          text: 'Audio stays on-device; no mobile data is used.',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1-Click Recent Tour Rejoin Banner (WhatsApp / Messenger Style)
// ─────────────────────────────────────────────────────────────────────────────

class _RecentTourRejoinBanner extends StatelessWidget {
  const _RecentTourRejoinBanner({
    required this.tourName,
    required this.tourCode,
    required this.isHost,
    required this.isLoading,
    required this.onRejoin,
    required this.onDismiss,
  });

  final String tourName;
  final String tourCode;
  final bool isHost;
  final bool isLoading;
  final VoidCallback onRejoin;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tourName,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isHost ? 'Host' : 'Rider',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Code $tourCode',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                onPressed: onDismiss,
                constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.buttonHeightCompact,
            child: OutlinedButton(
              onPressed: isLoading ? null : onRejoin,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Rejoin tour',
                      style: AppTextStyles.button.copyWith(fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
