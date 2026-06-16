import 'package:flutter/material.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/features/security_verification/presentation/widgets/security_verification_card.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';
import 'package:to_do_app/screens/auth/login/widgets/glass_card.dart';
import 'package:to_do_app/screens/auth/login/widgets/glass_text_field.dart';
import 'package:to_do_app/screens/auth/login/widgets/social_button.dart';
import 'package:to_do_app/screens/auth/login/widgets/gradient_button.dart';
import 'package:to_do_app/screens/auth/login/widgets/section_divider.dart';

class MobileAuthCard extends StatelessWidget {
  const MobileAuthCard({
    required this.emailController,
    required this.passwordController,
    required this.isPasswordHidden,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSocialLogin,
    required this.onForgotPassword,
    required this.onVerificationChanged,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordHidden;
  final bool rememberMe = false; // Mobile HTML does not have remember checkbox
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSocialLogin;
  final VoidCallback onForgotPassword;
  final ValueChanged<ChallengeResult?> onVerificationChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 28.0,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          GlassTextField(
            controller: emailController,
            labelText: 'Email or Username',
            hintText: 'name@nexus.ai',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          // Password field and Forgot row
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              ),
              const SizedBox(height: 4.0),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
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
            ],
          ),
          const SizedBox(height: 20.0),
          SecurityVerificationCard(
            onChanged: onVerificationChanged,
          ),
          const SizedBox(height: 24.0),
          // Sign In Button
          GradientButton(
            label: 'Sign In',
            onPressed: onSubmit,
            loading: isLoading,
          ),
          const SizedBox(height: 24.0),
          // Divider
          const SectionDivider(text: 'OR CONTINUE WITH'),
          const SizedBox(height: 24.0),
          // Google Full-Width Social Button
          SocialButton(
            label: 'Google',
            type: 'google',
            onPressed: () => onSocialLogin('google'),
          ),
          const SizedBox(height: 12.0),
          // GitHub and Meta row
          Row(
            children: [
              Expanded(
                child: SocialButton(
                  label: 'GitHub',
                  type: 'github',
                  onPressed: () => onSocialLogin('github'),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: SocialButton(
                  label: 'Meta',
                  type: 'facebook',
                  onPressed: () => onSocialLogin('facebook'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
