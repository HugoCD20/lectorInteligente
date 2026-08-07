import 'package:flutter/material.dart';

import '../../config/strings.dart';
import '../../core/theme/app_theme.dart';

/// Campo de texto reutilizable con estilo consistente.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }
}

/// Validaciones reutilizables.
String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.requiredField;
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.requiredField;
  }
  final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!email.hasMatch(value.trim())) {
    return AppStrings.invalidEmail;
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return AppStrings.requiredField;
  }
  if (value.length < 8) {
    return AppStrings.shortPassword;
  }
  return null;
}
