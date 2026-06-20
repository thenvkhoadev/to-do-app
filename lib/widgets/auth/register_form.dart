import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/config/env.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/theme/auth_theme.dart';
import 'package:to_do_app/widgets/auth/auth_text_field.dart';
import 'package:to_do_app/widgets/auth/gradient_button.dart';
import 'package:to_do_app/widgets/auth/email_verification_dialog.dart';
import 'package:to_do_app/widgets/auth/security_code_dialog.dart';
import 'package:to_do_app/widgets/auth/verification_success_dialog.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    // Step 1: Open EmailVerificationDialog
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (dialogContext) => EmailVerificationDialog(
        onNext: () async {
          // Trigger OTP send via Java backend
          try {
            final dio = Dio();
            await dio.post(
              '${Env.javaApiUrl}/api/auth/send-otp',
              data: {
                'email': email,
                'purpose': 'SIGNUP',
              },
            );

            if (!mounted) return;

            // Close EmailVerificationDialog
            Navigator.of(dialogContext).pop();

            // Step 2: Open SecurityCodeDialog
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.72),
              builder: (otpContext) => SecurityCodeDialog(
                email: email,
                onVerified: (code) async {
                  // Verify OTP via Java backend
                  try {
                    final verifyResponse = await dio.post(
                      '${Env.javaApiUrl}/api/auth/verify-otp',
                      data: {
                        'email': email,
                        'otp': code,
                        'purpose': 'SIGNUP',
                        'deviceName': 'Flutter Client',
                        'deviceOs': Theme.of(context).platform.name,
                        'ipAddress': '127.0.0.1',
                        'fullName': fullName,
                        'username': username,
                        'password': password,
                      },
                    );

                    final data = verifyResponse.data;
                    final accessToken = data['accessToken'] as String?;
                    final refreshToken = data['refreshToken'] as String?;
                    final userMap = data['user'];
                    final userId = userMap != null ? userMap['id'] as String? : null;

                    if (accessToken == null || refreshToken == null) {
                      return "Invalid verification response from server.";
                    }

                    // Recover Supabase session using the token returned by the Java backend
                    final sessionJson = jsonEncode({
                      'access_token': accessToken,
                      'refresh_token': refreshToken,
                      'expires_in': data['expiresIn'] ?? 86400,
                      'token_type': 'bearer',
                      'user': {
                        'id': userId,
                        'email': email,
                      },
                    });

                    final supabaseResponse = await Supabase.instance.client.auth.recoverSession(sessionJson);
                    final session = supabaseResponse.session;
                    if (session != null) {
                      // Save to secure local storage session keys
                      await ref.read(sessionStorageProvider).saveSession(session);
                    }

                    // Seed user database task items
                    if (userId != null) {
                      await ref.read(taskCreationProvider.notifier).seedUserData(userId);
                    }

                    if (!otpContext.mounted) return null;

                    // Close SecurityCodeDialog
                    Navigator.of(otpContext).pop();

                    // Step 3: Open VerificationSuccessDialog
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.72),
                      builder: (successContext) => VerificationSuccessDialog(
                        onContinue: () {
                          Navigator.of(successContext).pop();
                          // Navigate to home dashboard
                          context.go('/home');
                        },
                      ),
                    );

                    return null; // Success indication
                  } on DioException catch (dioError) {
                    final responseMessage = dioError.response?.data is Map
                        ? (dioError.response?.data['message'] ?? dioError.message)
                        : dioError.message;
                    return responseMessage ?? "Authentication failed. Try again.";
                  } catch (e) {
                    return e.toString();
                  }
                },
                onBack: () {
                  Navigator.of(otpContext).pop();
                },
                onResendOtp: () async {
                  final dio = Dio();
                  try {
                    await dio.post(
                      '${Env.javaApiUrl}/api/auth/send-otp',
                      data: {
                        'email': email,
                        'purpose': 'SIGNUP',
                      },
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("A new security code has been sent."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      _showMessage("Failed to resend security code.");
                    }
                  }
                },
              ),
            );
          } on DioException catch (dioError) {
            final responseMessage = dioError.response?.data is Map
                ? (dioError.response?.data['message'] ?? dioError.message)
                : dioError.message;
            _showMessage(responseMessage ?? "Failed to send verification key.");
          } catch (e) {
            _showMessage(e.toString());
          }
        },
        onChangeEmail: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final nameFields =
        widget.isDesktop
            ? Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                  ),
                ),
                const SizedBox(width: AuthSpacing.stackMd),
                Expanded(
                  child: AuthTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'johndoe_ai',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                  ),
                ),
              ],
            )
            : Column(
              children: [
                AuthTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AuthSpacing.stackMd),
                AuthTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'johndoe_ai',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                ),
              ],
            );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          nameFields,
          const SizedBox(height: AuthSpacing.stackMd),
          AuthTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AuthSpacing.stackMd),
          PasswordField(controller: _passwordController),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Initialize Account',
            loading: _loading,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
