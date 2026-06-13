import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/desktop/desktop_brand_panel.dart';
import 'package:to_do_app/screens/auth/login/desktop/desktop_auth_panel.dart';

class DesktopLoginView extends StatelessWidget {
  const DesktopLoginView({
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left branding panel (50% width)
        const Expanded(
          child: DesktopBrandPanel(),
        ),
        // Right login form panel (50% width)
        Expanded(
          child: DesktopAuthPanel(
            emailController: emailController,
            passwordController: passwordController,
            isPasswordHidden: isPasswordHidden,
            rememberMe: rememberMe,
            isLoading: isLoading,
            onTogglePassword: onTogglePassword,
            onToggleRemember: onToggleRemember,
            onSubmit: onSubmit,
            onSocialLogin: onSocialLogin,
            onRequestAccess: onRequestAccess,
            onForgotPassword: onForgotPassword,
          ),
        ),
      ],
    );
  }
}
