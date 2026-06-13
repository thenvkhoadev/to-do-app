import 'package:flutter/material.dart';
import 'package:to_do_app/screens/auth/login/theme/login_theme.dart';

class GlassTextField extends StatelessWidget {
  const GlassTextField({
    required this.controller,
    required this.hintText,
    required this.labelText,
    required this.prefixIcon,
    this.isPassword = false,
    this.isPasswordHidden = true,
    this.onTogglePassword,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.suffixLabel,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isPasswordHidden;
  final VoidCallback? onTogglePassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Widget? suffixLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                labelText,
                style: getLoginGeistStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: LoginColors.onSurfaceVariant,
                ),
              ),
            ),
            if (suffixLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
                child: suffixLabel!,
              ),
          ],
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword && isPasswordHidden,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: getLoginGeistStyle(fontSize: 15.0, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: getLoginGeistStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
              color: LoginColors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: LoginColors.outline,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordHidden ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                      color: LoginColors.outline,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: const Color(0x990D1322), // rgba(13, 19, 34, 0.6)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: LoginColors.glassStroke, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: LoginColors.secondary, width: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
