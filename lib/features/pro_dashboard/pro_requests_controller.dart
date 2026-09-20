import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/service_request_state_machine.dart';
import 'package:fixnow/features/notifications/notification_helpers.dart';
import 'package:fixnow/models/notification_model.dart';

/// State for the pro-side requests dashboard.
class ProRequestsState {
  final List<ServiceRequest> pending;
  final List<ServiceRequest> active;
  final List<ServiceRequest> history;
  final bool isLoading;
  final String? error;

  const ProRequestsState({
    this.pending = const [],
    this.active = const [],
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  ProRequestsState copyWith({
    List<ServiceRequest>? pending,
    List<ServiceRequest>? active,
    List<ServiceRequest>? history,
    bool? isLoading,
    String? error,
  }) {
    return ProRequestsState(
      pending: pending ?? this.pending,
      active: active ?? this.active,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller for the pro "My requests" screen.
class ProRequestsController extends StateNotifier<ProRequestsState> {
  final Ref _ref;

  ProRequestsController(this._ref) : super(const ProRequestsState()) {
    loadRequests();
  }

  void loadRequests() {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(isLoading: false, error: 'Non connecté');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    _ref
        .read(firestoreServiceProvider)
        .proRequestsStream(user.uid)
        .listen(
      (requests) {
        final pending = <ServiceRequest>[];
        final active = <ServiceRequest>[];
        final history = <ServiceRequest>[];

        for (final r in requests) {
          switch (r.status) {
            case ServiceRequestStatus.pending:
              pending.add(r);
              break;
            case ServiceRequestStatus.accepted:
            case ServiceRequestStatus.quoted:
            case ServiceRequestStatus.inProgress:
              active.add(r);
              break;
            case ServiceRequestStatus.completed:
            case ServiceRequestStatus.declined:
            case ServiceRequestStatus.cancelled:
              history.add(r);
              break;
          }
        }

        state = state.copyWith(
          pending: pending,
          active: active,
          history: history,
          isLoading: false,
        );
      },
      onError: (e, st) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  /// Accepts a pending request (state machine: pending -> accepted, pro).
  Future<String?> acceptRequest(ServiceRequest request) async {
    if (!request.canTransitionTo(ServiceRequestStatus.accepted, ActorRole.pro)) {
      return 'Action non autorisée pour cette demande';
    }
    return _updateAndNotify(
      request.id,
      {'status': ServiceRequestStatus.accepted.name},
      NotificationType.requestAccepted,
    );
  }

  /// Declines a pending request (state machine: pending -> declined, pro).
  Future<String?> declineRequest(ServiceRequest request) async {
    if (!request
        .canTransitionTo(ServiceRequestStatus.declined, ActorRole.pro)) {
      return 'Action non autorisée pour cette demande';
    }
    return _updateAndNotify(
      request.id,
      {'status': ServiceRequestStatus.declined.name},
      NotificationType.requestDeclined,
    );
  }

  /// Sends a quote for a pending request.
  ///
  /// NOTE: status stays 'pending' + quote fields set — the request only
  /// moves to 'quoted'... actually keeps 'pending' so the client simply
  /// sees the quote and accepts (pending -> accepted). This avoids a
  /// second status concept for "quote sent".
  Future<String?> sendQuote({
    required ServiceRequest request,
    required double price,
    required String note,
  }) async {
    if (!request.canTransitionTo(ServiceRequestStatus.accepted, ActorRole.pro) &&
        request.status != ServiceRequestStatus.pending) {
      return 'Action non autorisée pour cette demande';
    }
    try {
      await _ref.read(firestoreServiceProvider).updateServiceRequest(
            request.id,
            {
              'status': ServiceRequestStatus.quoted.name,
              'quotePrice': price,
              'quoteNote': note,
            },
          );
    } catch (e) {
      return e.toString();
    }

    try {
      final updated = await _ref.read(firestoreServiceProvider).getRequest(request.id);
      if (updated?.clientId != null) {
        await pushNotification(
          _ref,
          userId: updated!.clientId,
          type: NotificationType.quoteReceived,
          relatedId: request.id,
          title: NotificationCopy.titleFor(NotificationType.quoteReceived),
          body: 'Devis de ${price.toStringAsFixed(0)} €'
              '${note.isNotEmpty ? ' — $note' : ''}',
        );
      }
    } catch (_) {}
    return null;
  }

  /// Marks a request as in progress (state machine: accepted -> inProgress).
  Future<String?> startWork(ServiceRequest request) async {
    if (!request
        .canTransitionTo(ServiceRequestStatus.inProgress, ActorRole.pro)) {
      return 'Action non autorisée pour cette demande';
    }
    return _update(request.id, {'status': ServiceRequestStatus.inProgress.name});
  }

  /// Marks a request as completed (state machine: inProgress -> completed).
  Future<String?> completeWork(ServiceRequest request) async {
    if (!request
        .canTransitionTo(ServiceRequestStatus.completed, ActorRole.pro)) {
      return 'Action non autorisée pour cette demande';
    }
    return _updateAndNotify(
      request.id,
      {'status': ServiceRequestStatus.completed.name},
      NotificationType.requestCompleted,
    );
  }

  /// Updates the request then notifies the client.
  Future<String?> _updateAndNotify(
    String requestId,
    Map<String, dynamic> data,
    NotificationType type,
  ) async {
    final error = await _update(requestId, data);
    if (error != null) return error;

    try {
      final request = await _ref
          .read(firestoreServiceProvider)
          .getRequest(requestId);
      if (request?.clientId != null) {
        await pushNotification(
          _ref,
          userId: request!.clientId,
          type: type,
          relatedId: requestId,
          title: NotificationCopy.titleFor(type),
          body: NotificationCopy.bodyForRequest(
            ServiceRequestStatus.values
                .firstWhere((s) => s.name == data['status']),
            'Le professionnel',
          ),
        );
      }
    } catch (_) {
      // Notification is best-effort; the status update already succeeded.
    }
    return null;
  }

  Future<String?> _update(String requestId, Map<String, dynamic> data) async {
    try {
      await _ref.read(firestoreServiceProvider).updateServiceRequest(
            requestId,
            data,
          );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Provider for the pro requests controller.
final proRequestsControllerProvider =
    StateNotifierProvider<ProRequestsController, ProRequestsState>((ref) {
  return ProRequestsController(ref);
});
