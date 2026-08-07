import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/providers.dart';
import '../../../config/routes.dart';
import '../../../config/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../../features/documents/domain/entities/document.dart';
import '../../../features/documents/presentation/widgets/document_uploader.dart';
import '../../../shared/widgets/app_navigation_bar.dart';

/// Página de inicio: muestra las funcionalidades principales del sistema.
///
/// Diseño responsivo: en pantallas amplias se usa una disposición de dos
/// columnas y en pantallas estrechas una disposición apilada.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    if (ref.read(authControllerProvider).isAuthenticated) {
      ref.read(documentsControllerProvider.notifier).loadRecent();
    }
  }

  Future<void> _uploadDocument() async {
    final document = await pickAndUploadDocument(context, ref);
    if (document != null && mounted) {
      Navigator.of(context).pushNamed(Routes.gallery);
    }
  }

  void _openGallery() {
    Navigator.of(context).pushNamed(Routes.gallery);
  }

  void _openDocument(Document document) {
    Navigator.of(context).pushNamed(Routes.reader, arguments: document);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        ref.read(documentsControllerProvider.notifier).loadRecent();
      }
    });
    final recent = ref.watch(documentsControllerProvider).recent;

    return Scaffold(
      appBar: const AppNavigationBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppSpacing.xxl * 14;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _HeroSection(
                            recent: recent,
                            onUpload: _uploadDocument,
                            onGallery: _openGallery,
                            onOpenDocument: _openDocument,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        const Expanded(
                          flex: 2,
                          child: _Illustration(),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Illustration(),
                        const SizedBox(height: AppSpacing.lg),
                        _HeroSection(
                          recent: recent,
                          onUpload: _uploadDocument,
                          onGallery: _openGallery,
                          onOpenDocument: _openDocument,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.recent,
    required this.onUpload,
    required this.onGallery,
    required this.onOpenDocument,
  });

  final List<Document> recent;
  final VoidCallback onUpload;
  final VoidCallback onGallery;
  final void Function(Document document) onOpenDocument;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.appTagline,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onUpload,
          icon: const Icon(Icons.upload_file),
          label: const Text(AppStrings.uploadDocument),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onGallery,
          icon: const Icon(Icons.collections_bookmark_outlined),
          label: const Text(AppStrings.openGallery),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppStrings.recentlyViewed,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recent.isEmpty)
          const _EmptyRecentCard()
        else
          _RecentList(recent: recent, onOpen: onOpenDocument),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.recent, required this.onOpen});

  final List<Document> recent;
  final void Function(Document document) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final document in recent.take(5))
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                document.originalName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                '${document.extension.toUpperCase()} • ${document.sizeLabel}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () => onOpen(document),
            ),
          ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: const Icon(
          Icons.menu_book_outlined,
          size: 96,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyRecentCard extends StatelessWidget {
  const _EmptyRecentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Text(
        AppStrings.recentEmptyHint,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
