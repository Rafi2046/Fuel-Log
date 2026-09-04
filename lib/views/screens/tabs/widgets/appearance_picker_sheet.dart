import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../viewmodels/theme_viewmodel.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Inline Light / Dark / System theme cards — sits on Settings (not a sheet).
class AppearanceThemeSection extends ConsumerWidget {
  const AppearanceThemeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'appearance'.tr().toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ),
        CleanGlassPanel(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final mode in ThemeMode.values) ...[
                if (mode != ThemeMode.values.first) const SizedBox(width: 6),
                Expanded(
                  child: _ThemePreviewCard(
                    mode: mode,
                    selected: mode == current,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setMode(mode),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  String get _label => switch (mode) {
        ThemeMode.light => 'themeLight'.tr(),
        ThemeMode.dark => 'themeDark'.tr(),
        ThemeMode.system => 'themeSystem'.tr(),
      };

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
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Column(
            children: [
              _ThemeMiniPreview(mode: mode),
              const SizedBox(height: 6),
              Text(
                _label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeMiniPreview extends StatelessWidget {
  const _ThemeMiniPreview({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final isSystem = mode == ThemeMode.system;

    return SizedBox(
      height: 72,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: AppColors.isDark ? 0.3 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isSystem
              ? const Row(
                  children: [
                    Expanded(child: _MiniUi(brightness: Brightness.light)),
                    Expanded(child: _MiniUi(brightness: Brightness.dark)),
                  ],
                )
              : _MiniUi(
                  brightness: mode == ThemeMode.light
                      ? Brightness.light
                      : Brightness.dark,
                ),
        ),
      ),
    );
  }
}

/// Soft “shimmer” mock UI: status chip + lines + accent tile.
class _MiniUi extends StatelessWidget {
  const _MiniUi({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isLight = brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFF3F4F6) : const Color(0xFF1C1C28);
    final surface = isLight ? Colors.white : const Color(0xFF2A2A38);
    final line = isLight ? const Color(0xFFD8DBE4) : const Color(0xFF3E3E52);
    final lineSoft = isLight ? const Color(0xFFE8EAF0) : const Color(0xFF323246);

    return ColoredBox(
      color: bg,
      child: Stack(
        children: [
          // Soft top sheen
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isLight ? 0.55 : 0.08),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: lineSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Container(
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: lineSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: line.withValues(alpha: 0.7)),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
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
