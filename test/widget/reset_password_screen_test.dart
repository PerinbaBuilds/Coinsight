import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/screens/auth/reset_password_screen.dart';
import 'package:finance_tracker/theme/app_theme.dart';

Widget _wrap() => MaterialApp(
      theme: AppTheme.light,
      home: const ResetPasswordScreen(),
    );

void main() {
  group('ResetPasswordScreen — black-box widget tests', () {
    testWidgets('shows two password fields and Update button', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
      // Two password TextFields
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows error when fields are empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Please fill in both fields.'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(_wrap());
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'abc');
      await tester.enterText(fields.at(1), 'abc');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(_wrap());
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'pass123');
      await tester.enterText(fields.at(1), 'pass456');
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('password requirements hints are shown', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('At least 6 characters'), findsOneWidget);
      expect(find.text('Mix of letters and numbers recommended'), findsOneWidget);
    });
  });
}
