import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPass.isEmpty || confirm.isEmpty) {
      _err('Please fill in both fields.');
      return;
    }
    if (newPass.length < 6) {
      _err('Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirm) {
      _err('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: newPass));
      // Show snackbar before signOut so it appears on the root ScaffoldMessenger
      // and persists when _AuthGate transitions back to LoginScreen.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated! Sign in with your new password.'),
            backgroundColor: AppTheme.emerald,
            duration: Duration(seconds: 4),
          ),
        );
      }
      // signOut fires the signedOut event → _AuthGate resets _isRecovery = false
      // and naturally shows LoginScreen. No manual Navigator push needed.
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      if (mounted) _err(e.message);
    } catch (e) {
      if (mounted) _err('Failed to update password. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.rose),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Icon — same style as login logo
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: AppTheme.primary, size: 38),
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Set New Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a strong password for your account.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // New password
              _PasswordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 14),

              // Confirm password
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                onSubmitted: (_) => _update(),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _update,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Password requirements hint
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password requirements:',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    _Req(text: 'At least 6 characters'),
                    _Req(text: 'Mix of letters and numbers recommended'),
                    _Req(text: 'Avoid using your name or email'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, duration: 350.ms),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofillHints: const [AutofillHints.newPassword],
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(Icons.lock_outline_rounded,
              color: AppTheme.textSecondary, size: 20),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final String text;
  const _Req({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 13, color: AppTheme.emerald),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
