import 'dart:typed_data';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fixnow/features/booking/booking_controller.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

XFile _jpeg(String name) {
  final bytes = Uint8List(1024)..fillRange(0, 1024, 0x1F);
  return XFile.fromData(bytes, name: name, mimeType: 'image/jpeg');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookingController — garde photos', () {
    test(
      'plus de maxPhotosPerRequest photos : erreur FR, aucune écriture '
      'Firestore ni upload (la validation précède tout accès distant)',
      () async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWithValue(MockUser(uid: 'client-1')),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(bookingControllerProvider.notifier);

        final photos =
            List.generate(6, (i) => _jpeg('photo$i.jpg')); // limite = 5

        await controller.submitRequest(
          proId: 'pro-1',
          categoryId: 'plomberie',
          description: 'Fuite sous lévier de la cuisine, urgence.',
          address: '12 rue des Lilas, 75011 Paris',
          scheduledDate: null,
          photos: photos,
        );

        expect(controller.state.error, 'Maximum 5 photos');
        expect(controller.state.isSuccess, isFalse);
        expect(controller.state.isLoading, isFalse);
      },
    );

    test('utilisateur non connecté : erreur explicite', () async {
      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      final controller = container.read(bookingControllerProvider.notifier);

      await controller.submitRequest(
        proId: 'pro-1',
        categoryId: 'plomberie',
        description: 'Fuite sous lévier de la cuisine, urgence.',
        address: '12 rue des Lilas, 75011 Paris',
        scheduledDate: null,
      );

      expect(controller.state.error, 'Vous devez être connecté');
    });
  });
}
