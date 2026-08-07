import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Botón con estado de carga integrado.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: AppSpacing.lg,
            height: AppSpacing.lg,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: child,
      );
    }
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: child,
    );
  }
}
