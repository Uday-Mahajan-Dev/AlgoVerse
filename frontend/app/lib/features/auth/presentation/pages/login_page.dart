import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/social_login_button.dart';
import '../../data/social_auth_service.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final role = await ref.read(authNotifierProvider.notifier).login(
            email: email,
            password: password,
          );

      if (!mounted) return;

      _navigateToDashboardForRole(role);
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // GOOGLE
  // ============================================================

  Future<void> _googleLogin() async {
    if (_isLoading) return;

    if (kIsWeb) {
      _showMessage('Please use Email & Password to log in on Web.');
      return;
    }

    await _socialLogin(SocialAuthService.signInWithGoogle);
  }

  // ============================================================
  // GITHUB
  // ============================================================

  Future<void> _githubLogin() async {
    if (_isLoading) return;

    if (kIsWeb) {
      _showMessage('Please use Email & Password to log in on Web.');
      return;
    }

    await _socialLogin(SocialAuthService.signInWithGitHub);
  }

  Future<void> _socialLogin(
    Future<Map<String, dynamic>> Function() loginMethod,
  ) async {
    if (kIsWeb) {
      _showMessage('Please use Email & Password to log in on Web.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final role = await ref.read(authNotifierProvider.notifier).socialLogin(
            loginMethod,
          );

      if (!mounted) return;

      _navigateToDashboardForRole(role);
    } on UnimplementedError {
      if (!mounted) return;
      _showMessage('Please use Email & Password to log in on Web.');
    } on UnsupportedError {
      if (!mounted) return;
      _showMessage('Please use Email & Password to log in on Web.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDashboardForRole(String role) {
    final upperRole = role.toUpperCase();
    if (upperRole == 'TEACHER') {
      context.go(AppRoutes.teacherDashboard);
    } else if (upperRole == 'ADMIN') {
      context.go(AppRoutes.admin);
    } else {
      context.go(AppRoutes.studentDashboard);
    }
  }


  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Welcome to AlgoVerse',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Learn DSA through stories, practice, and adaptive challenges.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // EMAIL
                  // ==================================================
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // GOOGLE
                  SocialLoginButton(
                    text: _isLoading
                        ? 'Please wait...'
                        : 'Continue with Google',
                    icon: Icons.g_mobiledata,
                    onPressed: _isLoading ? null : _googleLogin,
                  ),

                  const SizedBox(height: 12),

                  // GITHUB
                  SocialLoginButton(
                    text: _isLoading
                        ? 'Please wait...'
                        : 'Continue with GitHub',
                    icon: Icons.code,
                    onPressed: _isLoading ? null : _githubLogin,
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                context.push(AppRoutes.register);
                              },
                        child: const Text('Create account'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'By continuing, you agree to the AlgoVerse Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
