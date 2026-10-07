import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Résultat d'un paiement (simulé ou réel).
class PaymentResult {
  /// Identifiant de transaction (fourni par le prestataire).
  final String transactionId;

  /// Montant réellement débité (après acompte/échéancier).
  final double amount;

  const PaymentResult({
    required this.transactionId,
    required this.amount,
  });
}

/// Échec de paiement (message déjà en français pour l'utilisateur).
class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);

  @override
  String toString() => message;
}

/// Interface d'un prestataire de paiement.
///
/// FixNow n'utilise AUCUN vrai prestataire (100 % gratuit, plan Spark) :
/// l'implémentation active est [FakePaymentService]. Une future intégration
/// (Stripe, PayPal…) n'aurait qu'à implémenter cette interface.
abstract class PaymentService {
  /// Débute une prestation : le client paie un ACOMPTE.
  /// [amount] = montant de l'acompte (pas le total).
  Future<PaymentResult> payDeposit({
    required String orderId,
    required double amount,
  });

  /// Solde la prestation : paiement du RESTE à la fin de la mission.
  Future<PaymentResult> payBalance({
    required String orderId,
    required double amount,
  });

  /// Rembourse un paiement (annulation client).
  Future<PaymentResult> refund({
    required String orderId,
    required String transactionId,
    required double amount,
  });
}

/// Paiement SIMULÉ — aucun frais, aucune API externe.
///
/// Comportement réaliste : valide les montants (positifs, non nuls),
/// simule une latence réseau courte et renvoie un identifiant de
/// transaction déterministe (utile pour les tests).
class FakePaymentService implements PaymentService {
  /// Part de l'acompte par défaut : 30 % du montant de la prestation.
  static const double depositRate = 0.30;

  /// Calcule l'acompte d'une prestation (arrondi au centime).
  static double depositFor(double total) =>
      (total * depositRate * 100).roundToDouble() / 100;

  Future<void> _simulateLatency() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  void _validate(double amount) {
    if (amount.isNaN || amount <= 0) {
      throw const PaymentException('Montant invalide.');
    }
  }

  @override
  Future<PaymentResult> payDeposit({
    required String orderId,
    required double amount,
  }) async {
    _validate(amount);
    await _simulateLatency();
    return PaymentResult(
      transactionId: 'fake_dep_$orderId',
      amount: amount,
    );
  }

  @override
  Future<PaymentResult> payBalance({
    required String orderId,
    required double amount,
  }) async {
    _validate(amount);
    await _simulateLatency();
    return PaymentResult(
      transactionId: 'fake_bal_$orderId',
      amount: amount,
    );
  }

  @override
  Future<PaymentResult> refund({
    required String orderId,
    required String transactionId,
    required double amount,
  }) async {
    _validate(amount);
    await _simulateLatency();
    return PaymentResult(
      transactionId: 'fake_ref_$orderId',
      amount: amount,
    );
  }
}

/// Provider du service de paiement (simulé).
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return FakePaymentService();
});
