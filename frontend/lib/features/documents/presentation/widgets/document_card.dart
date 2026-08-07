import 'package:flutter/material.dart';

import '../../../../config/strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/translations/domain/entities/translation.dart';
import '../../domain/entities/document.dart';

/// Tarjeta representativa de un documento en la galería.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    this.translating = false,
    this.deleting = false,
    this.deletingTranslationKeys = const {},
    this.onDelete,
    this.onTranslate,
    this.onOpen,
    this.onDeleteTranslation,
  });

  final Document document;
  final bool translating;
  final bool deleting;
  final Set<String> deletingTranslationKeys;
  final VoidCallback? onDelete;
  final VoidCallback? onTranslate;
  final VoidCallback? onOpen;
  final void Function(TranslationSummary translation)? onDeleteTranslation;

  @override
  Widget build(BuildContext context) {
    final isPdf = document.extension == 'pdf';
    final icon = isPdf ? Icons.picture_as_pdf_outlined : Icons.menu_book_outlined;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      document.originalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (translating)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (onTranslate != null)
                    IconButton(
                      tooltip: AppStrings.translate,
                      icon: const Icon(Icons.translate),
                      color: AppColors.primary,
                      onPressed: onTranslate,
                    ),
                  if (onDelete != null)
                    deleting
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: AppStrings.deleteDocument,
                            icon: const Icon(Icons.delete_outline),
                            color: Theme.of(context).colorScheme.error,
                            onPressed: onDelete,
                          ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${document.extension.toUpperCase()} • ${document.sizeLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (document.translations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final translation in document.translations)
                      _TranslationBadge(
                        translation: translation,
                        deleting: deletingTranslationKeys.contains(
                          _translationKey(document.id, translation.targetLanguage),
                        ),
                        onDelete: onDeleteTranslation == null ||
                                !translation.isTerminal
                            ? null
                            : () => onDeleteTranslation!(translation),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationBadge extends StatelessWidget {
  const _TranslationBadge({
    required this.translation,
    this.deleting = false,
    this.onDelete,
  });

  final TranslationSummary translation;
  final bool deleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(translation.status);
    return InkWell(
      onTap: onDelete,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '${translation.targetLanguage.toUpperCase()} • '
              '${_statusLabel(translation.status)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              deleting
                  ? SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      Icons.close,
                      size: 14,
                      color: color.withValues(alpha: 0.7),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

String _translationKey(int documentId, String targetLanguage) =>
    '$documentId:$targetLanguage';

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return AppColors.success;
    case 'partial':
      return AppColors.warning;
    case 'failed':
      return AppColors.danger;
    case 'processing':
      return AppColors.info;
    default:
      return AppColors.textSecondary;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'completed':
      return AppStrings.statusCompleted;
    case 'partial':
      return AppStrings.statusPartial;
    case 'failed':
      return AppStrings.statusFailed;
    case 'processing':
      return AppStrings.statusProcessing;
    default:
      return AppStrings.statusPending;
  }
}
