/// Configuración del entorno de la aplicación.
abstract final class AppEnvironment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
