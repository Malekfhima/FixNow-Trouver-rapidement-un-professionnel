import 'package:flutter_test/flutter_test.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/service_request_state_machine.dart';

ServiceRequest _req(ServiceRequestStatus status) => ServiceRequest(
      id: 'r1',
      clientId: 'c1',
      proId: 'p1',
      categoryId: 'cat',
      description: 'desc',
      address: 'addr',
      status: status,
      quotePrice: status == ServiceRequestStatus.quoted ? 120 : null,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Machine à états serviceRequests — transitions valides', () {
    test('pending : le pro accepte ou refuse, le client annule', () {
      final r = _req(ServiceRequestStatus.pending);
      expect(r.allowedTransitions(ActorRole.pro),
          [ServiceRequestStatus.accepted, ServiceRequestStatus.declined]);
      expect(r.allowedTransitions(ActorRole.client),
          [ServiceRequestStatus.cancelled]);
      expect(r.canTransitionTo(ServiceRequestStatus.accepted, ActorRole.pro),
          isTrue);
      expect(r.canTransitionTo(ServiceRequestStatus.declined, ActorRole.client),
          isFalse,
          reason: 'seul le pro peut refuser');
    });

    test('accepted : le pro démarre, le client annule', () {
      final r = _req(ServiceRequestStatus.accepted);
      expect(r.allowedTransitions(ActorRole.pro),
          [ServiceRequestStatus.inProgress]);
      expect(r.allowedTransitions(ActorRole.client),
          [ServiceRequestStatus.cancelled]);
    });

    test('quoted : le client accepte le devis ou annule', () {
      final r = _req(ServiceRequestStatus.quoted);
      expect(r.allowedTransitions(ActorRole.client),
          [ServiceRequestStatus.accepted, ServiceRequestStatus.cancelled]);
      expect(r.allowedTransitions(ActorRole.pro), isEmpty,
          reason: 'le pro ne peut rien faire tant que le client décide');
      expect(r.canClientAcceptQuote, isTrue);
    });

    test('quoted sans montant : pas d\'acceptation possible', () {
      // copyWith ne peut pas remettre un champ à null -> construction directe.
      final r = _req(ServiceRequestStatus.quoted);
      expect(r.canClientAcceptQuote, isTrue);
      final noQuote = ServiceRequest(
        id: 'r2',
        clientId: 'c1',
        proId: 'p1',
        categoryId: 'cat',
        description: 'desc',
        address: 'addr',
        status: ServiceRequestStatus.quoted,
        quotePrice: null,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(noQuote.canClientAcceptQuote, isFalse);
    });

    test('inProgress : seul le pro termine', () {
      final r = _req(ServiceRequestStatus.inProgress);
      expect(r.allowedTransitions(ActorRole.pro),
          [ServiceRequestStatus.completed]);
      expect(r.allowedTransitions(ActorRole.client), isEmpty);
      expect(r.canBeCancelledByClient, isFalse,
          reason: 'une prestation en cours ne peut plus être annulée');
    });

    test('états terminaux : aucune transition', () {
      for (final s in [
        ServiceRequestStatus.completed,
        ServiceRequestStatus.declined,
        ServiceRequestStatus.cancelled,
      ]) {
        final r = _req(s);
        expect(r.allowedTransitions(ActorRole.pro), isEmpty, reason: '$s');
        expect(r.allowedTransitions(ActorRole.client), isEmpty, reason: '$s');
        expect(r.allowedTransitions(ActorRole.admin), isEmpty, reason: '$s');
        expect(r.isTerminal, isTrue);
      }
    });

    test('admin : toutes les transitions non terminales autorisées', () {
      final r = _req(ServiceRequestStatus.pending);
      expect(
          r.allowedTransitions(ActorRole.admin).length,
          r.allowedTransitions(ActorRole.pro).length +
              r.allowedTransitions(ActorRole.client).length);
    });

    test('review : uniquement une demande completed', () {
      expect(_req(ServiceRequestStatus.completed).canBeReviewed, isTrue);
      expect(_req(ServiceRequestStatus.inProgress).canBeReviewed, isFalse);
    });

    test('transition invalide typique interdite : completed -> cancelled', () {
      expect(
          _req(ServiceRequestStatus.completed)
              .canTransitionTo(ServiceRequestStatus.cancelled, ActorRole.client),
          isFalse);
      expect(
          _req(ServiceRequestStatus.completed)
              .canTransitionTo(ServiceRequestStatus.pending, ActorRole.admin),
          isFalse);
    });
  });
}
