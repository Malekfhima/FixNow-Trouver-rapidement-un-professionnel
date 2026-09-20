import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/features/notifications/notification_helpers.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:uuid/uuid.dart';

/// State for the Booking screen.
class BookingState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const BookingState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  BookingState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Controller for the Booking screen.
class BookingController extends StateNotifier<BookingState> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  BookingController(this._firestoreService, Ref ref) : _ref = ref, super(const BookingState());

  Future<void> submitRequest({
    required String proId,
    required String description,
    required String address,
    required DateTime? scheduledDate,
    double? price,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return;
    }

    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final request = ServiceRequest(
        id: const Uuid().v4(),
        clientId: user.uid,
        proId: proId,
        categoryId: 'general', // Simplified for now
        description: description,
        address: address,
        scheduledDate: scheduledDate,
        price: price,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createServiceRequest(request);

      // Notify the pro of the new request (best-effort).
      if (proId.isNotEmpty) {
        try {
          await pushNotification(
            _ref,
            userId: proId,
            type: NotificationType.generic,
            relatedId: request.id,
            title: 'Nouvelle demande',
            body: 'Un client vous a envoyé une demande de service.',
          );
        } catch (_) {}
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Client cancels their own request (allowed while pending or quoted).
  Future<String?> cancelRequest(String requestId) async {
    try {
      await _firestoreService.updateServiceRequest(requestId, {
        'status': ServiceRequestStatus.cancelled.name,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Client accepts the pro's quote -> request becomes accepted and the
  /// quoted price becomes the agreed price.
  Future<String?> acceptQuote(String requestId) async {
    try {
      final request = await _firestoreService.getRequest(requestId);
      if (request == null || request.quotePrice == null) {
        return 'Aucun devis à accepter';
      }
      await _firestoreService.updateServiceRequest(requestId, {
        'status': ServiceRequestStatus.accepted.name,
        'price': request.quotePrice,
      });

      // Notify the pro (best-effort).
      try {
        if (request.proId != null) {
          await pushNotification(
            _ref,
            userId: request.proId!,
            type: NotificationType.requestAccepted,
            relatedId: requestId,
            title: 'Devis accepté',
            body: 'Le client a accepté votre devis.',
          );
        }
      } catch (_) {}

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Provider for the Booking controller.
final bookingControllerProvider = StateNotifierProvider<BookingController, BookingState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BookingController(firestoreService, ref);
});

/// Provider for user's service requests.
final clientRequestsProvider = StreamProvider<List<ServiceRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.clientRequestsStream(user.uid);
});
