import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fixnow/services/storage_service.dart';

XFile _jpeg({int kilobytes = 2}) {
  final bytes = Uint8List(kilobytes * 1024)
    ..fillRange(0, kilobytes * 1024, 0x1F);
  return XFile.fromData(
    bytes,
    name: 'photo.jpg',
    mimeType: 'image/jpeg',
  );
}

StorageService _service(http.Client client) => StorageService(
      client: client,
      cloudName: 'test-cloud',
      uploadPreset: 'test-preset',
    );

void main() {
  group('StorageService (Cloudinary, upload unsigned)', () {
    test('upload réussi : POST multipart vers la bonne URL, secure_url renvoyée',
        () async {
      Uri? capturedUrl;
      String? capturedPreset;
      String? capturedPublicId;
      var capturedFileField = false;

      final client = MockClient((request) async {
        capturedUrl = request.url;
        // MockClient lit le corps multipart dans un Request unique.
        final body = utf8.decode(request.bodyBytes);
        capturedPreset =
            RegExp('name="upload_preset"\\r\\n\\r\\n([^\\r]*)').firstMatch(body)?.group(1);
        capturedPublicId =
            RegExp('name="public_id"\\r\\n\\r\\n([^\\r]*)').firstMatch(body)?.group(1);
        capturedFileField = body.contains('name="file"');
        return http.Response(
          jsonEncode({
            'secure_url': 'https://res.cloudinary.com/test-cloud/image/upload/v1/avatars/u1.jpg',
            'public_id': 'avatars_u1',
          }),
          200,
        );
      });

      final url = await _service(client).uploadAvatar('u1', _jpeg());

      expect(url, 'https://res.cloudinary.com/test-cloud/image/upload/v1/avatars/u1.jpg');
      expect(capturedUrl!.host, 'api.cloudinary.com');
      expect(capturedUrl!.path, '/v1_1/test-cloud/image/upload');
      expect(capturedPreset, 'test-preset');
      expect(capturedPublicId, matches(RegExp(r'^avatars/u1_[0-9a-f]{8}$')),
          reason: 'le public_id garde la structure de dossiers + suffixe unique');
      expect(capturedFileField, isTrue, reason: 'le fichier doit être envoyé');
    });

    test('garde client : image > 5 Mo refusée AVANT tout envoi réseau', () async {
      var networkCalled = false;
      final client = MockClient((request) async {
        networkCalled = true;
        return http.Response('{}', 200);
      });

      await expectLater(
        _service(client).uploadAvatar('u1', _jpeg(kilobytes: 5 * 1024 + 1)),
        throwsA(isA<StorageException>()),
      );
      expect(networkCalled, isFalse, reason: 'aucun octet ne doit partir');
    });

    test('garde « image uniquement » : un PDF est refusé', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final pdf = XFile.fromData(
        Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        name: 'doc.pdf',
        mimeType: 'application/pdf',
      );

      await expectLater(
        _service(client).uploadAvatar('u1', pdf),
        throwsA(isA<StorageException>()),
      );
    });

    test('config manquante : erreur explicite, aucun appel réseau', () async {
      var networkCalled = false;
      final client = MockClient((request) async {
        networkCalled = true;
        return http.Response('{}', 200);
      });
      final service = StorageService(client: client);

      await expectLater(
        service.uploadAvatar('u1', _jpeg()),
        throwsA(isA<StorageException>()),
      );
      expect(networkCalled, isFalse);
    });

    test('erreur Cloudinary 401 (preset invalide) : message FR', () async {
      final client = MockClient(
        (request) async =>
            http.Response(jsonEncode({'error': {'message': 'Invalid upload preset'}}), 401),
      );

      await expectLater(
        _service(client).uploadAvatar('u1', _jpeg()),
        throwsA(
          isA<StorageException>()
              .having((e) => e.code, 'code', 'not-configured'),
        ),
      );
    });

    test('erreur Cloudinary « File size too large » : message FR', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': {'message': 'File size too large'}}),
          400,
        ),
      );

      await expectLater(
        _service(client).uploadGalleryImage('u1', 0, _jpeg()),
        throwsA(
          isA<StorageException>()
              .having((e) => e.code, 'code', 'image-too-large'),
        ),
      );
    });

    test('tous les chemins métiers produisent un public_id distinct', () async {
      final publicIds = <String>[];
      final client = MockClient((request) async {
        final body = utf8.decode(request.bodyBytes);
        publicIds.add(RegExp('name="public_id"\\r\\n\\r\\n([^\\r]*)')
                .firstMatch(body)
                ?.group(1) ??
            '');
        return http.Response(jsonEncode({'secure_url': 'https://x/y.jpg'}), 200);
      });
      final service = _service(client);
      final file = _jpeg();

      await service.uploadAvatar('u1', file);
      await service.uploadGalleryImage('u1', 3, file);
      await service.uploadRequestPhoto('req1', 0, file);
      await service.uploadChatImage('chat1', 'msg1', file);

      expect(
        publicIds.map((id) => id.replaceAll(RegExp(r'_[0-9a-f]{8}$'), '')),
        ['avatars/u1', 'gallery/u1/3', 'requests/req1/0', 'chats/chat1/msg1'],
        reason: 'le préfixe conserve la structure de dossiers',
      );
      expect(publicIds.toSet().length, publicIds.length,
          reason: 'chaque upload a un public_id unique');
    });

    test('même chemin envoyé deux fois : public_id distincts (pas d\'écrasement)',
        () async {
      final publicIds = <String>[];
      final client = MockClient((request) async {
        final body = utf8.decode(request.bodyBytes);
        publicIds.add(RegExp('name="public_id"\\r\\n\\r\\n([^\\r]*)')
                .firstMatch(body)
                ?.group(1) ??
            '');
        return http.Response(jsonEncode({'secure_url': 'https://x/y.jpg'}), 200);
      });
      final service = _service(client);
      final file = _jpeg();

      await service.uploadAvatar('u1', file);
      await service.uploadAvatar('u1', file);

      expect(publicIds[0], isNot(publicIds[1]),
          reason: 'mode unsigned : Cloudinary refuse d\'écraser un public_id existant');
    });
  });
}
