import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/service_request_state_machine.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fixnow/features/notifications/notification_helpers.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/core/constants/app_constants.dart';
import 'package:fixnow/services/storage_service.dart';
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
    required String categoryId,
    required String description,
    required String address,
    required DateTime? scheduledDate,
    double? price,
    List<File> photos = const [],
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return;
    }

    // Client-side validation (the rules re-check server-side).
    if (description.trim().length < 10) {
      state = state.copyWith(error: 'Décrivez votre besoin en quelques mots (10 caractères minimum)');
      return;
    }
    if (address.trim().isEmpty) {
      state = state.copyWith(error: 'L\'adresse d\'intervention est requise');
      return;
    }
    if (photos.length > AppConstants.maxPhotosPerRequest) {
      state = state.copyWith(
          error: 'Maximum ${AppConstants.maxPhotosPerRequest} photos');
      return;
    }

    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final requestId = const Uuid().v4();

      // Upload photos first (compressed client-side by the picker);
      // a failure here aborts before any Firestore write.
      final photoUrls = <String>[];
      if (photos.isNotEmpty) {
        final storage = _ref.read(storageServiceProvider);
        for (var i = 0; i < photos.length; i++) {
          final url = await storage.uploadRequestPhoto(requestId, i, photos[i]);
          photoUrls.add(url);
        }
      }

      final request = ServiceRequest(
        id: requestId,
        clientId: user.uid,
        proId: proId,
        categoryId: categoryId,
        description: description.trim(),
        photos: photoUrls,
        address: address.trim(),
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
        } catch (_) {
          debugPrint('notification (new request) failed');
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      debugPrint('submitRequest failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Envoi impossible pour le moment. Vérifiez votre connexion et réessayez.',
      );
    }
  }

  /// Client cancels their own request (state machine: pending/accepted/quoted
  /// -> cancelled by client).
  Future<String?> cancelRequest(ServiceRequest request) async {
    if (!request.canBeCancelledByClient) {
      return 'Cette demande ne peut plus être annulée';
    }
    try {
      await _firestoreService.updateServiceRequest(request.id, {
        'status': ServiceRequestStatus.cancelled.name,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Client accepts the pro's quote -> request becomes accepted and the
  /// quoted price becomes the agreed price (state machine: quoted -> accepted
  /// by client).
  Future<String?> acceptQuote(ServiceRequest request) async {
    if (!request.canClientAcceptQuote) {
      return 'Aucun devis à accepter';
    }
    try {
      await _firestoreService.updateServiceRequest(request.id, {
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
            relatedId: request.id,
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
