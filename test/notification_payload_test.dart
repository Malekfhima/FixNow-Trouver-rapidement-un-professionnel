import 'package:flutter_test/flutter_test.dart';

import 'package:fixnow/services/local_notification_service.dart';

/// Captures the data passed to [NotificationTapRouter.route].
Map<String, dynamic>? routed;

void main() {
  setUp(() {
    routed = null;
    NotificationTapRouter.handler = (data) => routed = data;
  });
  tearDown(() {
    NotificationTapRouter.handler = null;
  });

  group('Payload JSON des notifications locales (T1)', () {
    test(
      'aller-retour newRequest : encode → decode → route avec les bonnes clés',
      () {
        // Même construction que _localPayloadFor (app_bindings.dart).
        const data = {'type': 'newRequest', 'relatedId': 'req-123'};
        final payload = NotificationTapRouter.encodePayload(data);
        expect(payload, '{"type":"newRequest","relatedId":"req-123"}');

        NotificationTapRouter.route(
          NotificationTapRouter.decodePayload(payload),
        );

        expect(routed, isNotNull);
        expect(routed!['type'], 'newRequest');
        expect(routed!['relatedId'], 'req-123');
      },
    );

    test(
      'aller-retour newMessage : encode → decode → route avec les bonnes clés',
      () {
        const data = {'type': 'newMessage', 'chatId': 'chat-456'};
        final payload = NotificationTapRouter.encodePayload(data);

        NotificationTapRouter.route(
          NotificationTapRouter.decodePayload(payload),
        );

        expect(routed, isNotNull);
        expect(routed!['type'], 'newMessage');
        expect(routed!['chatId'], 'chat-456');
      },
    );

    test('payload malformé : map vide, aucune exception, aucun routage', () {
      // Ancien format fragile (« map Dart en texte ») — doit être ignoré.
      final decoded =
          NotificationTapRouter.decodePayload('{type: newRequest, x: 1}');
      expect(decoded, isEmpty);

      // Un payload vide ne déclenche aucune navigation utile : le handler
      // reçoit au pire une map vide (types inconnus ignorés côté routage).
      expect(NotificationTapRouter.decodePayload(null), isEmpty);
      expect(NotificationTapRouter.decodePayload(''), isEmpty);
      expect(NotificationTapRouter.decodePayload('not json at all'), isEmpty);
      expect(NotificationTapRouter.decodePayload('["a","b"]'), isEmpty);
    });

    test('encodePayload : valeurs non encodables → null, sans exception', () {
      expect(
        NotificationTapRouter.encodePayload({'ok': [1, 2, 3]}),
        '{"ok":[1,2,3]}',
      );
      expect(
        NotificationTapRouter.encodePayload({'bad': DateTime.now()}),
        isNull,
      );
    });

    test('stableId : déterministe, positif, sensible au contenu', () {
      final a1 = NotificationTapRouter.stableId('notif-1');
      expect(NotificationTapRouter.stableId('notif-1'), a1);
      expect(a1, greaterThanOrEqualTo(0));
      expect(NotificationTapRouter.stableId('notif-2'), isNot(a1));
    });
  });
}
