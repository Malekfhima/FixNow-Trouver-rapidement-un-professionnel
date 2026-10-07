/// Table de routage des notifications FixNow par type.
///
/// Utilisée par les trois points d'entrée :
/// - tap sur une notification locale (payload JSON) ;
/// - tap sur une notification push FCM (`data`) ;
/// - tap sur une tuile de la liste in-app (`notifications_screen.dart`).
///
/// Fonction PURE (aucune dépendance Firebase) → testée dans
/// `test/notification_routing_test.dart`.
library;

/// Types liés à une demande de service (destination : détail commande
/// côté client, liste des demandes pro côté pro).
const _requestTypes = <String>{
  'newRequest',
  'quoteReceived',
  'requestAccepted',
  'requestDeclined',
  'requestStarted',
  'requestCompleted',
  'requestCancelled',
};

/// Résout la destination GoRouter pour un tap sur une notification.
///
/// Renvoie null (aucune navigation) quand :
/// - le type est inconnu ou `generic` ;
/// - l'identifiant cible (`relatedId`) est manquant.
///
/// [isPro] oriente les types liés aux demandes et à la validation du
/// compte pro vers l'écran adapté au rôle.
String? resolveNotificationLocation({
  required String type,
  String? relatedId,
  required bool isPro,
}) {
  final id = relatedId ?? '';
  switch (type) {
    case 'newMessage':
      return id.isEmpty ? null : '/chat/$id';

    case 'reviewReceived':
      return '/pro-reviews';

    case 'proApproved':
    case 'proRejected':
      // Pro validé → tableau de bord ; rejeté/en attente → édition du
      // profil pro (permet de corriger puis redemander la validation).
      return isPro ? '/pro-dashboard' : '/pro-profile-edit';

    default:
      if (_requestTypes.contains(type)) {
        if (id.isEmpty) return null;
        return isPro ? '/pro-dashboard' : '/orders/$id';
      }
      // Type inconnu ou generic : ignoré.
      return null;
  }
}
