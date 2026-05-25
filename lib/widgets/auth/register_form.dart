import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/screens/blank_page.dart';
import 'package:to_do_app/theme/auth_theme.dart';
import 'package:to_do_app/widgets/auth/auth_text_field.dart';
import 'package:to_do_app/widgets/auth/gradient_button.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
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

    if (fullName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'username': username},
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const BlankPage()));
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final nameFields = widget.isDesktop
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
          GradientButton(label: 'Initialize Account', loading: _loading, onPressed: _loading ? null : _submit),
        ],
      ),
    );
  }
}
