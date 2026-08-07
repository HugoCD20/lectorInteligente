import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/providers.dart';
import '../../config/routes.dart';
import '../../config/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';

/// Barra de navegación superior.
///
/// Se adapta al estado de autenticación: los usuarios autenticados ven las
/// opciones protegidas (galería, perfil) y los demás ven inicio de sesión y
/// registro.
class AppNavigationBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppNavigationBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final actions = <Widget>[];

    if (auth.isAuthenticated) {
      actions.addAll([
        _NavTextButton(
          label: AppStrings.home,
          onPressed: () => _navigate(context, Routes.home),
        ),
        _NavTextButton(
          label: AppStrings.gallery,
          onPressed: () => _navigate(context, Routes.gallery),
        ),
        _NavTextButton(
          label: AppStrings.profile,
          onPressed: () => _navigate(context, Routes.profile),
        ),
        IconButton(
          tooltip: AppStrings.logout,
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context, ref),
        ),
      ]);
    } else if (auth.status == AuthStatus.unauthenticated) {
      actions.addAll([
        _NavTextButton(
          label: AppStrings.login,
          onPressed: () => _navigate(context, Routes.login),
        ),
        _NavTextButton(
          label: AppStrings.register,
          onPressed: () => _navigate(context, Routes.register),
        ),
      ]);
    }

    return AppBar(
      title: InkWell(
        onTap: () => _navigate(context, Routes.home),
        child: Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      actions: actions,
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  void _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.sessionClosed)));
  }
}

class _NavTextButton extends StatelessWidget {
  const _NavTextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
