import 'package:flutter_test/flutter_test.dart';
import 'package:fixnow/models/address_model.dart';
import 'package:fixnow/models/user_model.dart';

void main() {
  group('Address', () {
    test('fromMap / toMap font un aller-retour complet', () {
      const a = Address(
        label: 'Maison',
        fullAddress: '12 rue des Oliviers, Tunis',
        notes: 'Code portail 1234',
      );
      final map = a.toMap();

      expect(map['label'], 'Maison');
      expect(map['address'], '12 rue des Oliviers, Tunis');
      expect(map['notes'], 'Code portail 1234');

      final b = Address.fromMap(map);
      expect(b, a);
    });

    test('toMap omet la note absente', () {
      const a = Address(label: 'Bureau', fullAddress: 'Ariana');
      final map = a.toMap();

      expect(map.containsKey('notes'), isFalse);
      expect(Address.fromMap(map), a);
    });

    test('fromMap tolère les champs manquants', () {
      final a = Address.fromMap(const {});
      expect(a.label, '');
      expect(a.fullAddress, '');
      expect(a.notes, isNull);
    });

    test('constructeur par défaut : addresses vide', () {
      final user = AppUser(
        uid: 'u1',
        name: 'Client',
        email: 'c@ex.tn',
        createdAt: DateTime(2026),
      );
      expect(user.addresses, isEmpty);
    });

    test('copyWith conserve les adresses existantes', () {
      const a = Address(label: 'Maison', fullAddress: 'Tunis');
      final user = AppUser(
        uid: 'u1',
        name: 'Client',
        email: 'c@ex.tn',
        addresses: const [a],
        createdAt: DateTime.now(),
      );

      final renamed = user.copyWith(name: 'Nouveau nom');
      expect(renamed.addresses, hasLength(1));
      expect(renamed.addresses.first, a);
    });
  });
}
