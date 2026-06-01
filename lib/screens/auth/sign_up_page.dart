import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/theme/auth_theme.dart';
import 'package:to_do_app/widgets/auth/auth_header.dart';
import 'package:to_do_app/widgets/auth/footer_links.dart';
import 'package:to_do_app/widgets/auth/left_hero_section.dart';
import 'package:to_do_app/widgets/auth/register_form.dart';
import 'package:to_do_app/widgets/auth/social_login_buttons.dart';
import 'package:to_do_app/widgets/common/background_glow.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AuthTheme.dark(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < AuthBreakpoints.mobile;
          final isDesktop = width >= AuthBreakpoints.desktop;

          return Scaffold(
            backgroundColor: AuthColors.background,
            body: Stack(
              children: [
                BackgroundGlow(isDesktop: isDesktop),
                SafeArea(
                  child:
                      isDesktop
                          ? const Row(
                            children: [
                              Expanded(child: LeftHeroSection()),
                              Expanded(
                                child: _AuthPane(
                                  isDesktop: true,
                                  isMobile: false,
                                ),
                              ),
                            ],
                          )
                          : _AuthPane(isDesktop: false, isMobile: isMobile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthPane extends StatelessWidget {
  const _AuthPane({required this.isDesktop, required this.isMobile});

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        isDesktop ? AuthSpacing.containerMargin : AuthSpacing.gutter;

    return Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          isDesktop ? AuthSpacing.containerMargin : 16,
          horizontalPadding,
          32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDesktop) ...[
                  const AuthHeader(compact: true),
                  const SizedBox(height: 40),
                ],
                AuthTitle(
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  compact: isMobile,
                ),
                SizedBox(height: isDesktop ? AuthSpacing.stackLg : 40),
                const SocialLoginButtons(),
                SizedBox(height: isDesktop ? 24 : 32),
                const _EmailDivider(),
                SizedBox(height: isDesktop ? 24 : 32),
                RegisterForm(isDesktop: isDesktop),
                const SizedBox(height: 32),
                FooterLinks(
                  onLogin:
                      () =>
                          context.canPop()
                              ? context.pop()
                              : context.go('/login'),
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 32),
                  Container(
                    width: 64,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AuthColors.outlineVariant.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthTitle extends StatelessWidget {
  const AuthTitle({super.key, required this.textAlign, required this.compact});

  final TextAlign textAlign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final center = textAlign == TextAlign.center;
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Join the Future of ',
            children: [
              TextSpan(
                text: 'Focus',
                style: TextStyle(color: AuthColors.primary),
              ),
            ],
          ),
          textAlign: textAlign,
          style:
              compact
                  ? AuthTextStyles.headlineMobile
                  : AuthTextStyles.headlineLarge,
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: center ? 280 : 448),
          child: Text(
            'Synchronize your workflow with AI-driven precision.',
            textAlign: textAlign,
            style: AuthTextStyles.bodyMedium.copyWith(
              color: AuthColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailDivider extends StatelessWidget {
  const _EmailDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AuthColors.outlineVariant.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH EMAIL',
            style: AuthTextStyles.labelCaps.copyWith(
              color: AuthColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AuthColors.outlineVariant.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
      ],
    );
  }
}
