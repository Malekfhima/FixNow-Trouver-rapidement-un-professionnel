import 'package:flutter_test/flutter_test.dart';

import 'package:fixnow/services/notification_routing.dart';

void main() {
  group('Table de routage des notifications (T2)', () {
    const requestTypes = [
      'newRequest',
      'quoteReceived',
      'requestAccepted',
      'requestDeclined',
      'requestStarted',
      'requestCompleted',
      'requestCancelled',
    ];

    test('types liés à une demande : client → /orders/<id>', () {
      for (final type in requestTypes) {
        expect(
          resolveNotificationLocation(
              type: type, relatedId: 'req-1', isPro: false),
          '/orders/req-1',
          reason: 'type $type',
        );
      }
    });

    test('types liés à une demande : pro → /pro-dashboard', () {
      for (final type in requestTypes) {
        expect(
          resolveNotificationLocation(
              type: type, relatedId: 'req-1', isPro: true),
          '/pro-dashboard',
          reason: 'type $type',
        );
      }
    });

    test('newMessage → /chat/<id> quel que soit le rôle', () {
      expect(
        resolveNotificationLocation(
            type: 'newMessage', relatedId: 'chat-9', isPro: false),
        '/chat/chat-9',
      );
      expect(
        resolveNotificationLocation(
            type: 'newMessage', relatedId: 'chat-9', isPro: true),
        '/chat/chat-9',
      );
    });

    test('reviewReceived → /pro-reviews', () {
      expect(
        resolveNotificationLocation(
            type: 'reviewReceived', relatedId: 'rev-1', isPro: true),
        '/pro-reviews',
      );
    });

    test('proApproved : pro → /pro-dashboard ; non pro → /pro-profile-edit', () {
      expect(
        resolveNotificationLocation(type: 'proApproved', isPro: true),
        '/pro-dashboard',
      );
      expect(
        resolveNotificationLocation(type: 'proApproved', isPro: false),
        '/pro-profile-edit',
      );
    });

    test('proRejected : pro → /pro-dashboard ; non pro → /pro-profile-edit',
        () {
      expect(
        resolveNotificationLocation(type: 'proRejected', isPro: true),
        '/pro-dashboard',
      );
      expect(
        resolveNotificationLocation(type: 'proRejected', isPro: false),
        '/pro-profile-edit',
      );
    });

    test('type inconnu et generic : ignorés (null)', () {
      expect(
        resolveNotificationLocation(
            type: 'unknownType', relatedId: 'x', isPro: false),
        isNull,
      );
      expect(
        resolveNotificationLocation(type: 'generic', relatedId: 'x', isPro: true),
        isNull,
      );
      expect(
        resolveNotificationLocation(type: '', relatedId: 'x', isPro: false),
        isNull,
      );
    });

    test('relatedId manquant : null (aucune navigation cassée)', () {
      expect(
        resolveNotificationLocation(
            type: 'newRequest', relatedId: null, isPro: false),
        isNull,
      );
      expect(
        resolveNotificationLocation(
            type: 'newMessage', relatedId: '', isPro: false),
        isNull,
      );
    });
  });
}
