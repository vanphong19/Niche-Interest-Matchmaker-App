import 'package:flutter_test/flutter_test.dart';
import 'package:niche_interest_matchmaker_app/app.dart';
import 'package:niche_interest_matchmaker_app/injection/injection_container.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUpAll(() async {
    await GetIt.instance.reset();
    await configureDependencies();
  });

  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VibeApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('VibePulse'), findsOneWidget);

    // Wait for the 2-second navigation timer in SplashPage to complete
    await tester.pump(const Duration(seconds: 2));
  });
}
