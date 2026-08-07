import 'package:flutter/material.dart';

import '../../config/strings.dart';
import '../../core/theme/app_theme.dart';

/// Página provisional para funcionalidades no implementadas.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.featurePlaceholder,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
