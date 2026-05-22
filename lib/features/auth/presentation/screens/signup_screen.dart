import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/core/utils/validators.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/auth/presentation/widgets/auth_shell.dart';
import 'package:to_do_app/shared/widgets/nexus_gradient_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _acceptedTerms = false;
  int _strength = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameError = Validators.requiredText(_nameController.text, 'Full name');
    final usernameError = Validators.requiredText(_usernameController.text, 'Username');
    final emailError = Validators.email(_emailController.text);
    final passwordError = Validators.password(_passwordController.text);
    if (nameError != null || usernameError != null || emailError != null || passwordError != null) {
      _showMessage(nameError ?? usernameError ?? emailError ?? passwordError!);
      return;
    }
    if (!_acceptedTerms) {
      _showMessage('Please accept the terms first.');
      return;
    }
    await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
        );
    final error = ref.read(authControllerProvider).error;
    if (error != null) _showMessage(error.toString());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  int _passwordStrength(String value) {
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
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthShell(
      title: 'Create account',
      subtitle: 'Join the next generation of precision productivity.',
      child: Column(
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 14),
          TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email_rounded))),
          const SizedBox(height: 14),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded))),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _hidePassword,
            onChanged: (value) => setState(() => _strength = _passwordStrength(value)),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _StrengthBar(strength: _strength),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: NexusColors.primary,
            title: const Text('I agree to the Terms of Service and Privacy Policy.', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 16),
          NexusGradientButton(label: 'Create account', icon: Icons.arrow_forward_rounded, isLoading: isLoading, onPressed: _submit),
          const SizedBox(height: 14),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Already have an account? Sign in')),
        ],
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final color = switch (strength) {
      1 => NexusColors.error,
      2 => NexusColors.tertiary,
      3 => NexusColors.secondary,
      _ => NexusColors.surfaceContainerHighest,
    };

    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: AnimatedContainer(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
            duration: const Duration(milliseconds: 180),
            height: 4,
            decoration: BoxDecoration(
              color: index < strength ? color : NexusColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}
