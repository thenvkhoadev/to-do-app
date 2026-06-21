import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/core/config/env.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';
import 'package:to_do_app/screens/auth/components/desktop_components.dart';
import 'package:to_do_app/screens/auth/components/mobile_components.dart';
import 'package:to_do_app/widgets/auth/email_verification_dialog.dart';
import 'package:to_do_app/widgets/auth/security_code_dialog.dart';
import 'package:to_do_app/widgets/auth/verification_success_dialog.dart';
import 'package:to_do_app/widgets/auth/auth_message_dialog.dart';

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

      // Reset loading state on form since we transition to dialog workflow
      setState(() => _loading = false);

      // Step 1: Open EmailVerificationDialog
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.72),
        builder: (dialogContext) => EmailVerificationDialog(
          onNext: () {
            // Close EmailVerificationDialog immediately
            Navigator.of(dialogContext).pop();

            // Step 2: Open SecurityCodeDialog immediately
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.72),
              builder: (otpContext) => SecurityCodeDialog(
                email: email,
                onVerified: (code) async {
                  try {
                    final dio = Dio();
                    final verifyResponse = await dio.post(
                      '${Env.javaApiUrl}/api/otp/verify',
                      data: {
                        'email': email,
                        'otp': code,
                        'purpose': 'SIGNUP',
                      },
                    );

                    final data = verifyResponse.data;
                    final isVerified = data['verified'] == true;

                    if (!isVerified) {
                      return "Invalid verification response from server.";
                    }

                    // OTP is valid. Now sign up via Supabase directly.
                    final authResponse = await Supabase.instance.client.auth.signUp(
                      email: email,
                      password: password,
                      data: {
                        'username': username,
                        'full_name': fullName,
                      },
                    );

                    final session = authResponse.session;
                    if (session != null) {
                      await ref.read(sessionStorageProvider).saveSession(session);
                    }

                    final userId = authResponse.user?.id;
                    if (userId != null) {
                      await _reportHumanVerification(userId, verificationResult);
                      await ref.read(taskCreationProvider.notifier).seedUserData(userId);
                    }

                    if (!otpContext.mounted) return null;

                    // Close SecurityCodeDialog
                    Navigator.of(otpContext).pop();

                    // Step 3: Open VerificationSuccessDialog
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.72),
                      builder: (successContext) => VerificationSuccessDialog(
                        onContinue: () {
                          Navigator.of(successContext).pop();
                          context.go('/login');
                        },
                      ),
                    );

                    return null;
                  } on DioException catch (dioError) {
                    final responseMessage = dioError.response?.data is Map
                        ? (dioError.response?.data['message'] ?? dioError.message)
                        : dioError.message;
                    return responseMessage ?? "Verification failed. Try again.";
                  } on AuthException catch (authError) {
                    return authError.message;
                  } catch (e) {
                    return e.toString();
                  }
                },
                onBack: () {
                  Navigator.of(otpContext).pop();
                },
                onResendOtp: () async {
                  final dio = Dio();
                  try {
                    await dio.post(
                      '${Env.javaApiUrl}/api/otp/send',
                      data: {
                        'email': email,
                        'purpose': 'SIGNUP',
                      },
                    );
                    if (mounted) {
                      AuthMessageDialog.show(
                        context: context,
                        message: "A new security code has been sent.",
                        title: "OTP Sent",
                        isError: false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      _showError("Failed to resend security code.");
                    }
                  }
                },
              ),
            );

            // Trigger OTP send in the background (fire-and-forget)
            final dio = Dio();
            dio.post(
              '${Env.javaApiUrl}/api/otp/send',
              data: {
                'email': email,
                'purpose': 'SIGNUP',
              },
            ).catchError((e) {
              if (mounted) {
                String errorMsg = "Failed to send verification key.";
                if (e is DioException) {
                  errorMsg = e.response?.data is Map
                      ? (e.response?.data['message'] ?? e.message ?? errorMsg)
                      : (e.message ?? errorMsg);
                }
                _showError(errorMsg);
              }
            });
          },
          onChangeEmail: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    } catch (error) {
      _showError(error.toString());
      setState(() => _loading = false);
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
    AuthMessageDialog.show(
      context: context,
      message: message,
      title: 'Error',
      isError: true,
    );
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _loading = true);
    try {
      OAuthProvider oAuthProvider;
      if (provider == 'google') {
        oAuthProvider = OAuthProvider.google;
      } else if (provider == 'github') {
        oAuthProvider = OAuthProvider.github;
      } else if (provider == 'facebook') {
        oAuthProvider = OAuthProvider.facebook;
      } else {
        throw Exception('Unsupported OAuth provider: $provider');
      }

      await Supabase.instance.client.auth.signInWithOAuth(
        oAuthProvider,
        redirectTo: kIsWeb 
            ? null 
            : 'com.example.to_do_app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
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
              onSocialLogin: _handleSocialLogin,
              loading: _loading,
            );
          }

          return MobileRegisterLayout(
            onRegister: _handleRegister,
            onLogin: _navigateToLogin,
            onSocialLogin: _handleSocialLogin,
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
    required this.onSocialLogin,
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
  final ValueChanged<String> onSocialLogin;
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
              onSocialLogin: onSocialLogin,
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
    required this.onSocialLogin,
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
  final ValueChanged<String> onSocialLogin;
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
                      onSocialLogin: onSocialLogin,
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
