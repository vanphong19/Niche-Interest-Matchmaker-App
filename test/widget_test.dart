import 'package:flutter_test/flutter_test.dart';

import 'package:niche_interest_matchmaker_app/app.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VibeApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('VibePulse'), findsOneWidget);
  });
}
