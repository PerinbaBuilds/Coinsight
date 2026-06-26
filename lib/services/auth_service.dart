import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;
  String get displayName =>
      currentUser?.userMetadata?['full_name'] ?? userEmail ?? 'User';

  AuthService() {
    _supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // onAuthStateChange doesn't always fire promptly on web right after
    // signInWithPassword resolves, so notify explicitly to flip isLoggedIn.
    notifyListeners();
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    String? redirectTo;
    if (kIsWeb) {
      final full = Uri.base.toString();
      // Strip fragment and existing query params to get clean base URL
      String base = full.contains('#') ? full.substring(0, full.indexOf('#')) : full;
      base = base.contains('?') ? base.substring(0, base.indexOf('?')) : base;
      if (!base.endsWith('/')) base = '$base/';
      // Append type=recovery so the app can detect the reset flow on redirect
      redirectTo = '${base}?type=recovery';
    }
    await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> updateProfile({String? fullName}) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
    notifyListeners();
  }
}
