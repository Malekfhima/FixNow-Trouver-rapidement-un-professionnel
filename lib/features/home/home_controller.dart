import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/models/professional_model.dart';
import 'package:fixnow/models/user_model.dart';

/// State for the Home screen.
class HomeState {
  final List<Professional> popularPros;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.popularPros = const [],
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<Professional>? popularPros,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      popularPros: popularPros ?? this.popularPros,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller for the Home screen.
class HomeController extends StateNotifier<HomeState> {
  final FirestoreService _firestoreService;

  HomeController(this._firestoreService) : super(const HomeState()) {
    fetchData();
  }

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true);
    try {
      final pros = await _firestoreService.searchProfessionals();
      state = state.copyWith(
        popularPros: pros,
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

/// Provider for the Home controller.
final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return HomeController(firestoreService);
});

/// Provider for the current user's profile data.
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);
  
  return firestoreService.userStream(user.uid);
});
