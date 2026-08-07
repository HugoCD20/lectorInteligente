import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';

/// Estado de la gestión de documentos.
class DocumentsState {
  const DocumentsState({
    this.loadingGallery = false,
    this.galleryError,
    this.documents = const [],
    this.page = 1,
    this.hasMore = false,
    this.uploading = false,
    this.uploadError,
    this.recent = const [],
    this.recentError,
    this.deletingIds = const {},
  });

  final bool loadingGallery;
  final String? galleryError;
  final List<Document> documents;
  final int page;
  final bool hasMore;
  final bool uploading;
  final String? uploadError;
  final List<Document> recent;
  final String? recentError;
  final Set<int> deletingIds;

  DocumentsState copyWith({
    bool? loadingGallery,
    String? galleryError,
    List<Document>? documents,
    int? page,
    bool? hasMore,
    bool? uploading,
    String? uploadError,
    List<Document>? recent,
    String? recentError,
    Set<int>? deletingIds,
  }) {
    return DocumentsState(
      loadingGallery: loadingGallery ?? this.loadingGallery,
      galleryError: galleryError ?? this.galleryError,
      documents: documents ?? this.documents,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      uploading: uploading ?? this.uploading,
      uploadError: uploadError ?? this.uploadError,
      recent: recent ?? this.recent,
      recentError: recentError ?? this.recentError,
      deletingIds: deletingIds ?? this.deletingIds,
    );
  }
}

/// Controlador de la gestión de documentos.
class DocumentsController extends StateNotifier<DocumentsState> {
  DocumentsController({required this._documentRepository})
      : super(const DocumentsState());

  final DocumentRepository _documentRepository;
  String _search = '';
  bool _recentLoading = false;

  Future<void> loadRecent() async {
    if (_recentLoading) return;
    _recentLoading = true;
    try {
      final recent = await _documentRepository.getRecent(limit: 5);
      state = state.copyWith(recent: recent, recentError: null);
    } catch (error) {
      state = state.copyWith(recentError: error.toString());
    } finally {
      _recentLoading = false;
    }
  }

  Future<void> loadGallery({bool refresh = false}) async {
    if (state.loadingGallery) return;
    final page = refresh ? 1 : state.page;
    if (!refresh && !state.hasMore && state.documents.isNotEmpty) return;
    if (!refresh && page > 1 && state.documents.isEmpty) return;

    state = state.copyWith(loadingGallery: true, galleryError: null);
    try {
      final result = await _documentRepository.getGallery(
        page: page,
        search: _search.isEmpty ? null : _search,
      );
      final documents = refresh
          ? result.documents
          : [...state.documents, ...result.documents];
      state = state.copyWith(
        loadingGallery: false,
        documents: documents,
        page: result.hasMore ? result.page + 1 : result.page,
        hasMore: result.hasMore,
      );
    } catch (error) {
      state = state.copyWith(
        loadingGallery: false,
        galleryError: error.toString(),
      );
    }
  }

  void setSearch(String query) {
    _search = query.trim();
    state = state.copyWith(documents: const [], page: 1, hasMore: false);
    loadGallery(refresh: true);
  }

  Future<Document> upload({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    state = state.copyWith(uploading: true, uploadError: null);
    try {
      final document = await _documentRepository.upload(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      state = state.copyWith(
        uploading: false,
        uploadError: null,
        recent: [document, ...state.recent],
      );
      loadGallery(refresh: true);
      return document;
    } catch (error) {
      state = state.copyWith(uploading: false, uploadError: error.toString());
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    final deletingIds = {...state.deletingIds, id};
    state = state.copyWith(deletingIds: deletingIds);
    try {
      await _documentRepository.delete(id);
      state = state.copyWith(
        deletingIds: deletingIds..remove(id),
        documents: state.documents.where((d) => d.id != id).toList(),
      );
      loadRecent();
    } catch (error) {
      state = state.copyWith(deletingIds: deletingIds..remove(id));
      rethrow;
    }
  }
}
