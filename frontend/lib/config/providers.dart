import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../features/authentication/data/auth_repository_impl.dart';
import '../../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../features/documents/data/datasources/document_remote_datasource.dart';
import '../../features/documents/data/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/documents/presentation/controllers/documents_controller.dart';
import '../../features/translations/data/datasources/translation_remote_datasource.dart';
import '../../features/translations/data/translation_repository_impl.dart';
import '../../features/translations/domain/repositories/translation_repository.dart';
import '../../features/translations/presentation/controllers/translation_controller.dart';
import '../../features/reader/data/datasources/reader_remote_datasource.dart';
import '../../features/reader/data/reader_repository_impl.dart';
import '../../features/reader/domain/repositories/reader_repository.dart';
import '../../features/reader/presentation/controllers/reader_controller.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStorage: ref.watch(tokenStorageProvider)),
);

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasource(apiClient: ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    datasource: ref.watch(authRemoteDatasourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(authRepository: ref.watch(authRepositoryProvider)),
);

final documentRemoteDatasourceProvider = Provider<DocumentRemoteDatasource>(
  (ref) => DocumentRemoteDatasource(apiClient: ref.watch(apiClientProvider)),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepositoryImpl(
    datasource: ref.watch(documentRemoteDatasourceProvider),
  ),
);

final documentsControllerProvider =
    StateNotifierProvider<DocumentsController, DocumentsState>(
  (ref) => DocumentsController(
    documentRepository: ref.watch(documentRepositoryProvider),
  ),
);

final translationRemoteDatasourceProvider = Provider<TranslationRemoteDatasource>(
  (ref) => TranslationRemoteDatasource(apiClient: ref.watch(apiClientProvider)),
);

final translationRepositoryProvider = Provider<TranslationRepository>(
  (ref) => TranslationRepositoryImpl(
    datasource: ref.watch(translationRemoteDatasourceProvider),
  ),
);

final translationsControllerProvider =
    StateNotifierProvider<TranslationsController, TranslationsState>(
  (ref) => TranslationsController(
    repository: ref.watch(translationRepositoryProvider),
  ),
);

final readerRemoteDatasourceProvider = Provider<ReaderRemoteDatasource>(
  (ref) => ReaderRemoteDatasource(apiClient: ref.watch(apiClientProvider)),
);

final readerRepositoryProvider = Provider<ReaderRepository>(
  (ref) => ReaderRepositoryImpl(datasource: ref.watch(readerRemoteDatasourceProvider)),
);

final readerControllerProvider = StateNotifierProvider<ReaderController, ReaderState>(
  (ref) => ReaderController(repository: ref.watch(readerRepositoryProvider)),
);
