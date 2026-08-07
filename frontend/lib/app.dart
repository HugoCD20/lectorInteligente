import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/providers.dart';
import 'config/routes.dart';
import 'config/strings.dart';
import 'core/theme/app_theme.dart';

class LectorInteligenteApp extends StatelessWidget {
  const LectorInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppRoot());
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light(),
      initialRoute: Routes.home,
      onGenerateRoute: Routes.onGenerateRoute,
    );
  }
}
