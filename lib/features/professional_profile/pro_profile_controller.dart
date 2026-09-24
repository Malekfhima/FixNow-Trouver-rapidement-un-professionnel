import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/models/professional_model.dart';
import 'package:fixnow/models/review_model.dart';

/// State for the Professional Profile screen.
class ProProfileState {
  final Professional? pro;
  final List<Review> reviews;
  final bool isLoading;
  final String? error;

  const ProProfileState({
    this.pro,
    this.reviews = const [],
    this.isLoading = false,
    this.error,
  });

  ProProfileState copyWith({
    Professional? pro,
    List<Review>? reviews,
    bool? isLoading,
    String? error,
  }) {
    return ProProfileState(
      pro: pro ?? this.pro,
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller for the Professional Profile screen.
class ProProfileController extends StateNotifier<ProProfileState> {
  final FirestoreService _firestoreService;
  final String proId;

  ProProfileController(this._firestoreService, this.proId) : super(const ProProfileState()) {
    fetchData();
  }

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true);
    try {
      final pro = await _firestoreService.getProfessional(proId);
      final reviews = await _firestoreService.getProReviews(proId);
      
      state = state.copyWith(
        pro: pro,
        reviews: reviews,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorMapper.message(e),
      );
    }
  }
}

/// Provider for the Professional Profile controller (family provider to handle proId).
final proProfileControllerProvider = StateNotifierProvider.family<ProProfileController, ProProfileState, String>((ref, proId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProProfileController(firestoreService, proId);
});

/// Lightweight lookup of a professional by id (e.g. to show the pro name
/// on a service request card).
final proByIdProvider =
    FutureProvider.family<Professional?, String>((ref, proId) {
  return ref.watch(firestoreServiceProvider).getProfessional(proId);
});
