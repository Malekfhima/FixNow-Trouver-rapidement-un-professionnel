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

  /// True while an extra page is being fetched (scroll-to-bottom).
  final bool isLoadingMore;

  /// False once the last Firestore page has been reached.
  final bool hasMore;
  final String? error;
  final String query;
  final String selectedCategory;
  final double? maxPrice;
  final double minRating;
  final SearchSort sort;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
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
    bool? isLoadingMore,
    bool? hasMore,
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
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
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

  /// Firestore page size (a `limit` per request).
  static const int _pageSize = 20;

  /// Cursor of the last fetched page (`startAfter` for the next one).
  DocumentSnapshot? _lastDocument;

  /// Remembers the last location so re-filters keep distance sorting.
  GeoPoint? _userLocation;

  SearchController(this._firestoreService) : super(const SearchState());

  /// [userLocation] enables sorting by distance (Haversine) when provided.
  Future<void> search({
    String? query,
    String? category,
    GeoPoint? userLocation,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      query: query,
      selectedCategory: category,
    );
    _userLocation = userLocation;
    await _fetchPage(reset: true);
  }

  /// Loads the next Firestore page and appends it to [SearchState.results].
  ///
  /// Safe to call repeatedly (e.g. from a scroll listener): no-op while a
  /// page is already loading or when the last page has been reached.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetchPage(reset: false);
  }

  /// Fetches one page (first page when [reset], next page otherwise).
  Future<void> _fetchPage({required bool reset}) async {
    try {
      final category =
          state.selectedCategory == 'Tous' ? null : state.selectedCategory;

      final page = await _firestoreService.searchProfessionalsPage(
        category: category,
        limit: _pageSize,
        startAfter: reset ? null : _lastDocument,
      );

      _lastDocument = page.lastDocument;

      final combined =
          reset ? page.items : [...state.results, ...page.items];
      final processed = _filterAndSort(combined);

      state = state.copyWith(
        results: processed,
        isLoading: false,
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Recherche impossible pour le moment. Réessayez.',
      );
    }
  }

  /// Client-side search-text filtering, rating/price filters and sorting.
  ///
  /// Firestore has no full-text search: the text query is applied here on
  /// the documents of the currently loaded pages.
  List<Professional> _filterAndSort(List<Professional> pros) {
    final searchTerm = state.query.toLowerCase();
    var filtered = searchTerm.isEmpty
        ? pros
        : pros.where((pro) {
            return pro.name.toLowerCase().contains(searchTerm) ||
                pro.bio.toLowerCase().contains(searchTerm);
          }).toList();

    filtered = filtered
        .where((p) => p.ratingAvg >= state.minRating)
        .where(
            (p) => state.maxPrice == null || p.hourlyRate <= state.maxPrice!)
        .toList();

    final location = _userLocation;
    if (location != null) {
      filtered = _sortByDistance(filtered, location);
    } else {
      switch (state.sort) {
        case SearchSort.rating:
          filtered.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
          break;
        case SearchSort.priceAsc:
          filtered.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
          break;
        case SearchSort.priceDesc:
          filtered.sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
          break;
      }
    }
    return filtered;
  }

  /// Applies filters/sort without refetching (client-side, instant).
  void applyFilters({double? maxPrice, double? minRating, SearchSort? sort}) {
    state = state.copyWith(
      maxPrice: maxPrice,
      clearMaxPrice: maxPrice == null,
      minRating: minRating ?? state.minRating,
      sort: sort ?? state.sort,
    );
    // Re-run search but keep the last query/category/location.
    search(
      query: state.query,
      category: state.selectedCategory,
      userLocation: _userLocation,
    );
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
