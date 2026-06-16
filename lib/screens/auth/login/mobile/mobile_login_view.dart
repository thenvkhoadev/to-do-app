import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';
import 'package:to_do_app/screens/auth/login/mobile/mobile_background.dart';
import 'package:to_do_app/screens/auth/login/mobile/mobile_header.dart';
import 'package:to_do_app/screens/auth/login/mobile/mobile_auth_card.dart';

class MobileLoginView extends StatelessWidget {
  const MobileLoginView({
    required this.emailController,
    required this.passwordController,
    required this.isPasswordHidden,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSocialLogin,
    required this.onForgotPassword,
    required this.onSignUp,
    required this.onPrivacyPolicy,
    required this.onTermsOfService,
    required this.onVerificationChanged,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordHidden;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSocialLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTermsOfService;
  final ValueChanged<ChallengeResult?> onVerificationChanged;

  @override
  Widget build(BuildContext context) {
    return MobileBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 16.0),
              const MobileHeader(),
              const SizedBox(height: 32.0),
              MobileAuthCard(
                emailController: emailController,
                passwordController: passwordController,
                isPasswordHidden: isPasswordHidden,
                isLoading: isLoading,
                onTogglePassword: onTogglePassword,
                onSubmit: onSubmit,
                onSocialLogin: onSocialLogin,
                onForgotPassword: onForgotPassword,
                onVerificationChanged: onVerificationChanged,
              ),
              const SizedBox(height: 32.0),
              Column(
                children: [
                  RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: getLoginGeistStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: LoginColors.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: getLoginGeistStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: LoginColors.primary,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = onSignUp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: onPrivacyPolicy,
                        child: Text(
                          'Privacy Policy',
                          style: getLoginGeistStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: LoginColors.outline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24.0),
                      GestureDetector(
                        onTap: onTermsOfService,
                        child: Text(
                          'Terms of Service',
                          style: getLoginGeistStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: LoginColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                  Opacity(
                    opacity: 0.4,
                    child: Text(
                      'Nexus AI • Version 2.4.0',
                      style: getLoginGeistStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: LoginColors.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
