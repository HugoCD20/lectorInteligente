import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/translation.dart';
import '../../domain/repositories/translation_repository.dart';

/// Estado de las traducciones.
class TranslationsState {
  const TranslationsState({
    this.languages = const [],
    this.loadingLanguages = false,
    this.languagesError,
    this.summariesByDocument = const {},
    this.translatingIds = const {},
    this.deletingIds = const {},
    this.error,
  });

  final List<TranslationLanguage> languages;
  final bool loadingLanguages;
  final String? languagesError;
  final Map<int, List<TranslationSummary>> summariesByDocument;
  final Set<int> translatingIds;
  final Set<String> deletingIds;
  final String? error;

  List<TranslationSummary> summariesFor(int documentId) =>
      summariesByDocument[documentId] ?? const [];

  bool isDeleting(int documentId, String targetLanguage) =>
      deletingIds.contains(_translationKey(documentId, targetLanguage));

  TranslationsState copyWith({
    List<TranslationLanguage>? languages,
    bool? loadingLanguages,
    String? languagesError,
    Map<int, List<TranslationSummary>>? summariesByDocument,
    Set<int>? translatingIds,
    Set<String>? deletingIds,
    String? error,
  }) {
    return TranslationsState(
      languages: languages ?? this.languages,
      loadingLanguages: loadingLanguages ?? this.loadingLanguages,
      languagesError: languagesError ?? this.languagesError,
      summariesByDocument:
          summariesByDocument ?? this.summariesByDocument,
      translatingIds: translatingIds ?? this.translatingIds,
      deletingIds: deletingIds ?? this.deletingIds,
      error: error ?? this.error,
    );
  }
}

String _translationKey(int documentId, String targetLanguage) =>
    '$documentId:$targetLanguage';

/// Controlador de traducciones.
class TranslationsController extends StateNotifier<TranslationsState> {
  TranslationsController({required this.repository})
      : super(const TranslationsState());

  final TranslationRepository repository;
  final Set<int> _polling = {};

  Future<void> loadLanguages() async {
    state = state.copyWith(loadingLanguages: true, languagesError: null);
    try {
      final languages = await repository.getLanguages();
      state = state.copyWith(
        loadingLanguages: false,
        languages: languages,
        languagesError: null,
      );
    } catch (error) {
      state = state.copyWith(
        loadingLanguages: false,
        languagesError: error.toString(),
      );
    }
  }

  Future<void> translate({
    required int documentId,
    required String targetLanguage,
  }) async {
    state = state.copyWith(translatingIds: {...state.translatingIds, documentId});
    try {
      final summary = await repository.translate(
        documentId: documentId,
        targetLanguage: targetLanguage,
      );
      _store(documentId, [summary]);
      _poll(documentId);
    } catch (error) {
      state = state.copyWith(
        translatingIds: {...state.translatingIds}..remove(documentId),
        error: error.toString(),
      );
      rethrow;
    }
  }

  Future<void> refresh(int documentId) async {
    try {
      final summaries = await repository.getTranslations(documentId);
      _store(documentId, summaries);
      if (summaries.any((s) => !s.isTerminal)) {
        _poll(documentId);
      }
    } catch (_) {
      // La galería mantiene los datos incrustados; no bloquea la UI.
    }
  }

  Future<void> delete({
    required int documentId,
    required String targetLanguage,
  }) async {
    final key = _translationKey(documentId, targetLanguage);
    state = state.copyWith(deletingIds: {...state.deletingIds, key});
    try {
      await repository.delete(
        documentId: documentId,
        targetLanguage: targetLanguage,
      );
      final summaries = state.summariesByDocument[documentId] ?? const [];
      _store(
        documentId,
        summaries.where((s) => s.targetLanguage != targetLanguage).toList(),
      );
    } catch (error) {
      rethrow;
    } finally {
      state = state.copyWith(deletingIds: {...state.deletingIds}..remove(key));
    }
  }

  Future<void> _poll(int documentId) async {
    if (_polling.contains(documentId)) return;
    _polling.add(documentId);
    try {
      for (var attempt = 0; attempt < 60; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final summaries = await repository.getTranslations(documentId);
        _store(documentId, summaries);
        if (summaries.every((s) => s.isTerminal)) break;
      }
    } catch (_) {
      // Reintenta en la siguiente ronda; la UI sigue mostrando el estado.
    } finally {
      _polling.remove(documentId);
      state = state.copyWith(
        translatingIds: {...state.translatingIds}..remove(documentId),
      );
    }
  }

  void _store(int documentId, List<TranslationSummary> summaries) {
    state = state.copyWith(
      summariesByDocument: {...state.summariesByDocument, documentId: summaries},
    );
  }
}
