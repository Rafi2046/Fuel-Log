import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'app_app_bar.dart';

export 'app_app_bar.dart' show AppBackButton, AppAppBar;

/// Consistent dark scaffold with optional padded body.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: (title == null && titleWidget == null)
          ? null
          : AppAppBar(
              title: title,
              titleWidget: titleWidget,
              actions: actions,
              leading: leading,
              automaticallyImplyLeading: automaticallyImplyLeading,
            ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: padding == null
            ? body
            : Padding(padding: padding!, child: body),
      ),
    );
  }
}

/// Default screen edge padding helper.
EdgeInsets get appScreenPadding =>
    const EdgeInsets.all(AppSpacing.screenPadding);
