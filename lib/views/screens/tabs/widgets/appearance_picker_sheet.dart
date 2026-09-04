import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../viewmodels/theme_viewmodel.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Theme picker: Light / Dark / System preview cards (app primary accent).
Future<void> showAppearancePickerSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final current = ref.read(themeModeProvider);
  final selected = await showModalBottomSheet<ThemeMode>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        child: CleanGlassPanel(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
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
                    'appearance'.tr(),
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'appearanceSubtitle'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (final mode in ThemeMode.values) ...[
                        if (mode != ThemeMode.values.first)
                          const SizedBox(width: 10),
                        Expanded(
                          child: _ThemePreviewCard(
                            mode: mode,
                            selected: mode == current,
                            onTap: () => Navigator.pop(sheetContext, mode),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  if (selected != null) {
    await ref.read(themeModeProvider.notifier).setMode(selected);
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.wash,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.hairline,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              _ThemeMiniPreview(mode: mode),
              const SizedBox(height: 8),
              Text(
                _label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontSize: 12,
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
    final lightBg = const Color(0xFFF4F5F7);
    final darkBg = const Color(0xFF1A1A1A);
    final lightCard = Colors.white;
    final darkCard = const Color(0xFF2A2A2A);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 72,
        width: double.infinity,
        child: isSystem
            ? Row(
                children: [
                  Expanded(
                    child: _MiniUi(
                      bg: lightBg,
                      card: lightCard,
                      isLight: true,
                    ),
                  ),
                  Expanded(
                    child: _MiniUi(
                      bg: darkBg,
                      card: darkCard,
                      isLight: false,
                    ),
                  ),
                ],
              )
            : _MiniUi(
                bg: mode == ThemeMode.light ? lightBg : darkBg,
                card: mode == ThemeMode.light ? lightCard : darkCard,
                isLight: mode == ThemeMode.light,
              ),
      ),
    );
  }
}

class _MiniUi extends StatelessWidget {
  const _MiniUi({
    required this.bg,
    required this.card,
    required this.isLight,
  });

  final Color bg;
  final Color card;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE2E5EC)
                    : const Color(0xFF3A3A3A),
              ),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
