import 'package:flutter/material.dart';

import '../features/authentication/presentation/login_page.dart';
import '../features/authentication/presentation/profile_page.dart';
import '../features/authentication/presentation/register_page.dart';
import '../features/documents/domain/entities/document.dart';
import '../features/documents/presentation/pages/gallery_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/reader/presentation/pages/document_reader_page.dart';

/// Navegación centralizada.
///
/// Las rutas se declaran únicamente en este archivo.
abstract final class Routes {
  Routes._();

  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String gallery = '/gallery';
  static const String reader = '/reader';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      home => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomePage(),
        ),
      login => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginPage(),
        ),
      register => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RegisterPage(),
        ),
      profile => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ProfilePage(),
        ),
      gallery => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GalleryPage(),
        ),
      reader => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final document = settings.arguments as Document;
            return DocumentReaderPage(document: document);
          },
        ),
      _ => null,
    };
  }
}
