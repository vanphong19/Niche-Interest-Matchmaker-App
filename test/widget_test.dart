import 'package:flutter_test/flutter_test.dart';

import 'package:niche_interest_matchmaker_app/app.dart';

void main() {
  testWidgets('App renders home scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Niche Interest Matchmaker'), findsOneWidget);
  });
}
