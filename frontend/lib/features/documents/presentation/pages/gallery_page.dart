import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../config/routes.dart';
import '../../../../config/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_navigation_bar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../../../features/translations/presentation/controllers/translation_controller.dart';
import '../../../../features/translations/domain/entities/translation.dart';
import '../../domain/entities/document.dart';
import '../controllers/documents_controller.dart';
import '../widgets/document_card.dart';
import '../widgets/document_uploader.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    ref.read(documentsControllerProvider.notifier).loadRecent();
    ref.read(documentsControllerProvider.notifier).loadGallery(refresh: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(documentsControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _upload() async {
    await pickAndUploadDocument(context, ref);
  }

  Future<void> _confirmDelete(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteDocument),
        content: const Text(AppStrings.deleteDocumentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(documentsControllerProvider.notifier).delete(document.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.documentDeleted)),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _confirmDeleteTranslation(
    Document document,
    TranslationSummary translation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteTranslation),
        content: const Text(AppStrings.deleteTranslationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(translationsControllerProvider.notifier)
          .delete(
            documentId: document.id,
            targetLanguage: translation.targetLanguage,
          );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.translationDeleted)),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openReader(Document document) {
    Navigator.of(context).pushNamed(Routes.reader, arguments: document);
  }

  Future<void> _translate(Document document) async {
    final translationsController = ref.read(translationsControllerProvider.notifier);
    if (ref.read(translationsControllerProvider).languages.isEmpty) {
      await translationsController.loadLanguages();
    }
    if (!mounted) return;

    final current = ref.read(translationsControllerProvider);
    final languages = current.languages;
    if (languages.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              current.languagesError ?? AppStrings.translationsUnavailable,
            ),
          ),
        );
      return;
    }

    final alreadyDone = document.translations
        .where((t) => t.status != 'failed')
        .map((t) => t.targetLanguage)
        .toSet();
    final available =
        languages.where((l) => !alreadyDone.contains(l.code)).toList();
    if (available.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.translationAvailable)));
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                AppStrings.selectLanguage,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            for (final language in available)
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: Text(
                  language.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  language.code.toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () => Navigator.of(sheetContext).pop(language.code),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (selected == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await translationsController.translate(
        documentId: document.id,
        targetLanguage: selected,
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.translationStarted)));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Document _withFreshTranslations(Document document, TranslationsState translations) {
    final fresh = translations.summariesFor(document.id);
    if (fresh.isEmpty) return document;
    return Document(
      id: document.id,
      originalName: document.originalName,
      extension: document.extension,
      mimeType: document.mimeType,
      fileSize: document.fileSize,
      fileUrl: document.fileUrl,
      createdAt: document.createdAt,
      translations: fresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final documents = ref.watch(documentsControllerProvider);
    final translations = ref.watch(translationsControllerProvider);

    return Scaffold(
      appBar: const AppNavigationBar(),
      floatingActionButton: auth.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: documents.uploading ? null : _upload,
              icon: documents.uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text(AppStrings.uploadDocument),
            )
          : null,
      body: SafeArea(
          child: auth.isAuthenticated
              ? _buildGallery(documents, translations)
              : _buildLoginRequired(),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.galleryLoginRequired,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LoadingButton(
              label: AppStrings.login,
              isOutlined: true,
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(DocumentsState documents, TranslationsState translations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.gallery,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppStrings.searchDocuments,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (documents.galleryError != null && documents.documents.isEmpty)
              _ErrorState(message: documents.galleryError!)
            else if (documents.loadingGallery && documents.documents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (documents.documents.isEmpty)
              _EmptyState(onUpload: _upload)
            else
              _DocumentsGrid(
                documents: documents,
                translations: translations,
                onDelete: _confirmDelete,
                onTranslate: _translate,
                onOpen: _openReader,
                onDeleteTranslation: _confirmDeleteTranslation,
                enrich: _withFreshTranslations,
                onLoadMore: () => ref
                    .read(documentsControllerProvider.notifier)
                    .loadGallery(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsGrid extends StatelessWidget {
  const _DocumentsGrid({
    required this.documents,
    required this.translations,
    required this.onDelete,
    required this.onTranslate,
    required this.onOpen,
    required this.onDeleteTranslation,
    required this.enrich,
    required this.onLoadMore,
  });

  final DocumentsState documents;
  final TranslationsState translations;
  final void Function(Document document) onDelete;
  final void Function(Document document) onTranslate;
  final void Function(Document document) onOpen;
  final void Function(Document document, TranslationSummary translation)
      onDeleteTranslation;
  final Document Function(Document document, TranslationsState translations)
      enrich;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 600
                    ? 2
                    : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.documents.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 2.4,
              ),
              itemBuilder: (context, index) {
                final document = enrich(documents.documents[index], translations);
                return DocumentCard(
                  document: document,
                  deleting: documents.deletingIds.contains(document.id),
                  translating:
                      translations.translatingIds.contains(document.id),
                  deletingTranslationKeys: translations.deletingIds,
                  onDelete: () => onDelete(document),
                  onTranslate: () => onTranslate(document),
                  onOpen: () => onOpen(document),
                  onDeleteTranslation: (translation) =>
                      onDeleteTranslation(document, translation),
                );
              },
            );
          },
        ),
        if (documents.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Center(
              child: documents.loadingGallery
                  ? const CircularProgressIndicator()
                  : OutlinedButton.icon(
                      onPressed: onLoadMore,
                      icon: const Icon(Icons.more_horiz),
                      label: const Text(AppStrings.loadMore),
                    ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.collections_bookmark_outlined,
            size: 72,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.emptyGallery,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LoadingButton(
            label: AppStrings.uploadDocument,
            isOutlined: true,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
