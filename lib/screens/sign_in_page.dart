import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/constants/colors.dart';
import 'package:to_do_app/screens/blank_page.dart';
import 'package:to_do_app/screens/sign_up_page.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          _AuthBackground(),
          SafeArea(child: _AuthContent()),
        ],
      ),
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width >= 760 ? 48.0 : 16.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AuthLogoHeader(),
              SizedBox(height: 40),
              _AuthCard(),
              SizedBox(height: 40),
              _SignUpPrompt(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthLogoHeader extends StatelessWidget {
  const _AuthLogoHeader();

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
                fontSize: 48,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Welcome back. Please enter your details.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 18,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatefulWidget {
  const _AuthCard();

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 760 ? 40 : 24),
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
          _AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          _AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _isPasswordHidden,
            trailing: Icon(
              _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
            trailingLabel: 'Forgot Password?',
            onTrailingPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
          ),
          const SizedBox(height: 24),
          _PrimaryAuthButton(isLoading: _isLoading, onTap: _isLoading ? null : _signIn),
          const SizedBox(height: 24),
          const _DividerLabel(),
          const SizedBox(height: 24),
          const _SocialActions(),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.trailingLabel,
    this.onTrailingPressed,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final String? trailingLabel;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
            if (trailingLabel != null)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: NexusColors.primary,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  trailingLabel!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: NexusColors.onSurface, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: NexusColors.outline),
            prefixIcon: Icon(icon, color: NexusColors.outline, size: 20),
            suffixIcon: trailing == null
                ? null
                : IconButton(
                    onPressed: onTrailingPressed,
                    color: NexusColors.outline,
                    icon: trailing!,
                  ),
            filled: true,
            fillColor: NexusColors.surfaceContainerHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: NexusColors.outlineVariant.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: NexusColors.outlineVariant.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: NexusColors.primaryContainer.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({required this.isLoading, required this.onTap});

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
              blurRadius: 15,
              offset: const Offset(0, 4),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else ...const [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

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
              color: NexusColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: NexusColors.outlineVariant.withOpacity(0.3))),
      ],
    );
  }
}

class _SocialActions extends StatelessWidget {
  const _SocialActions();

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;

    if (isNarrow) {
      return const Column(
        children: [
          _SocialButton(label: 'Google', icon: _GoogleMark()),
          SizedBox(height: 12),
          _SocialButton(label: 'Apple', icon: Icon(Icons.apple_rounded, size: 20)),
        ],
      );
    }

    return const Row(
      children: [
        Expanded(child: _SocialButton(label: 'Google', icon: _GoogleMark())),
        SizedBox(width: 16),
        Expanded(child: _SocialButton(label: 'Apple', icon: Icon(Icons.apple_rounded, size: 20))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});

  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                      color: NexusColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 16),
        ),
        TextButton(
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignUpPage()),
              ),
          style: TextButton.styleFrom(
            foregroundColor: NexusColors.primary,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: NexusColors.background)),
        Positioned(
          left: -120,
          top: MediaQuery.sizeOf(context).height * 0.35,
          child: _GlowOrb(size: 360, color: NexusColors.primaryContainer.withOpacity(0.08)),
        ),
        Positioned(
          right: -100,
          top: MediaQuery.sizeOf(context).height * 0.12,
          child: _GlowOrb(size: 320, color: NexusColors.secondary.withOpacity(0.05)),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 80)],
      ),
    );
  }
}
