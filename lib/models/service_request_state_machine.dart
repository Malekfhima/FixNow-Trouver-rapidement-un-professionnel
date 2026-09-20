import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/models/service_request_model.dart';

/// Who may act on a service request.
enum ActorRole { client, pro, admin }

/// Centralized state machine for [ServiceRequest].
///
/// ALL status transitions — in the UI, the controllers and the Firestore
/// rules — must go through the transitions declared here.
///
/// Allowed flow (the "accepted" step after a quote is deliberate: the pro
/// sends a quote, the client accepts it, then the pro starts the work):
///
///   pending   -> accepted | declined | cancelled   (pro / pro / client)
///   accepted  -> inProgress | cancelled            (pro / client)
///   quoted    -> accepted (client accepts the quote) | cancelled (client)
///   inProgress-> completed                         (pro)
///
/// Terminal states: completed, declined, cancelled.
extension ServiceRequestStateMachine on ServiceRequest {
  // ── Transition table ───────────────────────────────────────────────
  static const Map<ServiceRequestStatus, Map<ServiceRequestStatus, ActorRole>>
      _transitions = {
    ServiceRequestStatus.pending: {
      ServiceRequestStatus.accepted: ActorRole.pro,
      ServiceRequestStatus.declined: ActorRole.pro,
      ServiceRequestStatus.cancelled: ActorRole.client,
    },
    ServiceRequestStatus.accepted: {
      ServiceRequestStatus.inProgress: ActorRole.pro,
      ServiceRequestStatus.cancelled: ActorRole.client,
    },
    ServiceRequestStatus.quoted: {
      ServiceRequestStatus.accepted: ActorRole.client,
      ServiceRequestStatus.cancelled: ActorRole.client,
    },
    ServiceRequestStatus.inProgress: {
      ServiceRequestStatus.completed: ActorRole.pro,
    },
    // Terminal states: no outgoing transitions.
    ServiceRequestStatus.completed: {},
    ServiceRequestStatus.declined: {},
    ServiceRequestStatus.cancelled: {},
  };

  /// Whether [to] is a valid transition from this status for [actor].
  bool canTransitionTo(ServiceRequestStatus to, ActorRole actor) {
    return _transitions[status]?[to] == actor ||
        (_transitions[status]?[to] != null && actor == ActorRole.admin);
  }

  /// All statuses this request can move to for [actor].
  List<ServiceRequestStatus> allowedTransitions(ActorRole actor) {
    final map = _transitions[status];
    if (map == null) return const [];
    if (actor == ActorRole.admin) return map.keys.toList();
    return map.entries
        .where((e) => e.value == actor)
        .map((e) => e.key)
        .toList();
  }

  bool get isTerminal =>
      status == ServiceRequestStatus.completed ||
      status == ServiceRequestStatus.declined ||
      status == ServiceRequestStatus.cancelled;

  /// Whether this request can be cancelled by the client.
  bool get canBeCancelledByClient =>
      canTransitionTo(ServiceRequestStatus.cancelled, ActorRole.client);

  /// Whether the client can accept the pending quote.
  bool get canClientAcceptQuote =>
      status == ServiceRequestStatus.quoted &&
      quotePrice != null;

  /// Whether the client can leave a review (completed and not yet reviewed
  /// is checked separately via [hasReview]).
  bool get canBeReviewed => status == ServiceRequestStatus.completed;

  // ── Presentation helpers (FR labels + semantic colors) ────────────
  String statusLabel() {
    switch (status) {
      case ServiceRequestStatus.pending: return 'En attente';
      case ServiceRequestStatus.accepted: return 'Acceptée';
      case ServiceRequestStatus.declined: return 'Refusée';
      case ServiceRequestStatus.quoted: return 'Devis reçu';
      case ServiceRequestStatus.inProgress: return 'En cours';
      case ServiceRequestStatus.completed: return 'Terminée';
      case ServiceRequestStatus.cancelled: return 'Annulée';
    }
  }

  /// Semantic token name — resolved to a concrete color by the UI layer
  /// (keeps this file Flutter-independent where possible).
  String statusColorToken() {
    switch (status) {
      case ServiceRequestStatus.pending: return 'warning';
      case ServiceRequestStatus.accepted: return 'primary';
      case ServiceRequestStatus.declined: return 'error';
      case ServiceRequestStatus.quoted: return 'accent';
      case ServiceRequestStatus.inProgress: return 'info';
      case ServiceRequestStatus.completed: return 'success';
      case ServiceRequestStatus.cancelled: return 'neutral';
    }
  }

  /// Convenience for UI code — resolves [statusColorToken] to a concrete,
  /// theme-aware color (adapts to light/dark).
  Color statusColor(BuildContext context) {
    final semantic = context.semanticColors;
    switch (statusColorToken()) {
      case 'warning': return semantic.warning;
      case 'primary': return Theme.of(context).colorScheme.primary;
      case 'error': return Theme.of(context).colorScheme.error;
      case 'accent': return semantic.accent;
      case 'info': return semantic.info;
      case 'success': return semantic.success;
      default: return semantic.neutral;
    }
  }
}
