import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/intercom_rider_role.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Premium role picker for driver, pillion, or group riding.
class IntercomRiderRoleSelector extends StatelessWidget {
  const IntercomRiderRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.compact = false,
  });

  final IntercomRiderRole selectedRole;
  final ValueChanged<IntercomRiderRole> onRoleChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            compact ? 'Your role' : 'How are you riding?',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ),
        CleanGlassPanel(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          padding: EdgeInsets.all(compact ? 8 : 10),
          child: Column(
            children: [
              for (var i = 0; i < IntercomRiderRole.values.length; i++) ...[
                _RoleTile(
                  role: IntercomRiderRole.values[i],
                  selected: selectedRole == IntercomRiderRole.values[i],
                  compact: compact,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRoleChanged(IntercomRiderRole.values[i]);
                  },
                ),
                if (i < IntercomRiderRole.values.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: compact ? 42 : 48,
                    color: AppColors.border.withValues(alpha: 0.55),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final IntercomRiderRole role;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  IconData get _icon => switch (role) {
        IntercomRiderRole.groupRider => Icons.groups_rounded,
        IntercomRiderRole.sameBikeDriver => Icons.two_wheeler_rounded,
        IntercomRiderRole.sameBikePillion => Icons.headphones_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : AppColors.cardElevated,
                ),
                child: Icon(
                  _icon,
                  size: compact ? 16 : 18,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: AppTextStyles.body.copyWith(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (!compact) ...[
                      SizedBox(height: 2),
                      Text(
                        role.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
