import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _user;

  User? get currentUser => _user;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.id;
  String? get userEmail => _user?.email;
  String get displayName =>
      _user?.userMetadata?['full_name'] ?? userEmail ?? 'User';

  AuthService() {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      // Supabase's web SDK can emit an event with a transiently null/stale
      // session right around sign-in, before the real session settles. If we
      // blindly copied data.session?.user every time, that transient event
      // could race with signIn()'s explicit assignment and flip _user back
      // to null right after a successful sign-in. Only signedOut should ever
      // clear _user; every other event should only update it when a real
      // user is present.
      if (data.event == AuthChangeEvent.signedOut) {
        // A signOut() call's broadcast event is asynchronous and can arrive
        // *after* a fast subsequent sign-in's own event, due to stream
        // ordering races. Blindly clearing _user here would wipe out a
        // brand-new session and bounce the user back to the login screen.
        // Only actually clear it if there's genuinely no active session by
        // the time this event is processed.
        if (_supabase.auth.currentSession == null) {
          _user = null;
        }
      } else if (data.session?.user != null) {
        _user = data.session!.user;
      }
      notifyListeners();
    });
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    // The SDK's currentUser/currentSession getters can lag behind the
    // returned response on web, so set state from the response directly
    // instead of waiting on onAuthStateChange to flip isLoggedIn.
    if (response.user != null) {
      _user = response.user;
      notifyListeners();
    }
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    _user = response.user;
    notifyListeners();
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
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
    final response = await _supabase.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
    if (response.user != null) _user = response.user;
    notifyListeners();
  }
}
