import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:to_do_app/core/config/env.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';
import 'package:to_do_app/screens/auth/login/desktop/desktop_login_view.dart';
import 'package:to_do_app/screens/auth/login/mobile/mobile_login_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  ChallengeResult? _verificationResult;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  void _toggleRemember(bool? value) {
    setState(() {
      _rememberMe = value ?? false;
    });
  }

  void _handleVerificationChanged(ChallengeResult? result) {
    setState(() {
      _verificationResult = result;
    });
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    final verificationResult = _verificationResult;
    if (verificationResult == null || !verificationResult.verified) {
      _showMessage('Please complete the security check.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String resolvedEmail = email;
      if (!email.contains('@')) {
        final dio = Dio();
        final response = await dio.get(
          '${Env.javaApiUrl}/api/auth/resolve-email',
          queryParameters: {'identifier': email},
        );
        if (response.data != null && response.data['email'] != null) {
          resolvedEmail = response.data['email'] as String;
        }
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: resolvedEmail,
        password: password,
      );
      // Removed manual Navigator.pushReplacement. GoRouter will automatically
      // redirect the user to /home based on the auth session change.
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _handleSocialLogin(String provider) {
    _showMessage('Social login with $provider selected.');
  }

  void _handleForgotPassword() {
    _showMessage('Password recovery link requested.');
  }

  void _handleSignUp() {
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return DesktopLoginView(
              emailController: _emailController,
              passwordController: _passwordController,
              isPasswordHidden: _isPasswordHidden,
              rememberMe: _rememberMe,
              isLoading: _isLoading,
              onTogglePassword: _togglePassword,
              onToggleRemember: _toggleRemember,
              onSubmit: _handleSignIn,
              onSocialLogin: _handleSocialLogin,
              onRequestAccess: _handleSignUp,
              onForgotPassword: _handleForgotPassword,
              onVerificationChanged: _handleVerificationChanged,
            );
          }

          return MobileLoginView(
            emailController: _emailController,
            passwordController: _passwordController,
            isPasswordHidden: _isPasswordHidden,
            isLoading: _isLoading,
            onTogglePassword: _togglePassword,
            onSubmit: _handleSignIn,
            onSocialLogin: _handleSocialLogin,
            onForgotPassword: _handleForgotPassword,
            onSignUp: _handleSignUp,
            onPrivacyPolicy: () => _showMessage('Privacy Policy opened.'),
            onTermsOfService: () => _showMessage('Terms of Service opened.'),
            onVerificationChanged: _handleVerificationChanged,
          );
        },
      ),
    );
  }
}
