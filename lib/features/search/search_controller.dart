import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/models/professional_model.dart';

/// Sort orders for search results.
enum SearchSort { rating, priceAsc, priceDesc }

/// State for the Search screen.
class SearchState {
  /// Pros des pages Firestore chargées (non filtrés) — source des
  /// compteurs de catégories affichés sur les FilterChips.
  final List<Professional> allResults;

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

  /// True when only pros with a non-empty availability are shown.
  final bool availableOnly;

  /// Filtre rapide « Agréé Assurances » : aucun champ `insuranceAgreement`
  /// n'existe encore dans Firestore — proxy documenté côté client :
  /// pros bien notés (≥ 4.5 avec ≥ 10 avis). À brancher sur un vrai
  /// champ dès que le backend le fournit.
  final bool insuredOnly;

  /// Rayon de recherche en km (filtre client-side, actif uniquement
  /// quand une position utilisateur est connue).
  final double? radiusKm;

  const SearchState({
    this.allResults = const [],
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
    this.availableOnly = false,
    this.insuredOnly = false,
    this.radiusKm,
  });

  SearchState copyWith({
    List<Professional>? allResults,
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
    bool? availableOnly,
    bool? insuredOnly,
    double? radiusKm,
    bool clearRadius = false,
  }) {
    return SearchState(
      allResults: allResults ?? this.allResults,
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
      availableOnly: availableOnly ?? this.availableOnly,
      insuredOnly: insuredOnly ?? this.insuredOnly,
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
    );
  }

  /// Nombre de filtres actifs (badge du bouton « Filtres »).
  int get activeFilterCount {
    var count = 0;
    if (maxPrice != null) count++;
    if (minRating > 0) count++;
    if (availableOnly) count++;
    if (insuredOnly) count++;
    if (radiusKm != null) count++;
    return count;
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

  /// Position utilisateur (null tant que « Autour de moi » n'a pas été
  /// activé ou n'a pas réussi).
  GeoPoint? get userLocation => _userLocation;

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

      final rawAll = reset ? page.items : [...state.allResults, ...page.items];
      final processed = _filterAndSort(rawAll);

      state = state.copyWith(
        allResults: rawAll,
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
        // Filtre « disponible » : le pro a déclaré au moins un jour
        // d'ouverture (availability['days'] non vide).
        .where((p) => !state.availableOnly || _hasAvailability(p))
        // Filtre « Agréé assurances » : proxy (voir SearchState.insuredOnly).
        .where((p) => !state.insuredOnly || _looksInsured(p))
        // Filtre « rayon » : uniquement si une position est connue.
        .where((p) =>
            state.radiusKm == null ||
            _userLocation == null ||
            (distanceKmTo(p) ?? double.infinity) <= state.radiusKm!)
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

  /// True when the pro declared at least one opening day.
  /// `availability` est un map {'days': [..]} (voir pro_profile_edit_screen).
  static bool _hasAvailability(Professional pro) {
    final days = pro.availability?['days'];
    return days is List && days.isNotEmpty;
  }

  /// Proxy « agréé assurances » tant que le champ dédié n'existe pas :
  /// pros bien établis (note ≥ 4.5 sur ≥ 10 avis).
  static bool _looksInsured(Professional pro) =>
      pro.ratingAvg >= 4.5 && pro.ratingCount >= 10;

  /// Applies filters/sort without refetching (client-side, instant).
  void applyFilters({
    double? maxPrice,
    double? minRating,
    SearchSort? sort,
    bool? availableOnly,
    bool? insuredOnly,
    double? radiusKm,
    bool clearRadius = false,
  }) {
    state = state.copyWith(
      maxPrice: maxPrice,
      clearMaxPrice: maxPrice == null,
      minRating: minRating ?? state.minRating,
      sort: sort ?? state.sort,
      availableOnly: availableOnly ?? state.availableOnly,
      insuredOnly: insuredOnly ?? state.insuredOnly,
      radiusKm: clearRadius ? null : (radiusKm ?? state.radiusKm),
    );
    // Re-run search but keep the last query/category/location.
    search(
      query: state.query,
      category: state.selectedCategory,
      userLocation: _userLocation,
    );
  }

  /// Compteurs de catégories à partir des pages Firestore chargées :
  /// « Tous » = total chargé, chaque catégorie = nb de pros la déclarant.
  Map<String, int> categoryCounts(Iterable<String> categories) {
    final counts = <String, int>{};
    for (final category in categories) {
      if (category == 'Tous') {
        counts[category] = state.allResults.length;
        continue;
      }
      counts[category] = state.allResults
          .where((p) => p.categories.contains(category))
          .length;
    }
    return counts;
  }

  /// Distance en km jusqu'au pro (null si pas de position ou de lieu pro).
  double? distanceKmTo(Professional pro) {
    final location = _userLocation;
    final proLocation = pro.location;
    if (location == null || proLocation == null) return null;
    return _haversineKm(location, proLocation);
  }

  /// Temps d'arrivée estimé (minutes) — heuristique documentée :
  /// 8 min de préparation + 4 min par km, bornée à 60.
  int? etaMinutesFor(Professional pro) {
    final km = distanceKmTo(pro);
    if (km == null) return null;
    return (8 + 4 * km).round().clamp(5, 60);
  }

  /// Sorts pros by great-circle distance (Haversine) to the user's position.
  List<Professional> _sortByDistance(
    List<Professional> pros,
    GeoPoint userLocation,
  ) {
    final sorted = List<Professional>.from(pros);
    sorted.sort((a, b) {
      final da = distanceKmTo(a) ?? double.infinity;
      final db = distanceKmTo(b) ?? double.infinity;
      return da.compareTo(db);
    });
    return sorted;
  }

  /// Distance Haversine entre deux GeoPoints (km).
  static double _haversineKm(GeoPoint a, GeoPoint b) {
    const r = 6371.0; // Earth radius in km
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final h =
        _haversine(dLat) + math.cos(lat1) * math.cos(lat2) * _haversine(dLon);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
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
