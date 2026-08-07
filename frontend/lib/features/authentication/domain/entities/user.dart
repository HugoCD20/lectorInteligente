/// Entidad de usuario del dominio.
class User {
  const User({
    required this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;

  String get fullName {
    final full = [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
    return full.trim();
  }
}
