import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/models/professional_model.dart';

/// Sort orders for search results.
enum SearchSort { rating, priceAsc, priceDesc }

/// State for the Search screen.
class SearchState {
  final List<Professional> results;
  final bool isLoading;
  final String? error;
  final String query;
  final String selectedCategory;
  final double? maxPrice;
  final double minRating;
  final SearchSort sort;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.selectedCategory = 'Tous',
    this.maxPrice,
    this.minRating = 0,
    this.sort = SearchSort.rating,
  });

  SearchState copyWith({
    List<Professional>? results,
    bool? isLoading,
    String? error,
    String? query,
    String? selectedCategory,
    double? maxPrice,
    bool clearMaxPrice = false,
    double? minRating,
    SearchSort? sort,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: minRating ?? this.minRating,
      sort: sort ?? this.sort,
    );
  }
}

/// Controller for the Search screen.
class SearchController extends StateNotifier<SearchState> {
  final FirestoreService _firestoreService;

  SearchController(this._firestoreService) : super(const SearchState());

  /// [userLocation] enables sorting by distance (Haversine) when provided.
  Future<void> search({
    String? query,
    String? category,
    GeoPoint? userLocation,
  }) async {
    state = state.copyWith(
      isLoading: true,
      query: query,
      selectedCategory: category,
    );

    try {
      final results = await _firestoreService.searchProfessionals(
        category: category == 'Tous' ? null : category,
      );

      // Client-side filtering for the search query (Firestore doesn't support full-text search out of the box)
      var filteredResults = query == null || query.isEmpty
          ? results
          : results.where((pro) {
              final proName = pro.name.toLowerCase();
              final proBio = pro.bio.toLowerCase();
              final searchTerm = query.toLowerCase();
              return proName.contains(searchTerm) || proBio.contains(searchTerm);
            }).toList();

      // Filters: min rating, max price.
      filteredResults = filteredResults
          .where((p) => p.ratingAvg >= state.minRating)
          .where((p) =>
              state.maxPrice == null || p.hourlyRate <= state.maxPrice!)
          .toList();

      // Sorting.
      if (userLocation != null) {
        filteredResults = _sortByDistance(filteredResults, userLocation);
      } else {
        switch (state.sort) {
          case SearchSort.rating:
            filteredResults.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
            break;
          case SearchSort.priceAsc:
            filteredResults.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
            break;
          case SearchSort.priceDesc:
            filteredResults.sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
            break;
        }
      }

      state = state.copyWith(
        results: filteredResults,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Recherche impossible pour le moment. Réessayez.',
      );
    }
  }

  /// Applies filters/sort without refetching (client-side, instant).
  void applyFilters({double? maxPrice, double? minRating, SearchSort? sort}) {
    state = state.copyWith(
      maxPrice: maxPrice,
      clearMaxPrice: maxPrice == null,
      minRating: minRating ?? state.minRating,
      sort: sort ?? state.sort,
    );
    // Re-run search but keep the last query/category (uses cached fetch).
    search(query: state.query, category: state.selectedCategory);
  }

  /// Sorts pros by great-circle distance (Haversine) to the user's position.
  List<Professional> _sortByDistance(
    List<Professional> pros,
    GeoPoint userLocation,
  ) {
    double distanceKm(Professional pro) {
      final loc = pro.location;
      if (loc == null) return double.infinity;
      const r = 6371.0; // Earth radius in km
      final dLat = _degToRad(loc.latitude - userLocation.latitude);
      final dLon = _degToRad(loc.longitude - userLocation.longitude);
      final lat1 = _degToRad(userLocation.latitude);
      final lat2 = _degToRad(loc.latitude);
      final a =
          _haversine(dLat) + math.cos(lat1) * math.cos(lat2) * _haversine(dLon);
      return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    }

    final sorted = List<Professional>.from(pros);
    sorted.sort((a, b) => distanceKm(a).compareTo(distanceKm(b)));
    return sorted;
  }

  static double _degToRad(double deg) => deg * math.pi / 180.0;

  static double _haversine(double x) {
    final s = math.sin(x / 2);
    return s * s;
  }

  void updateQuery(String query) {
    search(query: query, category: state.selectedCategory);
  }

  void updateCategory(String category) {
    search(query: state.query, category: category);
  }
}

/// Provider for the Search controller.
final searchControllerProvider = StateNotifierProvider<SearchController, SearchState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return SearchController(firestoreService);
});
