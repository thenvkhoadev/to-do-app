import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/screens/blank_page.dart';
import 'package:to_do_app/screens/sign_up_page.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _LoginPage());
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width < 560 ? 24.0 : 32.0;

    return Stack(
      children: [
        const Positioned.fill(child: _AnimatedBackground()),
        const Positioned(
          top: -120,
          left: -120,
          child: _BackgroundBlob(size: 600, color: Color(0x12C0C1FF)),
        ),
        const Positioned(
          right: -120,
          bottom: -120,
          child: _BackgroundBlob(size: 600, color: Color(0x0DADC6FF)),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BrandHeader(),
                    SizedBox(height: 32),
                    _LoginCard(),
                    SizedBox(height: 32),
                    _FooterLinks(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF0D1322),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.05,
          colors: [Color(0xFF151B2B), Color(0xFF0D1322)],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC0C1FF), Color(0xFFDDB7FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26C0C1FF),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF1000A9),
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFFC0C1FF), Color(0xFFDDB7FF)],
              ).createShader(bounds),
          child: const Text(
            'NEXUS AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'DEEP WORK ACCESS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xCCC0C1FF),
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _signInFocusNode = FocusNode();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _signInFocusNode.dispose();
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
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const BlankPage()));
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          _AuthField(
            controller: _emailController,
            label: 'Email',
            hint: 'name@company.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: () => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_rounded,
            obscureText: _isPasswordHidden,
            focusNode: _passwordFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: () {
              _signInFocusNode.requestFocus();
              if (!_isLoading) _signIn();
            },
            topAction: 'Forgot password?',
            trailing: IconButton(
              onPressed:
                  () => setState(() => _isPasswordHidden = !_isPasswordHidden),
              icon: Icon(
                _isPasswordHidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFFC7C4D7),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _SignInButton(
            focusNode: _signInFocusNode,
            isLoading: _isLoading,
            onTap: _isLoading ? null : _signIn,
          ),
          const SizedBox(height: 20),
          const _DividerLabel(),
          const SizedBox(height: 20),
          const _SocialButtons(),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.topAction,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final String? topAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC7C4D7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (topAction != null)
                TextButton(
                  onHover: (_) {},
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC0C1FF),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    topAction!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: (_) => onSubmitted?.call(),
          obscureText: obscureText,
          style: const TextStyle(
            color: Color(0xFFDDE2F8),
            fontSize: 16,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0x80464554), fontSize: 16),
            prefixIcon: Icon(icon, color: const Color(0xFF908FA0), size: 22),
            suffixIcon: trailing,
            filled: true,
            fillColor: const Color(0xFF080E1D).withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x4D464554)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFC0C1FF),
                width: 1.3,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x4D464554)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.focusNode,
    required this.isLoading,
    required this.onTap,
  });

  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8083FF), Color(0xFF6F00BE)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x1AC0C1FF), blurRadius: 18),
          ],
        ),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          focusNode: focusNode,
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child:
                isLoading
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                    : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign in',
                          style: TextStyle(
                            color: Color(0xFF0D0096),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF0D0096),
                          size: 24,
                        ),
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
        Expanded(
          child: Divider(color: const Color(0xFF464554).withValues(alpha: 0.2)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: Color(0xFF464554),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: const Color(0xFF464554).withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons();

  @override
  Widget build(BuildContext context) {
    final stack = MediaQuery.sizeOf(context).width < 380;

    if (stack) {
      return const Column(
        children: [
          _SocialButton(label: 'Google', icon: _GoogleMark()),
          SizedBox(height: 8),
          _SocialButton(label: 'GitHub', icon: _GitHubMark()),
        ],
      );
    }

    return const Row(
      children: [
        Expanded(child: _SocialButton(label: 'Google', icon: _GoogleMark())),
        SizedBox(width: 8),
        Expanded(child: _SocialButton(label: 'GitHub', icon: _GitHubMark())),
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
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF2F3445).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF464554).withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDDE2F8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    return Image.network(
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDpCQZFSTBBulXROPYFearaXA6ngGtQ9-ry7ajMdSsU0toXNLoZPVujSnHKtOAJDjnzu5ga24jw5u4G-pw2_bEtz8z3AEUJ3uASUmYrQI-ErvVn0rKa-q2SGaPvSCiC3W0yELqivvIQ6g_IgxKb3_GZyrgX7bWTYYcy-CQZ1I9HrXw4JxKVEkWSnFMT-W_C8Oa6-mR-d3HMrxq3-2C_HgjEMD1LIMsc6NLyFHuRlVgkqrJiFjD2OeRYMArw-Ved5qe3i-2uku3_KvLL',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      errorBuilder:
          (_, __, ___) => const Icon(
            Icons.g_mobiledata_rounded,
            color: Color(0xFFDDE2F8),
            size: 20,
          ),
    );
  }
}

class _GitHubMark extends StatelessWidget {
  const _GitHubMark();

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://lh3.googleusercontent.com/aida/ADBb0ujwdgyV34o4oCm-aQwCOUOR694gdAxC9XtrTsWm-33XdUBT4Oeeqbbm3GUcRS61ESx9syc7PJUXFjGhETKn-vQm39AlI2wFJ-7otkqS_7x-DBM4nm7xNdisYELru2xAtg3mLgaSKcgy-BGCv9N5sQVe4s7nvUsu6YWvQ9h8Wvs0vSNKEOcF5_XU_TNcV3Bth3zhjwMex6Vrl_YDTBkvPUo4Zz8HXhQXYjbd9lwEda0e0RrOjBrlIjxdnV3w',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      errorBuilder:
          (_, __, ___) => const Icon(
            Icons.code_rounded,
            color: Color(0xFFDDE2F8),
            size: 20,
          ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                color: Color(0xFFC7C4D7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            TextButton(
              onHover: (_) {},
              onPressed:
                  () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const SignUpPage())),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC0C1FF),
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Sign up',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 8,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                color: Color(0xFF464554),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Status: All Systems Optimal',
              style: TextStyle(
                color: Color(0xFF464554),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  const _BackgroundBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 120)],
      ),
    );
  }
}
