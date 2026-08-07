import 'package:flutter/material.dart';

/// Sistema de diseño consistente para toda la aplicación.
///
/// Colores, tipografías, tamaños y espaciados se centralizan aquí.
/// No se permiten valores mágicos dentro de los widgets.
abstract final class AppColors {
  static const Color primary = Color(0xFF1F6FEB);
  static const Color onPrimary = Colors.white;
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1B2A41);
  static const Color textSecondary = Color(0xFF5A6B7C);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1F6FEB);
}

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
    );
  }
}
