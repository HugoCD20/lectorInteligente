import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/authentication/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson construye el modelo completo', () {
      final model = UserModel.fromJson(const {
        'id': 7,
        'email': 'ana@example.com',
        'first_name': 'Ana',
        'last_name': 'Pérez',
      });

      expect(model.id, 7);
      expect(model.email, 'ana@example.com');
      expect(model.firstName, 'Ana');
      expect(model.lastName, 'Pérez');
    });

    test('fromJson usa valores por defecto cuando faltan campos', () {
      final model = UserModel.fromJson(const {
        'id': 3,
        'email': 'test@example.com',
      });

      expect(model.firstName, '');
      expect(model.lastName, '');
    });

    test('fullName combina nombre y apellido', () {
      final model = UserModel.fromJson(const {
        'id': 1,
        'email': 'test@example.com',
        'first_name': 'Ana',
        'last_name': 'Pérez',
      });
      expect(model.fullName, 'Ana Pérez');
    });

    test('fullName devuelve vacío sin datos', () {
      final model = UserModel.fromJson(const {
        'id': 1,
        'email': 'test@example.com',
      });
      expect(model.fullName, '');
    });
  });
}
