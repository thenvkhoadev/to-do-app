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
                      '${Env.javaApiUrl}/api/auth/verify-otp',
                      data: {
                        'email': email,
                        'otp': code,
                        'purpose': 'SIGNUP',
                        'deviceName': 'Flutter Client',
                        'deviceOs': Theme.of(otpContext).platform.name,
                        'ipAddress': '127.0.0.1',
                        'fullName': fullName,
                        'username': username,
                        'password': password,
                      },
                    );

                    final data = verifyResponse.data;
                    final accessToken = data['accessToken'] as String?;
                    final refreshToken = data['refreshToken'] as String?;
                    final userMap = data['user'];
                    final userId = userMap != null ? userMap['id'] as String? : null;

                    if (accessToken == null || refreshToken == null) {
                      return "Invalid verification response from server.";
                    }

                    // Recover Supabase session using the token returned by the Java backend
                    final sessionJson = jsonEncode({
                      'access_token': accessToken,
                      'refresh_token': refreshToken,
                      'expires_in': data['expiresIn'] ?? 86400,
                      'token_type': 'bearer',
                      'user': {
                        'id': userId,
                        'email': email,
                      },
                    });

                    final supabaseResponse = await Supabase.instance.client.auth.recoverSession(sessionJson);
                    final session = supabaseResponse.session;
                    if (session != null) {
                      await ref.read(sessionStorageProvider).saveSession(session);
                    }

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
                          context.go('/home');
                        },
                      ),
                    );

                    return null;
                  } on DioException catch (dioError) {
                    final responseMessage = dioError.response?.data is Map
                        ? (dioError.response?.data['message'] ?? dioError.message)
                        : dioError.message;
                    return responseMessage ?? "Authentication failed. Try again.";
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
                      '${Env.javaApiUrl}/api/auth/send-otp',
                      data: {
                        'email': email,
                        'purpose': 'SIGNUP',
                      },
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("A new security code has been sent."),
                          behavior: SnackBarBehavior.floating,
                        ),
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
              '${Env.javaApiUrl}/api/auth/send-otp',
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
