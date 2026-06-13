import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';
import 'package:to_do_app/screens/auth/components/desktop_components.dart';
import 'package:to_do_app/screens/auth/components/mobile_components.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  bool _loading = false;

  Future<void> _handleRegister({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required ChallengeResult verificationResult,
  }) async {
    setState(() => _loading = true);

    try {
      if (!verificationResult.verified || verificationResult.challengeScore < 100) {
        _showError('Security check failed. Please verify again.');
        return;
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username},
      );
      final userId = response.user?.id;
      if (userId != null) {
        await _reportHumanVerification(userId, verificationResult);
        await ref.read(taskCreationProvider.notifier).seedUserData(userId);
      }
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: RegisterColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reportHumanVerification(
    String userId,
    ChallengeResult result,
  ) async {
    try {
      await Supabase.instance.client.from('human_verifications').insert({
        'user_id': userId,
        'verified': result.verified,
        'challenge_score': result.challengeScore,
        'challenge_type': result.challengeType,
        'completed_at': result.completedAt.toUtc().toIso8601String(),
        'payload': result.toJson(),
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[HumanVerification] Report skipped: $error');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RegisterColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegisterColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return DesktopRegisterLayout(
              onRegister: _handleRegister,
              onLogin: _navigateToLogin,
              loading: _loading,
            );
          }

          return MobileRegisterLayout(
            onRegister: _handleRegister,
            onLogin: _navigateToLogin,
            loading: _loading,
          );
        },
      ),
    );
  }
}

class DesktopRegisterLayout extends StatelessWidget {
  const DesktopRegisterLayout({
    required this.onRegister,
    required this.onLogin,
    this.loading = false,
    super.key,
  });

  final Future<void> Function({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required ChallengeResult verificationResult,
  })
  onRegister;
  final VoidCallback onLogin;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Branding & Shader (50%)
        const Expanded(child: DesktopBrandingPanel()),
        // Right Side: Registration Form (50%)
        Expanded(
          child: Container(
            color: RegisterColors.background,
            child: DesktopRegisterForm(
              onRegister: onRegister,
              onLogin: onLogin,
              loading: loading,
            ),
          ),
        ),
      ],
    );
  }
}

class MobileRegisterLayout extends StatelessWidget {
  const MobileRegisterLayout({
    required this.onRegister,
    required this.onLogin,
    this.loading = false,
    super.key,
  });

  final Future<void> Function({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required ChallengeResult verificationResult,
  })
  onRegister;
  final VoidCallback onLogin;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return MobileGlowBackground(
      child: Column(
        children: [
          // Fixed Top Navbar
          MobileNavbar(onLogin: onLogin),
          // Main Scrollable Area
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32.0),
                    MobileRegisterCard(
                      onRegister: onRegister,
                      onLogin: onLogin,
                      loading: loading,
                    ),
                    const SizedBox(height: 48.0),
                    // Footer section
                    const MobileFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
