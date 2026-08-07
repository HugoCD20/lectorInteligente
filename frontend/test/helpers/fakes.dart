import 'dart:typed_data';

import 'package:lector_inteligente/core/errors/app_exception.dart';
import 'package:lector_inteligente/features/authentication/domain/entities/auth_session.dart';
import 'package:lector_inteligente/features/authentication/domain/entities/user.dart';
import 'package:lector_inteligente/features/authentication/domain/repositories/auth_repository.dart';
import 'package:lector_inteligente/features/documents/domain/entities/document.dart';
import 'package:lector_inteligente/features/documents/domain/repositories/document_repository.dart';
import 'package:lector_inteligente/features/reader/domain/entities/reader_page_data.dart';
import 'package:lector_inteligente/features/reader/domain/repositories/reader_repository.dart';
import 'package:lector_inteligente/features/translations/domain/entities/translation.dart';
import 'package:lector_inteligente/features/translations/domain/repositories/translation_repository.dart';

const fakeUser = User(
  id: 1,
  email: 'test@example.com',
  firstName: 'Ana',
  lastName: 'Pérez',
);

const fakeSession = AuthSession(
  user: fakeUser,
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
);

Document makeDocument({
  int id = 1,
  String name = 'documento.pdf',
  int fileSize = 2048,
  List<TranslationSummary> translations = const [],
}) {
  return Document(
    id: id,
    originalName: name,
    extension: 'pdf',
    mimeType: 'application/pdf',
    fileSize: fileSize,
    createdAt: DateTime(2026, 1, 1),
    translations: translations,
  );
}

TranslationSummary makeTranslation({
  int id = 1,
  String target = 'en',
  String status = 'pending',
  int totalPages = 2,
  int processedPages = 0,
}) {
  return TranslationSummary(
    id: id,
    targetLanguage: target,
    status: status,
    totalPages: totalPages,
    processedPages: processedPages,
    updatedAt: DateTime(2026, 1, 1),
  );
}

ReaderPage makeReaderPage({
  int pageNumber = 1,
  String originalContent = 'Contenido',
  String? translatedContent,
}) {
  return ReaderPage(
    pageNumber: pageNumber,
    originalContent: originalContent,
    translatedContent: translatedContent,
  );
}

ReaderPageData makeReaderPageData({
  int totalPages = 3,
  int page = 1,
  String? targetLanguage,
  List<ReaderPage> pages = const [],
}) {
  return ReaderPageData(
    totalPages: totalPages,
    page: page,
    pageSize: 1,
    targetLanguage: targetLanguage,
    pages: pages,
  );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failOn = false});

  final bool failOn;
  final List<String> calls = [];
  User? sessionUser;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    calls.add('login');
    if (failOn) throw const AppException('Credenciales inválidas.');
    return fakeSession;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    calls.add('register');
    if (failOn) throw const AppException('Ya existe una cuenta con este email.');
    return fakeSession;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    sessionUser = null;
  }

  @override
  Future<User?> restoreSession() async {
    calls.add('restoreSession');
    return sessionUser;
  }

  @override
  Future<User> updateProfile({String? firstName, String? lastName}) async {
    calls.add('updateProfile');
    return fakeUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls.add('changePassword');
    if (failOn) throw const AppException('La contraseña actual es incorrecta.');
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    sessionUser = null;
  }
}

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({
    this.documents = const [],
    this.recent = const [],
    this.failOnGallery = false,
    this.failOnUpload = false,
  });

  final List<Document> documents;
  final List<Document> recent;
  final bool failOnGallery;
  final bool failOnUpload;
  final List<int> deletedIds = [];

  @override
  Future<PaginatedDocuments> getGallery({int page = 1, String? search}) async {
    if (failOnGallery) throw const AppException('Error al cargar la galería.');
    final filtered = search == null || search.isEmpty
        ? documents
        : documents
            .where((document) => document.originalName.contains(search))
            .toList();
    final start = (page - 1) * 2;
    final slice = filtered.skip(start).take(2).toList();
    return PaginatedDocuments(
      count: filtered.length,
      page: page,
      pageSize: 2,
      next: start + 2 < filtered.length ? 'page=${page + 1}' : null,
      documents: slice,
    );
  }

  @override
  Future<List<Document>> getRecent({int limit = 5}) async => recent;

  @override
  Future<Document> upload({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (failOnUpload) throw const AppException('Error al subir el archivo.');
    return makeDocument(id: 99, name: fileName, fileSize: bytes.length);
  }

  @override
  Future<void> delete(int id) async {
    deletedIds.add(id);
  }
}

class FakeReaderRepository implements ReaderRepository {
  FakeReaderRepository({this.failOn = false, this.totalPages = 3});

  final bool failOn;
  final int totalPages;
  final List<int> requestedPages = [];

  @override
  Future<ReaderPageData> readPage({
    required int documentId,
    required int page,
    int pageSize = 1,
    String? targetLanguage,
  }) async {
    if (failOn) throw const AppException('No se pudo leer la página.');
    requestedPages.add(page);
    return makeReaderPageData(
      totalPages: totalPages,
      page: page,
      targetLanguage: targetLanguage,
      pages: [
        makeReaderPage(
          pageNumber: page,
          originalContent: 'Contenido de la página $page',
          translatedContent: targetLanguage == null
              ? null
              : '[$targetLanguage] página $page',
        ),
      ],
    );
  }
}

class FakeTranslationRepository implements TranslationRepository {
  FakeTranslationRepository({
    this.languages = const [],
    this.translationsFor = const {},
    this.summaries = const [],
    this.failOn = false,
  });

  final List<TranslationLanguage> languages;
  final Map<int, List<TranslationSummary>> translationsFor;
  final List<TranslationSummary> summaries;
  final bool failOn;
  final List<String> calls = [];

  @override
  Future<TranslationSummary> translate({
    required int documentId,
    required String targetLanguage,
  }) async {
    calls.add('translate');
    if (failOn) throw const AppException('El documento supera el límite.');
    return makeTranslation(
      target: targetLanguage,
      status: 'processing',
    );
  }

  @override
  Future<List<TranslationSummary>> getTranslations(int documentId) async {
    calls.add('getTranslations');
    if (translationsFor.containsKey(documentId)) {
      return translationsFor[documentId]!;
    }
    return summaries;
  }

  @override
  Future<TranslationDetail> getTranslationDetail({
    required int documentId,
    required String targetLanguage,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete({
    required int documentId,
    required String targetLanguage,
  }) async {
    calls.add('delete');
  }

  @override
  Future<List<TranslationLanguage>> getLanguages() async {
    calls.add('getLanguages');
    if (failOn) throw const AppException('Error al cargar los idiomas.');
    return languages;
  }
}
