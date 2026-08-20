import 'package:flutter/material.dart';

import '../../core/constants/app_text_styles.dart';
import '../widgets/app_scaffold.dart';

/// Main dashboard screen placeholder.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard',
      padding: appScreenPadding,
      body: Center(
        child: Text(
          'Dashboard coming soon',
          style: AppTextStyles.bodySecondary,
        ),
      ),
    );
  }
}
