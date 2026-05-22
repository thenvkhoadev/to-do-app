import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/colors.dart';
import 'package:to_do_app/screens/blank_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          _SignUpBackground(),
          SafeArea(child: _SignUpContent()),
        ],
      ),
    );
  }
}

class _SignUpContent extends StatelessWidget {
  const _SignUpContent();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width >= 760 ? 48.0 : 16.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SignUpHeader(),
              SizedBox(height: 40),
              _SignUpCard(),
              SizedBox(height: 40),
              _LoginPrompt(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bubble_chart_rounded, color: NexusColors.primary, size: 32),
            SizedBox(width: 8),
            Text(
              'Nexus AI',
              style: TextStyle(
                color: NexusColors.onSurface,
                fontSize: 32,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Create your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Join the next generation of precision AI.',
          textAlign: TextAlign.center,
          style: TextStyle(color: NexusColors.outline, fontSize: 16, height: 1.6),
        ),
      ],
    );
  }
}

class _SignUpCard extends StatefulWidget {
  const _SignUpCard();

  @override
  State<_SignUpCard> createState() => _SignUpCardState();
}

class _SignUpCardState extends State<_SignUpCard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }
    if (!_acceptedTerms) {
      _showMessage('Please accept the terms first.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BlankPage()),
        );
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int _calculatePasswordStrength(String value) {
    if (value.isEmpty) return 0;

    var score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;

    if (score <= 1) return 1;
    if (score <= 3) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.sizeOf(context).width >= 760 ? 40.0 : 24.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          _SignUpTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Jane Doe',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _SignUpTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'jane@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _SignUpTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _isPasswordHidden,
            trailing: Icon(
              _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
            onTrailingPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
            onChanged: (value) => setState(() => _passwordStrength = _calculatePasswordStrength(value)),
          ),
          const SizedBox(height: 8),
          _PasswordStrengthBar(strength: _passwordStrength),
          const SizedBox(height: 16),
          _TermsCheckbox(
            value: _acceptedTerms,
            onChanged: (value) => setState(() => _acceptedTerms = value),
          ),
          const SizedBox(height: 24),
          _CreateAccountButton(isLoading: _isLoading, onTap: _isLoading ? null : _signUp),
          const SizedBox(height: 24),
          const _DividerText(),
          const SizedBox(height: 24),
          const _SecondaryOptions(),
        ],
      ),
    );
  }
}

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.onTrailingPressed,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final VoidCallback? onTrailingPressed;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(color: NexusColors.onSurface, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: NexusColors.outline.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: NexusColors.outline, size: 22),
            suffixIcon: trailing == null
                ? null
                : IconButton(
                    onPressed: onTrailingPressed,
                    color: NexusColors.outline,
                    icon: trailing!,
                  ),
            filled: true,
            fillColor: NexusColors.background.withOpacity(0.8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: NexusColors.outlineVariant.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: NexusColors.outlineVariant.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: NexusColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final activeColor = switch (strength) {
      1 => const Color(0xFFFFB4AB),
      2 => NexusColors.tertiary,
      3 => NexusColors.secondary,
      _ => NexusColors.surfaceContainerHighest,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Row(
        children: List.generate(3, (index) {
          final active = index < strength;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 4,
                color:
                    active
                        ? activeColor.withOpacity(0.75)
                        : NexusColors.surfaceContainerHighest.withOpacity(0.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Checkbox(
            value: value,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: NexusColors.primary,
            checkColor: NexusColors.onPrimary,
            side: const BorderSide(color: NexusColors.outline),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: NexusColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: NexusColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
              style: TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [NexusColors.primaryContainer, NexusColors.secondary],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: NexusColors.primaryContainer.withOpacity(0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NexusColors.surfaceLow,
                    ),
                  )
                else ...const [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      color: NexusColors.surfaceLow,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: NexusColors.surfaceLow, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: NexusColors.outlineVariant.withOpacity(0.3))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: NexusColors.outline,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(child: Divider(color: NexusColors.outlineVariant.withOpacity(0.3))),
      ],
    );
  }
}

class _SecondaryOptions extends StatelessWidget {
  const _SecondaryOptions();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;

    if (narrow) {
      return const Column(
        children: [
          _GhostButton(label: 'Google', icon: _GoogleMark()),
          SizedBox(height: 12),
          _GhostButton(label: 'GitHub', icon: Icon(Icons.code_rounded, size: 20)),
        ],
      );
    }

    return const Row(
      children: [
        Expanded(child: _GhostButton(label: 'Google', icon: _GoogleMark())),
        SizedBox(width: 16),
        Expanded(child: _GhostButton(label: 'GitHub', icon: Icon(Icons.code_rounded, size: 20))),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.icon});

  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NexusColors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 18, fontWeight: FontWeight.w800)),
          Positioned(right: 0, bottom: 2, child: Icon(Icons.circle, color: Color(0xFF34A853), size: 5)),
          Positioned(left: 1, bottom: 2, child: Icon(Icons.circle, color: Color(0xFFFBBC05), size: 5)),
          Positioned(right: 1, top: 1, child: Icon(Icons.circle, color: Color(0xFFEA4335), size: 4)),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 16),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: NexusColors.secondary,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: const Text(
            'Log In',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpBackground extends StatelessWidget {
  const _SignUpBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFF0F111A))),
        Positioned(
          top: -100,
          left: -100,
          child: _AmbientGlow(size: 600, color: NexusColors.primaryContainer.withOpacity(0.15)),
        ),
        Positioned(
          right: -50,
          bottom: -50,
          child: _AmbientGlow(size: 500, color: NexusColors.secondary.withOpacity(0.15)),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }
}
