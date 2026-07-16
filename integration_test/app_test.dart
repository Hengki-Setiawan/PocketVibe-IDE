import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pocketvibe_ide/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows onboarding', (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('PocketVibe IDE'), findsOneWidget);
  });

  testWidgets('Onboarding page can navigate to guide', (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    expect(find.text('Mulai Panduan Setup'), findsOneWidget);
  });
}
