import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/core/utils/validators.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/auth/presentation/widgets/auth_shell.dart';
import 'package:to_do_app/shared/widgets/nexus_gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = Validators.email(_emailController.text);
    final passwordError = Validators.password(_passwordController.text);
    if (emailError != null || passwordError != null) {
      _showMessage(emailError ?? passwordError!);
      return;
    }
    await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    final error = ref.read(authControllerProvider).error;
    if (error != null) _showMessage(error.toString());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Sign in to resume your focus system.',
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _hidePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
            ),
          ),
          const SizedBox(height: 22),
          NexusGradientButton(label: 'Sign in', icon: Icons.arrow_forward_rounded, isLoading: isLoading, onPressed: _submit),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => context.go('/signup'),
            child: const Text('Create a NexusAI account', style: TextStyle(color: NexusColors.primary)),
          ),
        ],
      ),
    );
  }
}
