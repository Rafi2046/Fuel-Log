import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_images.dart';
import '../../core/constants/app_regions.dart';
import '../../core/services/onboarding_prefs.dart';
import '../../viewmodels/region_viewmodel.dart';
import '../widgets/app_primary_button.dart';
import 'vehicle_setup_screen.dart';

/// Two-step first-run chooser: language → currency (after splash).
class OnboardingLocaleScreen extends ConsumerStatefulWidget {
  const OnboardingLocaleScreen({
    super.key,
    this.next = const VehicleSetupScreen(),
  });

  final Widget next;

  @override
  ConsumerState<OnboardingLocaleScreen> createState() =>
      _OnboardingLocaleScreenState();
}

class _OnboardingLocaleScreenState extends ConsumerState<OnboardingLocaleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final PageController _pages;
  int _step = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();
  }

  @override
  void dispose() {
    _pages.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _goToCurrency() async {
    await _pages.animateToPage(
      1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    final language = ref.read(appLanguageProvider);
    final currency = ref.read(appCurrencyProvider);
    await ref.read(appLanguageProvider.notifier).setLanguage(language);
    await ref.read(appCurrencyProvider.notifier).setCurrency(currency);
    if (mounted) await context.setLocale(language.locale);
    await OnboardingPrefs.markOnboardingComplete();

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, _) => widget.next,
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final currency = ref.watch(appCurrencyProvider);
    final isLanguageStep = _step == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0E0E14),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E14),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0E0E14)),
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.26),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 140,
              left: -90,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BrandHeader(step: _step),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Column(
                            key: ValueKey(_step),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLanguageStep
                                    ? 'onboardingLanguageTitle'.tr()
                                    : 'onboardingCurrencyTitle'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isLanguageStep
                                    ? 'onboardingLanguageSubtitle'.tr()
                                    : 'onboardingCurrencySubtitle'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Expanded(
                          child: PageView(
                            controller: _pages,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (i) => setState(() => _step = i),
                            children: [
                              _OptionList(
                                children: [
                                  for (final lang in AppLanguage.values)
                                    _PremiumOptionTile(
                                      selected: language == lang,
                                      flag: lang.flagEmoji,
                                      title: lang.nameKey.tr(),
                                      subtitle: lang.id.toUpperCase(),
                                      onTap: () async {
                                        await ref
                                            .read(appLanguageProvider.notifier)
                                            .setLanguage(lang);
                                        if (context.mounted) {
                                          await context.setLocale(lang.locale);
                                        }
                                      },
                                    ),
                                ],
                              ),
                              _OptionList(
                                children: [
                                  for (final cur in AppCurrencyId.values)
                                    _PremiumOptionTile(
                                      selected: currency == cur,
                                      flag: cur.flagEmoji,
                                      title: cur.code,
                                      subtitle:
                                          '${cur.glyph}  ·  ${cur.nameKey.tr()}',
                                      onTap: () => ref
                                          .read(appCurrencyProvider.notifier)
                                          .setCurrency(cur),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppPrimaryButton(
                          label: isLanguageStep
                              ? 'onboardingLocaleContinue'.tr()
                              : 'onboardingLocaleFinish'.tr(),
                          isLoading: _saving,
                          onPressed: isLanguageStep ? _goToCurrency : _finish,
                        ),
                      ],
                    ),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(AppImages.appLogo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FuelSync',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Text(
          '${step + 1} / 2',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => children[i],
    );
  }
}

class _PremiumOptionTile extends StatelessWidget {
  const _PremiumOptionTile({
    required this.selected,
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String flag;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0xFF16161E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.07),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
