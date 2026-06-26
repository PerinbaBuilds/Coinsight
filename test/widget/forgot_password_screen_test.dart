import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finance_tracker/screens/auth/forgot_password_screen.dart';
import 'package:finance_tracker/services/auth_service.dart';
import 'package:finance_tracker/theme/app_theme.dart';

// Stub that does nothing — avoids real Supabase calls in widget tests.
class _FakeAuthService extends AuthService {
  bool resetCalled = false;
  String? lastEmail;
  Object? throwOn;

  @override
  Future<void> resetPassword(String email) async {
    resetCalled = true;
    lastEmail = email;
    if (throwOn != null) throw throwOn!;
  }
}

Widget _wrap(_FakeAuthService auth) => MultiProvider(
      providers: [ChangeNotifierProvider<AuthService>.value(value: auth)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ForgotPasswordScreen(),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock the shared_preferences platform channel so Supabase can initialize
    // without real platform plugins.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, Object>{};
        return null;
      },
    );
    await Supabase.initialize(
      url: 'https://test-project.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  group('ForgotPasswordScreen — black-box widget tests', () {
    testWidgets('shows email field and Send button', (tester) async {
      await tester.pumpWidget(_wrap(_FakeAuthService()));
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows error snackbar for empty email', (tester) async {
      await tester.pumpWidget(_wrap(_FakeAuthService()));
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error snackbar for email without @', (tester) async {
      final auth = _FakeAuthService();
      await tester.pumpWidget(_wrap(auth));
      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('calls resetPassword and shows success state on valid email',
        (tester) async {
      final auth = _FakeAuthService();
      await tester.pumpWidget(_wrap(auth));
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump(); // trigger async
      await tester.pump(); // settle

      expect(auth.resetCalled, true);
      expect(auth.lastEmail, 'user@example.com');
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.text('Resend Link'), findsOneWidget);
    });

    testWidgets('Resend Link button goes back to form', (tester) async {
      final auth = _FakeAuthService();
      await tester.pumpWidget(_wrap(auth));
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resend Link'));
      await tester.pumpAndSettle();
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('shows error snackbar when resetPassword throws', (tester) async {
      final auth = _FakeAuthService()..throwOn = Exception('Network error');
      await tester.pumpWidget(_wrap(auth));
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Error:'), findsOneWidget);
    });
  });
}
