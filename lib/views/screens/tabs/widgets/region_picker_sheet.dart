import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_regions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../viewmodels/region_viewmodel.dart';
import '../../../widgets/clean_glass_panel.dart';

Future<void> showLanguagePickerSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final current = ref.read(appLanguageProvider);
  final selected = await _showOptionSheet<AppLanguage>(
    context: context,
    title: 'language'.tr(),
    subtitle: 'languageSubtitle'.tr(),
    icon: LucideIcons.languages,
    options: AppLanguage.values,
    isSelected: (o) => o == current,
    leading: (o) => o.flagEmoji,
    titleOf: (o) => o.nameKey.tr(),
    subtitleOf: (o) => o.id.toUpperCase(),
  );
  if (selected == null || !context.mounted) return;
  await ref.read(appLanguageProvider.notifier).setLanguage(selected);
  if (!context.mounted) return;
  await context.setLocale(selected.locale);
}

Future<void> showCurrencyPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final current = ref.read(appCurrencyProvider);
  final selected = await _showOptionSheet<AppCurrencyId>(
    context: context,
    title: 'currency'.tr(),
    subtitle: 'currencySubtitle'.tr(),
    icon: LucideIcons.coins,
    options: AppCurrencyId.values,
    isSelected: (o) => o == current,
    leading: (o) => o.flagEmoji,
    titleOf: (o) => o.nameKey.tr(),
    subtitleOf: (o) => o.code,
    trailing: (o) => o.glyph,
  );
  if (selected == null) return;
  await ref.read(appCurrencyProvider.notifier).setCurrency(selected);
}

Future<T?> _showOptionSheet<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required List<T> options,
  required bool Function(T) isSelected,
  required String Function(T) leading,
  required String Function(T) titleOf,
  required String Function(T) subtitleOf,
  String Function(T)? trailing,
}) {
  return showModalBottomSheet<T>(
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
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 17, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.title.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final option in options) ...[
                    _OptionCard(
                      selected: isSelected(option),
                      leading: leading(option),
                      title: titleOf(option),
                      subtitle: subtitleOf(option),
                      trailing: trailing?.call(option),
                      onTap: () => Navigator.pop(sheetContext, option),
                    ),
                    if (option != options.last) const SizedBox(height: 8),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final bool selected;
  final String leading;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.wash,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.hairline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(leading, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.circleCheck,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
