import 'package:flutter_test/flutter_test.dart';

// Unit tests for AuthService logic that doesn't require a live Supabase connection.
// Integration tests (actual sign-in / sign-up) should be run against a local
// Supabase dev stack or Supabase Test Helpers.

void main() {
  group('Password validation rules (mirrored in ResetPasswordScreen)', () {
    bool isValidPassword(String pass, String confirm) {
      if (pass.isEmpty || confirm.isEmpty) return false;
      if (pass.length < 6) return false;
      if (pass != confirm) return false;
      return true;
    }

    test('rejects empty fields', () {
      expect(isValidPassword('', ''), false);
      expect(isValidPassword('abc123', ''), false);
    });

    test('rejects passwords shorter than 6 chars', () {
      expect(isValidPassword('abc', 'abc'), false);
    });

    test('rejects mismatched passwords', () {
      expect(isValidPassword('abc123', 'abc456'), false);
    });

    test('accepts matching passwords of 6+ chars', () {
      expect(isValidPassword('secret1', 'secret1'), true);
      expect(isValidPassword('Str0ng!Pass', 'Str0ng!Pass'), true);
    });
  });

  group('Email validation (mirrored in ForgotPasswordScreen)', () {
    bool isValidEmail(String email) =>
        email.trim().isNotEmpty && email.contains('@');

    test('rejects empty email', () => expect(isValidEmail(''), false));
    test('rejects email without @', () => expect(isValidEmail('notanemail'), false));
    test('accepts valid email', () => expect(isValidEmail('user@example.com'), true));
  });

  group('redirectTo origin builder', () {
    // Mirrors the logic in auth_service.dart _currentOrigin helper
    String buildOrigin(String scheme, String host, int port) {
      final portStr = port != 0 && port != 80 && port != 443 ? ':$port' : '';
      return '$scheme://$host$portStr';
    }

    test('omits standard HTTPS port', () {
      expect(buildOrigin('https', 'example.com', 443), 'https://example.com');
    });

    test('omits standard HTTP port', () {
      expect(buildOrigin('http', 'localhost', 80), 'http://localhost');
    });

    test('includes non-standard port', () {
      expect(buildOrigin('http', 'localhost', 3000), 'http://localhost:3000');
    });
  });
}
