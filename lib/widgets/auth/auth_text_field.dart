import 'package:flutter/material.dart';
import 'package:to_do_app/theme/auth_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: AuthTextStyles.labelSmall.copyWith(
                    color:
                        focused
                            ? AuthColors.primary
                            : AuthColors.onSurfaceVariant,
                  ),
                  child: Text(label),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      focused
                          ? [
                            BoxShadow(
                              color: AuthColors.primary.withValues(alpha: 0.15),
                              blurRadius: 30,
                            ),
                          ]
                          : null,
                ),
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  autofillHints: autofillHints,
                  obscureText: obscureText,
                  style: AuthTextStyles.bodyMedium,
                  cursorColor: AuthColors.primary,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AuthTextStyles.bodyMedium.copyWith(
                      color: AuthColors.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    suffixIcon: suffixIcon,
                    suffixIconColor: AuthColors.onSurfaceVariant.withValues(
                      alpha: 0.55,
                    ),
                    filled: true,
                    fillColor: AuthColors.surfaceContainerLow.withValues(
                      alpha: 0.5,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: _border(
                      AuthColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                    enabledBorder: _border(
                      AuthColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                    focusedBorder: _border(
                      AuthColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      controller: widget.controller,
      label: 'Password',
      hint: '••••••••',
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        tooltip: _obscure ? 'Show password' : 'Hide password',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
        ),
      ),
    );
  }
}
