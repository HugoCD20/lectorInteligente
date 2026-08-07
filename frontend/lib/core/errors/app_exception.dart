/// Excepción de dominio con mensaje amigable para el usuario.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
