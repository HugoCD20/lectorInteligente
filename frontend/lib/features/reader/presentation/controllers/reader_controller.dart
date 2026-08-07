import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../translations/domain/entities/translation.dart';
import '../../domain/entities/reader_page_data.dart';
import '../../domain/repositories/reader_repository.dart';

/// Estado del lector de documentos.
class ReaderState {
  const ReaderState({
    this.documentId,
    this.documentName = '',
    this.availableLanguages = const [],
    this.targetLanguage,
    this.totalPages = 0,
    this.currentPage = 1,
    this.loading = false,
    this.error,
    this.pages = const {},
  });

  final int? documentId;
  final String documentName;
  final List<String> availableLanguages;
  final String? targetLanguage;
  final int totalPages;
  final int currentPage;
  final bool loading;
  final String? error;
  final Map<int, ReaderPage> pages;

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < totalPages;
  bool get hasTranslation => targetLanguage != null;

  ReaderPage? get current => pages[currentPage];

  ReaderState copyWith({
    int? documentId,
    String? documentName,
    List<String>? availableLanguages,
    String? targetLanguage,
    int? totalPages,
    int? currentPage,
    bool? loading,
    String? error,
    Map<int, ReaderPage>? pages,
  }) {
    return ReaderState(
      documentId: documentId ?? this.documentId,
      documentName: documentName ?? this.documentName,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      pages: pages ?? this.pages,
    );
  }
}

/// Controlador del lector: carga eficiente de páginas con caché y precarga.
class ReaderController extends StateNotifier<ReaderState> {
  ReaderController({required this.repository}) : super(const ReaderState());

  final ReaderRepository repository;
  final Set<int> _fetching = {};

  void open({
    required int documentId,
    required String documentName,
    required List<TranslationSummary> translations,
  }) {
    final available = translations
        .where((t) => t.status == 'completed' || t.status == 'partial')
        .map((t) => t.targetLanguage)
        .toList();
    state = ReaderState(
      documentId: documentId,
      documentName: documentName,
      availableLanguages: available,
      targetLanguage: available.isEmpty ? null : available.first,
    );
    _loadPage(1);
  }

  void setTargetLanguage(String? code) {
    if (state.targetLanguage == code) return;
    state = state.copyWith(
      targetLanguage: code,
      currentPage: 1,
      pages: const {},
      error: null,
    );
    _loadPage(1);
  }

  void goToPage(int page) {
    if (state.pages.containsKey(page)) {
      state = state.copyWith(currentPage: page, error: null);
      _prefetch(page + 1);
      return;
    }
    _loadPage(page);
  }

  void nextPage() {
    if (state.hasNext) goToPage(state.currentPage + 1);
  }

  void previousPage() {
    if (state.hasPrevious) goToPage(state.currentPage - 1);
  }

  void retry() {
    if (state.currentPage > 0) _loadPage(state.currentPage);
  }

  Future<void> _loadPage(int page) async {
    final documentId = state.documentId;
    if (documentId == null) return;
    if (_fetching.contains(page)) return;
    _fetching.add(page);

    state = state.copyWith(loading: true, error: null);
    try {
      final result = await repository.readPage(
        documentId: documentId,
        page: page,
        pageSize: 1,
        targetLanguage: state.targetLanguage,
      );
      if (documentId != state.documentId) return;
      final pages = {...state.pages};
      if (result.pages.isNotEmpty) {
        pages[result.pages.first.pageNumber] = result.pages.first;
      }
      state = state.copyWith(
        loading: false,
        totalPages: result.totalPages,
        currentPage: result.page,
        pages: pages,
        error: null,
      );
      _prefetch(result.page + 1);
    } catch (error) {
      if (documentId != state.documentId) return;
      state = state.copyWith(loading: false, error: error.toString());
    } finally {
      _fetching.remove(page);
    }
  }

  Future<void> _prefetch(int page) async {
    final documentId = state.documentId;
    if (documentId == null) return;
    if (page > state.totalPages || page < 1) return;
    if (state.pages.containsKey(page)) return;
    if (_fetching.contains(page)) return;
    _fetching.add(page);
    try {
      final result = await repository.readPage(
        documentId: documentId,
        page: page,
        pageSize: 1,
        targetLanguage: state.targetLanguage,
      );
      if (documentId != state.documentId) return;
      final pages = {...state.pages};
      if (result.pages.isNotEmpty) {
        pages[result.pages.first.pageNumber] = result.pages.first;
      }
      state = state.copyWith(totalPages: result.totalPages, pages: pages);
    } catch (_) {
      // La precarga falla silenciosamente; la navegación reintentará.
    } finally {
      _fetching.remove(page);
    }
  }
}
