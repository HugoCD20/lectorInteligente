import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/providers.dart';
import '../../../config/routes.dart';
import '../../../config/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.home);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.welcomeBack,
      children: [
        AppTextField(
          controller: _emailController,
          label: AppStrings.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _passwordController,
          label: AppStrings.password,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: validateRequired,
          onFieldSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        LoadingButton(
          label: AppStrings.login,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.dontHaveAccount,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(Routes.register),
              child: const Text(AppStrings.register),
            ),
          ],
        ),
      ],
    );
  }
}
