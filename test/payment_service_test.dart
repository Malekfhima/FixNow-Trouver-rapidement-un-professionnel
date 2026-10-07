import 'package:flutter_test/flutter_test.dart';

import 'package:fixnow/services/payment_service.dart';

void main() {
  group('FakePaymentService (paiement simulé, aucun frais)', () {
    final service = FakePaymentService();

    test('calcule l\'acompte à 30 % arrondi au centime', () {
      expect(FakePaymentService.depositFor(100), 30.0);
      expect(FakePaymentService.depositFor(49.99), closeTo(15.0, 0.001));
      expect(FakePaymentService.depositFor(0), 0.0);
    });

    test('payDeposit renvoie un résultat avec id déterministe', () async {
      final result = await service.payDeposit(orderId: 'o1', amount: 30);
      expect(result.transactionId, 'fake_dep_o1');
      expect(result.amount, 30);
    });

    test('payBalance renvoie un résultat avec id déterministe', () async {
      final result = await service.payBalance(orderId: 'o2', amount: 70);
      expect(result.transactionId, 'fake_bal_o2');
      expect(result.amount, 70);
    });

    test('refund renvoie un résultat avec id déterministe', () async {
      final result = await service.refund(
        orderId: 'o3',
        transactionId: 'fake_dep_o3',
        amount: 30,
      );
      expect(result.transactionId, 'fake_ref_o3');
      expect(result.amount, 30);
    });

    test('montant nul ou négatif : PaymentException', () async {
      await expectLater(
        service.payDeposit(orderId: 'o4', amount: 0),
        throwsA(isA<PaymentException>()),
      );
      await expectLater(
        service.payBalance(orderId: 'o4', amount: -5),
        throwsA(isA<PaymentException>()),
      );
    });

    test('montant NaN : PaymentException', () async {
      await expectLater(
        service.refund(orderId: 'o5', transactionId: 't', amount: double.nan),
        throwsA(isA<PaymentException>()),
      );
    });
  });
}
