import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/constants/app_spacing.dart';
import 'package:fuel_log/views/widgets/app_scaffold.dart';

void main() {
  test('AppBar-to-body gap is 16px on every screen', () {
    expect(AppSpacing.appBarBodyGap, AppSpacing.md);
    expect(appScreenPadding.top, AppSpacing.appBarBodyGap);
    expect(appScreenPadding.left, AppSpacing.screenPadding);
    expect(appScreenPadding.right, AppSpacing.screenPadding);
  });
}
