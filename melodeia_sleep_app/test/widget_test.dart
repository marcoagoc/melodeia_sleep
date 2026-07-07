import 'package:flutter_test/flutter_test.dart';
import 'package:melodeia_sleep_app/app/melodeia_sleep_app.dart';
import 'package:melodeia_sleep_app/features/auth/firebase_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows session setup controls', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MelodeiaSleepApp(
        firebaseStatus: FirebaseBootstrapStatus(
          isReady: false,
          message: 'Test mode',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Melodeia Sleep'), findsOneWidget);
    expect(find.text('Tonight session'), findsOneWidget);
    expect(find.text('Start sleep session'), findsOneWidget);
  });
}
