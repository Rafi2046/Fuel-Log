import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// Standard sleek back button with tactile rounded square container.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.padding = const EdgeInsets.only(left: 14),
  });

  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: InkWell(
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.control,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.controlBorder),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified, premium App bar with tactile back button and bottom surface divider.
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
    this.bottom,
    this.backgroundColor,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final double toolbarHeight;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;

  static const _dividerHeight = 1.0;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? _dividerHeight;
    return Size.fromHeight(toolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? Navigator.canPop(context);

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && automaticallyImplyLeading && canPop) {
      effectiveLeading = AppBackButton();
    }

    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      leading: effectiveLeading,
      leadingWidth: effectiveLeading != null ? 54 : null,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      titleSpacing: titleSpacing,
      backgroundColor: backgroundColor ?? AppColors.appBar,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bottom: bottom ??
          PreferredSize(
            preferredSize: Size.fromHeight(_dividerHeight),
            child: Container(
              height: _dividerHeight,
              color: AppColors.appBarDivider,
            ),
          ),
    );
  }
}
