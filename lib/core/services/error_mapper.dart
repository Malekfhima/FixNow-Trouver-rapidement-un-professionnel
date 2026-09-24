import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Single place that converts technical exceptions into clear,
/// jargon-free French messages for the user.
///
/// Raw errors are never shown in the UI: the technical detail is
/// logged in debug mode only ([developer.log]).
class ErrorMapper {
  ErrorMapper._();

  /// Returns a user-facing French message for [error].
  static String message(Object error) {
    if (error is FirebaseAuthException) return _auth(error);
    if (error is FirebaseException) return _firestore(error);
    if (error is TimeoutException) {
      return 'Le serveur met trop de temps à répondre. Vérifiez votre connexion puis réessayez.';
    }
    if (error is FormatException) {
      return 'Saisie invalide. Vérifiez les champs du formulaire.';
    }
    // SocketException / ClientException / http errors…
    final s = error.toString().toLowerCase();
    // Flutter web : erreur js_interop « boxed » qui masque la vraie cause.
    if (s.contains('converted future')) {
      return 'Une erreur technique est survenue. Réessayez ou rechargez la page.';
    }
    if (s.contains('google sign-in aborted')) {
      return 'Connexion Google annulée.';
    }
    if (s.contains('socket') ||
        s.contains('network') ||
        s.contains('client_exception') ||
        s.contains('failed host lookup') ||
        s.contains('connection')) {
      return 'Pas de connexion internet. Vérifiez votre réseau et réessayez.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  static String _auth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-not-found':
        return 'Aucun compte associé à cette adresse e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'user-disabled':
        return 'Ce compte a été désactivé. Contactez le support.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse e-mail.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Pas de connexion internet. Vérifiez votre réseau.';
      case 'requires-recent-login':
        return 'Veuillez vous reconnecter pour effectuer cette action.';
      case 'invalid-verification-code':
        return 'Code de vérification incorrect.';
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide (format international, ex. +33…).';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion est désactivée.';
      case 'google-account':
        return 'Ce compte utilise la connexion Google : connectez-vous avec Google (aucun mot de passe à réinitialiser).';
    }
    _log(e);
    return 'Connexion impossible. Veuillez réessayer.';
  }

  static String _firestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Action non autorisée.';
      case 'not-found':
        return 'Élément introuvable. Il a peut-être été supprimé.';
      case 'already-exists':
        return 'Cet élément existe déjà.';
      case 'failed-precondition':
        return 'Action impossible pour le moment. Réessayez.';
      case 'aborted':
      case 'unavailable':
        return 'Service momentanément indisponible. Réessayez.';
      case 'image-too-large':
        return 'Image trop lourde : 5 Mo maximum. Réduisez sa taille et réessayez.';
      case 'unauthorized':
        return 'Action non autorisée sur ce fichier.';
      case 'quota-exceeded':
        return 'Espace de stockage saturé. Réessayez plus tard.';
      case 'unauthenticated':
        return 'Votre session a expiré. Veuillez vous reconnecter.';
      case 'resource-exhausted':
        return 'Quota atteint. Réessayez plus tard.';
    }
    _log(e);
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  static void _log(Object e) {
    if (kDebugMode) {
      developer.log(e.toString(), name: 'fixnow.error');
    }
  }
}
