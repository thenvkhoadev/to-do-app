import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/features/security_verification/presentation/widgets/security_verification_card.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';
import 'package:to_do_app/shared/widgets/stitch_shader_background.dart';
import 'package:to_do_app/widgets/auth/privacy_policy_dialog.dart';
import 'package:to_do_app/widgets/auth/auth_message_dialog.dart';

class MobileNavbar extends StatelessWidget {
  const MobileNavbar({required this.onLogin, super.key});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      decoration: const BoxDecoration(
        color: Color(0x990D1322), // bg-surface/60
        border: Border(
          bottom: BorderSide(color: RegisterColors.glassStroke, width: 1.0),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nexus AI',
                  style: getGeistStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: RegisterColors.text,
                  ),
                ),
                GestureDetector(
                  onTap: onLogin,
                  child: Text(
                    'Sign in',
                    style: getGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: RegisterColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileGlowBackground extends StatelessWidget {
  const MobileGlowBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebGL-style pulsing space shader background
        const Positioned.fill(child: StitchShaderBackground()),
        // Content on top
        Positioned.fill(child: child),
      ],
    );
  }
}

class MobileRegisterCard extends StatefulWidget {
  const MobileRegisterCard({
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
  State<MobileRegisterCard> createState() => _MobileRegisterCardState();
}

class _MobileRegisterCardState extends State<MobileRegisterCard> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ChallengeResult? _verificationResult;
  bool _agreeTerms = false;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyRecognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _privacyRecognizer.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatName(String name) {
    if (name.trim().isEmpty) return '';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  void _handleSubmit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showSnack('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match.');
      return;
    }

    final verificationResult = _verificationResult;
    if (verificationResult == null || !verificationResult.verified) {
      _showSnack('Please complete the security check.');
      return;
    }

    if (!_agreeTerms) {
      _showSnack('Please agree to terms.');
      return;
    }

    final formattedFirstName = _formatName(firstName);
    final formattedLastName = _formatName(lastName);
    final fullName = '$formattedFirstName $formattedLastName';

    widget.onRegister(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
      verificationResult: verificationResult,
    );
  }

  void _showSnack(String msg) {
    AuthMessageDialog.show(
      context: context,
      message: msg,
      title: 'Alert',
    );
  }

  Widget _buildSocialLoginRow() {
    return Row(
      children: [
        Expanded(
          child: SocialLoginButton(
            label: 'Google',
            type: 'google',
            onPressed: () => widget.onSocialLogin('google'),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: SocialLoginButton(
            label: 'GitHub',
            type: 'github',
            onPressed: () => widget.onSocialLogin('github'),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: SocialLoginButton(
            label: 'Facebook',
            type: 'facebook',
            onPressed: () => widget.onSocialLogin('facebook'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 28.0,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Create Account',
                  style: getGeistStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Unlock boundless focus with Nexus AI Intelligence.',
                  textAlign: TextAlign.center,
                  style: getGeistStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: RegisterColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
           _buildSocialLoginRow(),
          const SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: GlassInputField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  hintText: 'John',
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: GlassInputField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  hintText: 'Doe',
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          GlassInputField(
            controller: _usernameController,
            labelText: 'Username',
            hintText: 'johndoe_nexus',
            prefixIcon: Icons.alternate_email_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          GlassInputField(
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'john@nexus.ai',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          GlassInputField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          GlassInputField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: '••••••••',
            prefixIcon: Icons.lock_reset_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24.0),
          SecurityVerificationCard(
            onChanged: (result) {
              setState(() => _verificationResult = result);
            },
          ),
          const SizedBox(height: 16.0),
          // Terms & Conditions
          GlassCheckbox(
            value: _agreeTerms,
            onChanged: (v) => setState(() => _agreeTerms = v ?? false),
            label: RichText(
              text: TextSpan(
                text: 'I agree to the ',
                style: getGeistStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w400,
                  color: RegisterColors.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: getGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: RegisterColors.primary,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: getGeistStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: RegisterColors.primary,
                    ).copyWith(decoration: TextDecoration.underline),
                    recognizer: _privacyRecognizer
                      ..onTap = () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.72),
                          builder: (context) => const PrivacyPolicyDialog(),
                        );
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          GradientPrimaryButton(
            label: 'Initialize Account',
            onPressed: _handleSubmit,
            loading: widget.loading,
          ),
          const SizedBox(height: 24.0),
          const DividerWithText(text: 'or initialize with'),
          const SizedBox(height: 24.0),
          _buildSocialLoginRow(), // Social buttons rendered for the second time, exactly matching HTML
          const SizedBox(height: 32.0),
          Center(
            child: Column(
              children: [
                Text(
                  'Already registered?',
                  style: getGeistStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: RegisterColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4.0),
                GestureDetector(
                  onTap: widget.onLogin,
                  child: Text(
                    'Sign in here',
                    style: getGeistStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: RegisterColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: RegisterColors.primary.withValues(
                alpha: 0.3 * (1.0 - _controller.value),
              ),
              width: 1.0 + 3.0 * _controller.value,
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 8.0,
            height: 8.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: RegisterColors.primary,
            ),
          ),
        );
      },
    );
  }
}

class MobileFooter extends StatelessWidget {
  const MobileFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 48.0,
        bottom: 24.0,
        left: 24.0,
        right: 24.0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF080E1D), // bg-surface-container-lowest
        border: Border(
          top: BorderSide(color: RegisterColors.glassStroke, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nexus AI',
            style: getGeistStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.w900,
              color: RegisterColors.text,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            '© 2024 Nexus AI. Boundless Focus.',
            style: getGeistStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: RegisterColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40.0),
          // Footer Links Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFooterSection(context, 'Product', ['Features', 'Pricing']),
              ),
              Expanded(
                child: _buildFooterSection(context, 'Social', ['LinkedIn', 'GitHub']),
              ),
              Expanded(
                child: _buildFooterSection(context, 'Legal', ['Privacy', 'Terms']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context, String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: getGeistStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: RegisterColors.primary,
          ),
        ),
        const SizedBox(height: 16.0),
        ...links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () {
                if (link == 'Privacy') {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.72),
                    builder: (context) => const PrivacyPolicyDialog(),
                  );
                }
              },
              child: Text(
                link,
                style: getGeistStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: RegisterColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
