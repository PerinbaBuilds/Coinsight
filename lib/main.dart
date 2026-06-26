import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/finance_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect password recovery BEFORE Supabase.initialize() exchanges the PKCE code.
  // New PKCE flow: link lands on ?type=recovery&code=xxx (query param)
  // Legacy implicit flow: link lands on #type=recovery (fragment)
  final isPasswordRecovery = kIsWeb && (
    Uri.base.queryParameters['type'] == 'recovery' ||
    Uri.base.fragment.contains('type=recovery')
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FinanceService()),
      ],
      child: FinanceTrackerApp(isPasswordRecovery: isPasswordRecovery),
    ),
  );
}

class FinanceTrackerApp extends StatelessWidget {
  final bool isPasswordRecovery;
  const FinanceTrackerApp({super.key, this.isPasswordRecovery = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, finance, _) => MaterialApp(
        title: 'Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: finance.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: _AuthGate(isPasswordRecovery: isPasswordRecovery),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  final bool isPasswordRecovery;
  const _AuthGate({this.isPasswordRecovery = false});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _initialized = false;
  bool _isRecovery = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _isRecovery = widget.isPasswordRecovery;
    _init();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final supabase = Supabase.instance.client;

    // Always subscribe first — even in recovery mode we need signedOut to
    // reset _isRecovery; without this listener the user gets stuck on the
    // ResetPasswordScreen after changing their password.
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() { _isRecovery = true; _initialized = true; });
      } else if (data.event == AuthChangeEvent.signedOut) {
        setState(() => _isRecovery = false);
      } else if (data.event == AuthChangeEvent.signedIn ||
                 data.event == AuthChangeEvent.tokenRefreshed) {
        // Load finance data whenever a user session becomes active.
        // LoginScreen cannot reliably call loadData (widget may unmount first).
        if (!_isRecovery && data.session != null) {
          await context.read<FinanceService>().loadData();
        }
      }
    });

    // If URL flagged recovery, show reset screen immediately without waiting
    // for session restoration — Supabase will fire passwordRecovery via _authSub.
    if (_isRecovery) {
      if (mounted) setState(() => _initialized = true);
      return;
    }

    // On web, session restoration is async — wait for the first event,
    // but cap at 5 s so the splash never hangs on a bad network.
    if (supabase.auth.currentSession == null) {
      try {
        await supabase.auth.onAuthStateChange.first
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    if (!mounted) return;
    if (context.read<AuthService>().isLoggedIn && !_isRecovery) {
      await context.read<FinanceService>().loadData();
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecovery) return const ResetPasswordScreen();

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 64, color: AppTheme.navy),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppTheme.navy),
              SizedBox(height: 16),
              Text('Finance Tracker',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthService>();
    return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
