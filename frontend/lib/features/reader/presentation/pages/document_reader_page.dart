import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../../../config/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/documents/domain/entities/document.dart';
import '../controllers/reader_controller.dart';

/// Página del lector de documentos.
///
/// En escritorio muestra el original y su traducción lado a lado; en móvil
/// los apila (original y traducción de la página actual).
class DocumentReaderPage extends ConsumerStatefulWidget {
  const DocumentReaderPage({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<DocumentReaderPage> createState() => _DocumentReaderPageState();
}

class _DocumentReaderPageState extends ConsumerState<DocumentReaderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(readerControllerProvider.notifier).open(
            documentId: widget.document.id,
            documentName: widget.document.originalName,
            translations: widget.document.translations,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reader = ref.watch(readerControllerProvider);
    final current = reader.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          reader.documentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (reader.availableLanguages.isNotEmpty) _buildLanguageSelector(reader),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(child: _buildBody(reader, current)),
      bottomNavigationBar: reader.totalPages > 0
          ? _PageNavigator(
              reader: reader,
              onPrevious: () => ref
                  .read(readerControllerProvider.notifier)
                  .previousPage(),
              onNext: () =>
                  ref.read(readerControllerProvider.notifier).nextPage(),
            )
          : null,
    );
  }

  Widget _buildLanguageSelector(ReaderState reader) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: reader.targetLanguage,
          iconEnabledColor: AppColors.primary,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                AppStrings.readerOriginalOnly,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            for (final code in reader.availableLanguages)
              DropdownMenuItem<String?>(
                value: code,
                child: Text(
                  code.toUpperCase(),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
          ],
          onChanged: (value) => ref
              .read(readerControllerProvider.notifier)
              .setTargetLanguage(value),
        ),
      ),
    );
  }

  Widget _buildBody(ReaderState reader, dynamic current) {
    if (current == null) {
      if (reader.error != null && !reader.loading) {
        return _ErrorState(
          message: reader.error!,
          onRetry: () =>
              ref.read(readerControllerProvider.notifier).retry(),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final original = _ReadingPane(
          title: AppStrings.readerOriginal,
          text: current.originalContent,
        );
        if (!wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  original,
                  if (reader.hasTranslation) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _ReadingPane(
                      title:
                          '${AppStrings.readerTranslation} (${reader.targetLanguage!.toUpperCase()})',
                      text: current.translatedContent ?? '',
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: original),
            const VerticalDivider(width: 1),
            Expanded(
              child: reader.hasTranslation
                  ? _ReadingPane(
                      title:
                          '${AppStrings.readerTranslation} (${reader.targetLanguage!.toUpperCase()})',
                      text: current.translatedContent ?? '',
                    )
                  : const _NoTranslationPane(),
            ),
          ],
        );
      },
    );
  }
}

class _ReadingPane extends StatelessWidget {
  const _ReadingPane({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  text.isEmpty
                      ? AppStrings.readerEmptyPage
                      : text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTranslationPane extends StatelessWidget {
  const _NoTranslationPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.readerNoTranslation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageNavigator extends StatelessWidget {
  const _PageNavigator({
    required this.reader,
    required this.onPrevious,
    required this.onNext,
  });

  final ReaderState reader;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: AppStrings.readerPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: reader.hasPrevious ? onPrevious : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                AppStrings.readerPageOf(reader.currentPage, reader.totalPages),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                tooltip: AppStrings.readerNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: reader.hasNext ? onNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
