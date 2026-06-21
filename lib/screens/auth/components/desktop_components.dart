import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/features/security_verification/presentation/widgets/security_verification_card.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';
import 'package:to_do_app/shared/widgets/stitch_shader_background.dart';
import 'package:to_do_app/widgets/auth/privacy_policy_dialog.dart';
import 'package:to_do_app/widgets/auth/auth_message_dialog.dart';

class DesktopInsightCard extends StatefulWidget {
  const DesktopInsightCard({super.key});

  @override
  State<DesktopInsightCard> createState() => _DesktopInsightCardState();
}

class _DesktopInsightCardState extends State<DesktopInsightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
        final double t = _controller.value * 2.0 * math.pi;
        final double dy = math.sin(t) * 10.0;
        final double angle = math.sin(t) * 0.0174; // Max 1 degree rotation

        return Transform.translate(
          offset: Offset(0, dy - 10.0),
          child: Transform.rotate(angle: angle, child: child),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(32.0),
        child: SizedBox(
          width: 448.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _IconPlaceholder(),
                  SizedBox(width: 16.0),
                  _InsightHeader(),
                ],
              ),
              SizedBox(height: 24.0),
              Text(
                '"The transition from manual workflow to Nexus was seamless. It\'s like having a neural expansion for my professional output."',
                style: getGeistStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w400,
                  color: RegisterColors.text,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.0),
              Row(
                children: [
                  _AvatarImage(),
                  SizedBox(width: 12.0),
                  _AuthorInfo(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPlaceholder extends StatelessWidget {
  const _IconPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: RegisterColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: RegisterColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: RegisterColors.primary,
          size: 20.0,
        ),
      ),
    );
  }
}

class _InsightHeader extends StatelessWidget {
  const _InsightHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI INSIGHT',
          style: getGeistStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: RegisterColors.primary,
          ),
        ),
        Text(
          'Precision redefined.',
          style: getGeistStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: RegisterColors.text,
          ),
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: RegisterColors.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(color: RegisterColors.glassStroke),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Image.network(
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA_a6f3ahMd7ElJQBrKmevbAgxGozjdkNl4Lxfk88OWFmS1N5w0ZWLtiQ0x_bgLp5ezGMWmxC7AyeOYomdEu1SkIqT6sG0eOAmQT9WVFx_aTXHF2KCcmyS7XGrwL3rjfhmNQTCYC94N_rss56j1TyJUZQpCmaxOcixDekbuTMmEPhzSrbxg99lpmCelX9exACfPK5Ufz7AbtuKYPo1-lfe7z1nph50P52tsaQbT1GRn0rv6fNQU9B3gkNcdKQxi4uXkuuQmvdh1wPFd',
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.person, color: RegisterColors.text),
        ),
      ),
    );
  }
}

class _AuthorInfo extends StatelessWidget {
  const _AuthorInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alex Rivera',
          style: getGeistMonoStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: RegisterColors.text,
          ),
        ),
        Text(
          'LEAD DEVELOPER, ORBITX',
          style: getGeistStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: RegisterColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class DesktopStatsSection extends StatelessWidget {
  const DesktopStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatItem('99.9%', 'UPTIME'),
        const SizedBox(width: 32.0),
        _buildStatItem('12ms', 'LATENCY'),
        const SizedBox(width: 32.0),
        _buildStatItem('E2E', 'ENCRYPTION'),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: getGeistMonoStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
            color: RegisterColors.primary,
          ),
        ),
        Text(
          label,
          style: getGeistStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: RegisterColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class DesktopBrandingPanel extends StatelessWidget {
  const DesktopBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StitchShaderBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(64.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nexus AI',
                      style: getGeistStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: RegisterColors.text,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Experience the frontier of boundless focus and intelligent productivity.',
                      style: getGeistStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: RegisterColors.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const DesktopInsightCard(),
                const DesktopStatsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DesktopRegisterForm extends StatefulWidget {
  const DesktopRegisterForm({
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
  State<DesktopRegisterForm> createState() => _DesktopRegisterFormState();
}

class _DesktopRegisterFormState extends State<DesktopRegisterForm> {
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

    if (password.length < 8) {
      _showSnack('Password must be at least 8 characters.');
      return;
    }

    final verificationResult = _verificationResult;
    if (verificationResult == null || !verificationResult.verified) {
      _showSnack('Please complete the security check.');
      return;
    }

    if (!_agreeTerms) {
      _showSnack('You must agree to the Terms of Service and Privacy Policy.');
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 512.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create your workspace',
                  style: getGeistStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w600,
                    color: RegisterColors.text,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      'Already have an account? ',
                      style: getGeistStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: RegisterColors.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onLogin,
                      child: Text(
                        'Sign in',
                        style: getGeistStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: RegisterColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
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
                    const SizedBox(width: 16.0),
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
                const SizedBox(height: 20.0),
                GlassInputField(
                  controller: _usernameController,
                  labelText: 'Username',
                  hintText: 'johndoe_ai',
                  prefixIcon: Icons.alternate_email_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20.0),
                GlassInputField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'john@nexus.ai',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20.0),
                ListenableBuilder(
                  listenable: _passwordController,
                  builder: (context, _) {
                    return Column(
                      children: [
                        GlassInputField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: '••••••••••••',
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12.0),
                        PasswordStrengthWidget(
                          password: _passwordController.text,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                GlassInputField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: '••••••••••••',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24.0),
                SecurityVerificationCard(
                  onChanged: (result) {
                    setState(() => _verificationResult = result);
                  },
                ),
                const SizedBox(height: 20.0),
                // Terms & Privacy Agreement
                GlassCheckbox(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                  label: RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: getGeistStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: RegisterColors.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: getGeistStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                            color: RegisterColors.primary,
                          ).copyWith(decoration: TextDecoration.underline),
                        ),
                        const TextSpan(text: ' and acknowledge the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: getGeistStyle(
                            fontSize: 14.0,
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
                  label: 'Create Account',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _handleSubmit,
                  loading: widget.loading,
                ),
                const SizedBox(height: 24.0),
                const DividerWithText(text: 'Or register with'),
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    Expanded(
                      child: SocialLoginButton(
                        label: 'Google',
                        type: 'google',
                        onPressed: () => widget.onSocialLogin('google'),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: SocialLoginButton(
                        label: 'Facebook',
                        type: 'facebook',
                        onPressed: () => widget.onSocialLogin('facebook'),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: SocialLoginButton(
                        label: 'GitHub',
                        type: 'github',
                        onPressed: () => widget.onSocialLogin('github'),
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
}
