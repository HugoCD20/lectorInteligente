import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/providers.dart';
import '../../../config/routes.dart';
import '../../../config/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
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
      title: AppStrings.createAccount,
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
          controller: _firstNameController,
          label: AppStrings.firstName,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _lastNameController,
          label: AppStrings.lastName,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _passwordController,
          label: AppStrings.password,
          obscureText: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: validatePassword,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _confirmPasswordController,
          label: AppStrings.confirmPassword,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.requiredField;
            }
            if (value != _passwordController.text) {
              return AppStrings.passwordMismatch;
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        LoadingButton(
          label: AppStrings.register,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.alreadyHaveAccount,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(Routes.login),
              child: const Text(AppStrings.login),
            ),
          ],
        ),
      ],
    );
  }
}
