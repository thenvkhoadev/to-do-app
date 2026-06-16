import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/features/security_verification/presentation/widgets/security_verification_card.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';
import 'package:to_do_app/screens/auth/login/widgets/glass_card.dart';
import 'package:to_do_app/screens/auth/login/widgets/glass_text_field.dart';
import 'package:to_do_app/screens/auth/login/widgets/social_button.dart';
import 'package:to_do_app/screens/auth/login/widgets/gradient_button.dart';
import 'package:to_do_app/screens/auth/login/widgets/section_divider.dart';

class DesktopAuthPanel extends StatelessWidget {
  const DesktopAuthPanel({
    required this.emailController,
    required this.passwordController,
    required this.isPasswordHidden,
    required this.rememberMe,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleRemember,
    required this.onSubmit,
    required this.onSocialLogin,
    required this.onRequestAccess,
    required this.onForgotPassword,
    required this.onVerificationChanged,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordHidden;
  final bool rememberMe;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onToggleRemember;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSocialLogin;
  final VoidCallback onRequestAccess;
  final VoidCallback onForgotPassword;
  final ValueChanged<ChallengeResult?> onVerificationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LoginColors.surface,
      child: Stack(
        children: [
          // Ambient Glow Behind Card (centered)
          Center(
            child: Container(
              width: 384.0,
              height: 384.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LoginColors.primary.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: LoginColors.primary.withValues(alpha: 0.08),
                    blurRadius: 120.0,
                    spreadRadius: 10.0,
                  ),
                ],
              ),
            ),
          ),
          // Scrollable Form Content & Centered Footer
          CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 460.0),
                        child: GlassCard(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In',
                                style: getLoginGeistStyle(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                'Enter your credentials to access your Nexus dashboard.',
                                style: getLoginGeistStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  color: LoginColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 32.0),
                              // Email Field
                              GlassTextField(
                                controller: emailController,
                                labelText: 'Email or Username',
                                hintText: 'e.g. neuro_coder',
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 24.0),
                              // Password Field with nested suffixLabel
                              GlassTextField(
                                controller: passwordController,
                                labelText: 'Password',
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isPasswordHidden: isPasswordHidden,
                                onTogglePassword: onTogglePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => onSubmit(),
                                suffixLabel: GestureDetector(
                                  onTap: onForgotPassword,
                                  child: Text(
                                    'Forgot password',
                                    style: getLoginGeistStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: LoginColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20.0),
                              SecurityVerificationCard(
                                onChanged: onVerificationChanged,
                              ),
                              const SizedBox(height: 14.0),
                              // Remember Me
                              Row(
                                children: [
                                  Theme(
                                    data: ThemeData(
                                      unselectedWidgetColor: LoginColors.glassStroke,
                                    ),
                                    child: Checkbox(
                                      value: rememberMe,
                                      onChanged: onToggleRemember,
                                      activeColor: LoginColors.primary,
                                      checkColor: LoginColors.background,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      side: const BorderSide(
                                        color: LoginColors.glassStroke,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      'Remember this device for 30 days',
                                      style: getLoginGeistStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w400,
                                        color: LoginColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22.0),
                              // Submit Button
                              GradientButton(
                                label: 'Sign In',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: onSubmit,
                                loading: isLoading,
                              ),
                              const SizedBox(height: 24.0),
                              // Divider
                              const SectionDivider(text: 'OR CONTINUE WITH'),
                              const SizedBox(height: 24.0),
                              // Social Row
                              Row(
                                children: [
                                  Expanded(
                                    child: SocialButton(
                                      type: 'google',
                                      onPressed: () => onSocialLogin('google'),
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: SocialButton(
                                      type: 'github',
                                      onPressed: () => onSocialLogin('github'),
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: SocialButton(
                                      type: 'facebook',
                                      onPressed: () => onSocialLogin('facebook'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24.0),
                              // Sign up link (Moved inside GlassCard to avoid footer overlaps)
                              Center(
                                child: RichText(
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
                                        recognizer: TapGestureRecognizer()..onTap = onRequestAccess,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
