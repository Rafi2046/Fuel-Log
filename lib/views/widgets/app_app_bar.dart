import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// App bar with visible surface separation from the body.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.toolbarHeight = kToolbarHeight,
    this.titleSpacing,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final double toolbarHeight;
  final double? titleSpacing;

  static const _dividerHeight = 1.0;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight + _dividerHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      titleSpacing: titleSpacing,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.title,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_dividerHeight),
        child: Container(
          height: _dividerHeight,
          color: AppColors.border,
        ),
      ),
    );
  }
}
