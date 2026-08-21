import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fuel_log/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('onboarding leads to vehicle setup', (tester) async {
    await tester.pumpWidget(const FuelLogApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Track'), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);

    await tester.tap(find.text('GET STARTED'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Vehicle Name'), findsOneWidget);
    expect(find.text('Car'), findsOneWidget);
  });
}
