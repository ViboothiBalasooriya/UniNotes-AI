import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) context.go('/universities');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (mounted) context.go('/universities');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAsDemo({bool isAdmin = false}) async {
    setState(() => _isLoading = true);
    try {
      // 1. Set local demo providers FIRST so that if GoRouter redirects immediately
      // upon auth state change, the demo state is already active.
      ref.read(isDemoUserProvider.notifier).state = true;
      ref.read(isDemoAdminProvider.notifier).state = isAdmin;

      // 2. Sign in anonymously so Firestore 'isAuthenticated()' rules pass for reads.
      await ref.read(authNotifierProvider.notifier).signInAnonymously(isAdmin: false);
      
      if (mounted) context.go('/universities');
    } catch (e) {
      // Revert demo state on failure
      ref.read(isDemoUserProvider.notifier).state = false;
      ref.read(isDemoAdminProvider.notifier).state = false;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(

            content: Text('Demo Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ────────────────────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 24),
                Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access your academic resources.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),
                const SizedBox(height: 40),

                // ─── Email Field ───────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Password Field ────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // ─── Forgot Password ───────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(context),
                    child: const Text('Forgot password?', style: TextStyle(color: AppColors.primaryLight)),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Sign In Button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('login_btn'),
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Divider ───────────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Google Sign-In ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('google_signin_btn'),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: AppColors.primaryLight),
                    label: const Text('Continue with Google'),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Demo Mode Buttons ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _signInAsDemo(isAdmin: false),
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('Demo Student'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _signInAsDemo(isAdmin: true),
                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                        label: const Text('Demo Admin'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ─── Register Link ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Create one',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Enter your email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).sendPasswordReset(emailCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent!')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
