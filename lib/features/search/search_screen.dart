import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/search/search_controller.dart';
import 'package:fixnow/features/search/search_pro_card.dart';
import 'package:fixnow/models/professional_model.dart';

/// Écran Recherche — interface hybride « Carte + Liste » :
/// - SearchBar Material 3 (retour, micro, filtres avec badge) ;
/// - FilterChips catégories avec compteurs + filtres rapides à icônes ;
/// - mini-map OpenStreetMap (flutter_map, sans clé API) avec marqueurs
///   de prix + état en direct, bascule Liste / Carte, géolocalisation ;
/// - grandes cartes artisans (`SearchProCard`) ;
/// - FAB étendu « Filtres (N) » ouvrant le bottomSheet des filtres
///   avancés (tarif, rayon, note minimale).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  /// Mode d'affichage : liste (défaut, sans réseau) ou carte.
  bool _mapMode = false;

  /// Centre de la mini-map (défaut : Paris).
  LatLng _mapCenter = const LatLng(48.8566, 2.3522);

  // Noms identiques à ceux enregistrés dans Firestore (pro.categories) —
  // garantit que le filtre `arrayContains` fonctionne.
  final _categories = [
    'Tous',
    'Plomberie',
    'Électricité',
    'Menuiserie',
    'Peinture',
    'Maçonnerie',
    'Soudure',
    'Couverture',
    'Ménage',
    'Serrurerie',
    'Mécanique',
  ];

  @override
  void initState() {
    super.initState();

    // Check for initial category in query params.
    // GoRouter.maybeOf : l'écran reste montable même hors route GoRouter
    // (tests widget, deep-link raté) — aucune exception non gérée.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = GoRouter.maybeOf(context);
      final category = router?.state.uri.queryParameters['category'];
      if (category != null && _categories.contains(category)) {
        ref.read(searchControllerProvider.notifier).updateCategory(category);
      } else {
        ref.read(searchControllerProvider.notifier).search();
      }
    });

    // Pagination : charge la page suivante ~300 px avant la fin de la liste.
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 300) {
        ref.read(searchControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final counts =
        ref.read(searchControllerProvider.notifier).categoryCounts(_categories);
    final activeFilters = searchState.activeFilterCount;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'search_filters',
        onPressed: () => _openAdvancedFilters(context, searchState),
        icon: const Icon(Icons.tune_rounded),
        label: Text('Filtres ($activeFilters)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildSearchBar(context),
            const SizedBox(height: AppSpacing.md),

            // ── Ligne 1 : catégories avec compteurs.
            _buildCategoryChips(context, searchState, counts),
            const SizedBox(height: AppSpacing.sm),

            // ── Ligne 2 : filtres rapides à icônes.
            _buildQuickFilters(context, searchState),
            const SizedBox(height: AppSpacing.md),

            // ── Résultats : header + bascule Liste / Carte.
            _buildResultsHeader(context, searchState),
            if (_mapMode) ...[
              const SizedBox(height: AppSpacing.md),
              _buildMiniMap(context, searchState),
            ],
            const SizedBox(height: AppSpacing.md),

            // ── Liste des artisans.
            Expanded(
              child: searchState.isLoading
                  ? const ProCardSkeletonList()
                  : searchState.error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(searchState.error ?? 'Erreur'),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(searchControllerProvider.notifier)
                                    .search(
                                      query: searchState.query,
                                      category:
                                          searchState.selectedCategory,
                                    ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : searchState.results.isEmpty
                          ? _buildEmptyState()
                          : _buildResultsList(context, searchState),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  // ── SearchBar Material 3 ─────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final activeFilters = searchState.activeFilterCount;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          // Bouton retour (pop).
          IconButton(
            tooltip: 'Retour',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SearchBar(
              controller: _searchController,
              hintText: 'Plomberie, fuite d\'eau, serrurier…',
              hintStyle: WidgetStatePropertyAll(
                AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              ),
              textStyle: WidgetStatePropertyAll(
                AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
              ),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(cs.surface),
              side: WidgetStatePropertyAll(
                BorderSide(color: cs.outlineVariant),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
              onChanged: (value) =>
                  ref.read(searchControllerProvider.notifier).updateQuery(value),
              trailing: [
                // Bouton micro (reconnaissance vocale — bientôt disponible).
                IconButton(
                  tooltip: 'Recherche vocale',
                  onPressed: () => AppAlerts.info(
                    context,
                    'La recherche vocale arrive bientôt !',
                  ),
                  icon: Icon(Icons.mic_none_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                ),
                // Bouton filtres avec badge numérique des filtres actifs.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Filtres avancés',
                      onPressed: () =>
                          _openAdvancedFilters(context, searchState),
                      icon: const Icon(Icons.tune_rounded,
                          size: 20, color: AppColors.primary),
                    ),
                    if (activeFilters > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(minHeight: 15),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.fullAll,
                          ),
                          child: Text(
                            '$activeFilters',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ligne 1 : catégories avec compteurs ─────────────────────────────

  Widget _buildCategoryChips(
    BuildContext context,
    SearchState searchState,
    Map<String, int> counts,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          for (final category in _categories) ...[
            FilterChip(
              selected: searchState.selectedCategory == category,
              onSelected: (_) => ref
                  .read(searchControllerProvider.notifier)
                  .updateCategory(category),
              label: Text('${category == 'Tous' ? 'Tous' : category}'
                  ' (${counts[category] ?? 0})'),
              labelStyle: AppTextStyles.buttonSmall.copyWith(
                color: searchState.selectedCategory == category
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              showCheckmark: false,
              selectedColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  // ── Ligne 2 : filtres rapides ────────────────────────────────────────

  Widget _buildQuickFilters(BuildContext context, SearchState searchState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          _QuickFilterChip(
            icon: Icons.bolt_rounded,
            label: 'Dispo immédiate (< 30 min)',
            selected: searchState.availableOnly,
            tooltip: 'Pros disponibles cette semaine',
            onTap: () => ref
                .read(searchControllerProvider.notifier)
                .applyFilters(availableOnly: !searchState.availableOnly),
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickFilterChip(
            icon: Icons.star_rounded,
            label: '4.8+',
            selected: searchState.minRating >= 4.8,
            tooltip: 'Note minimale 4.8',
            onTap: () => ref
                .read(searchControllerProvider.notifier)
                .applyFilters(
                    minRating: searchState.minRating >= 4.8 ? 0 : 4.8),
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickFilterChip(
            icon: Icons.euro_rounded,
            label: '≤ 50€/h',
            selected: searchState.maxPrice == 50,
            tooltip: 'Tarif maximum 50 €/h',
            onTap: () => ref
                .read(searchControllerProvider.notifier)
                .applyFilters(
                    maxPrice: searchState.maxPrice == 50 ? null : 50),
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickFilterChip(
            icon: Icons.verified_user_rounded,
            label: 'Agréé Assurances',
            selected: searchState.insuredOnly,
            tooltip: 'Pros agréés par les assurances partenaires',
            onTap: () => ref
                .read(searchControllerProvider.notifier)
                .applyFilters(insuredOnly: !searchState.insuredOnly),
          ),
        ],
      ),
    );
  }

  // ── Header résultats + bascule Liste / Carte ─────────────────────────

  Widget _buildResultsHeader(BuildContext context, SearchState searchState) {
    final cs = Theme.of(context).colorScheme;
    // LayoutBuilder : sur écran étroit (< 400 dp) le tri et la bascule
    // passent en mode icône seule — le compteur reste lisible et la
    // rangée ne déborde jamais (320 dp × 1.5×).
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              // Flexible : le compteur passe sur 2 lignes plutôt que de
              // déborder à 320 dp × 1.5×.
              Flexible(
                child: Text(
                  '${searchState.results.length} professionnels',
                  style: AppTextStyles.h3.copyWith(color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),

              // Tri compact (menu popup) : meilleur tri que de reprendre
              // les 3 dropdowns de l'ancienne UI.
              PopupMenuButton<SearchSort>(
                tooltip: 'Trier par',
                onSelected: (sort) => ref
                    .read(searchControllerProvider.notifier)
                    .applyFilters(sort: sort),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SearchSort.rating,
                    child: Text('Meilleures notes'),
                  ),
                  PopupMenuItem(
                    value: SearchSort.priceAsc,
                    child: Text('Prix croissant'),
                  ),
                  PopupMenuItem(
                    value: SearchSort.priceDesc,
                    child: Text('Prix décroissant'),
                  ),
                ],
                child: narrow
                    ? Icon(Icons.sort_rounded,
                        size: 20, color: cs.onSurfaceVariant)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort_rounded,
                              size: 18, color: cs.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Trier',
                            style: AppTextStyles.label.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Bascule Liste / Carte (icônes seules sur écran étroit).
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.view_list_rounded, size: 16),
                    label: narrow ? null : const Text('Liste'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: narrow ? null : const Text('Carte'),
                  ),
                ],
                selected: {_mapMode},
                onSelectionChanged: (selection) {
                  setState(() => _mapMode = selection.first);
                  if (_mapMode) _centerMapOnResults();
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    AppTextStyles.buttonSmall.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mini-map OpenStreetMap ───────────────────────────────────────────

  Widget _buildMiniMap(BuildContext context, SearchState searchState) {
    final cs = Theme.of(context).colorScheme;
    // Seuls les pros géolocalisés apparaissent sur la carte.
    final locatedPros =
        searchState.results.where((p) => p.location != null).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.xlAll,
            child: SizedBox(
              height: 200,
              child: fm.FlutterMap(
                options: fm.MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 11,
                  interactionOptions: const fm.InteractionOptions(
                    flags: fm.InteractiveFlag.pinchZoom |
                        fm.InteractiveFlag.drag,
                  ),
                ),
                children: [
                  fm.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fixnow.app',
                  ),
                  // Marqueurs personnalisés : prix (« 45€/h ») + état
                  // en direct (point vert/orange).
                  fm.MarkerLayer(
                    markers: [
                      for (final pro in locatedPros)
                        fm.Marker(
                          point: LatLng(
                            pro.location!.latitude,
                            pro.location!.longitude,
                          ),
                          width: 76,
                          height: 34,
                          child: GestureDetector(
                            onTap: () => context.push('/pro/${pro.uid}'),
                            child: _PriceMarker(
                              price: pro.hourlyRate,
                              available: _hasAvailability(pro),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bouton flottant « Autour de moi » (géolocalisation).
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: FloatingActionButton.small(
              heroTag: 'search_geolocate',
              tooltip: 'Autour de moi',
              backgroundColor: cs.surface,
              foregroundColor: AppColors.primary,
              onPressed: _geolocate,
              child: const Icon(Icons.my_location_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Centre la carte sur le premier pro géolocalisé (sinon Paris).
  void _centerMapOnResults() {
    final searchState = ref.read(searchControllerProvider);
    final first = searchState.results
        .where((p) => p.location != null)
        .firstOrNull;
    if (first != null) {
      setState(() {
        _mapCenter =
            LatLng(first.location!.latitude, first.location!.longitude);
      });
    }
  }

  /// Géolocalisation « Autour de moi » : permission → position →
  /// recherche triée par distance + recentrage de la carte.
  Future<void> _geolocate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppAlerts.warning(
            context,
            'Autorisez la localisation pour trouver des pros autour de vous.',
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      await ref.read(searchControllerProvider.notifier).search(
            query: ref.read(searchControllerProvider).query,
            category: ref.read(searchControllerProvider).selectedCategory,
            userLocation: GeoPoint(position.latitude, position.longitude),
          );
      setState(() {
        _mapCenter =
            LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        AppAlerts.fromError(context, e);
      }
    }
  }

  /// True when the pro declared at least one opening day (mirror du
  /// contrôleur, utilisé pour la couleur des marqueurs).
  static bool _hasAvailability(Professional pro) {
    final days = pro.availability?['days'];
    return days is List && days.isNotEmpty;
  }

  // ── Liste des résultats ─────────────────────────────────────────────

  Widget _buildResultsList(BuildContext context, SearchState searchState) {
    final notifier = ref.read(searchControllerProvider.notifier);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: searchState.results.length +
          (searchState.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        if (index >= searchState.results.length) {
          // Pied de liste : chargement de la page suivante.
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        final pro = searchState.results[index];
        final distance = notifier.distanceKmTo(pro);
        return SearchProCard(
          name: pro.name,
          category:
              pro.categories.isNotEmpty ? pro.categories.first : 'Artisan',
          categoryColor: _categoryColor(pro),
          categoryBgColor: _categoryBgColor(pro),
          rating: pro.ratingAvg,
          reviewCount: pro.ratingCount,
          price: pro.hourlyRate,
          imageUrl: pro.avatarUrl,
          available: _hasAvailability(pro),
          distanceKm: distance,
          etaMinutes: notifier.etaMinutesFor(pro),
          badges: _badgesFor(pro),
          onViewProfile: () => context.push('/pro/${pro.uid}'),
          onMessage: () => context.push('/chat/new?proId=${pro.uid}'),
          onBook: () => context.push('/booking/new?proId=${pro.uid}'),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Aucun professionnel trouvé',
      message: 'Essayez une autre catégorie ou retirez vos filtres.',
      actionLabel: 'Réinitialiser les filtres',
      onAction: () {
        ref.read(searchControllerProvider.notifier).applyFilters(
              maxPrice: null,
              minRating: 0,
              sort: SearchSort.rating,
              availableOnly: false,
              insuredOnly: false,
              clearRadius: true,
            );
      },
    );
  }

  // ── BottomSheet des filtres avancés ──────────────────────────────────

  void _openAdvancedFilters(BuildContext context, SearchState searchState) {
    final notifier = ref.read(searchControllerProvider.notifier);
    final hasLocation = notifier.userLocation != null;

    // Valeurs locales du sheet (confirmées par « Appliquer »).
    var maxPrice = searchState.maxPrice ?? 100.0;
    var minRating = searchState.minRating;
    var radiusKm = searchState.radiusKm ?? 5.0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtres avancés', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.lg),

              // ── Tarif max (0–100 €/h ; 100 = pas de filtre).
              Text(
                maxPrice >= 100
                    ? 'Tarif : tous les prix'
                    : 'Tarif max : ${maxPrice.toStringAsFixed(0)} €/h',
                style: AppTextStyles.bodyMedium,
              ),
              Slider(
                value: maxPrice,
                min: 15,
                max: 100,
                divisions: 17,
                label: maxPrice >= 100 ? '∞' : '${maxPrice.toStringAsFixed(0)} €',
                onChanged: (v) => setSheetState(() => maxPrice = v),
              ),

              // ── Rayon en km (actif seulement avec une position).
              Text(
                hasLocation
                    ? 'Rayon : ${radiusKm.toStringAsFixed(0)} km'
                    : 'Rayon : activez « Autour de moi » sur la carte',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasLocation
                      ? Theme.of(sheetContext).colorScheme.onSurface
                      : Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              Slider(
                value: radiusKm,
                min: 1,
                max: 25,
                divisions: 24,
                label: '${radiusKm.toStringAsFixed(0)} km',
                onChanged: hasLocation ? (v) => setSheetState(() => radiusKm = v) : null,
              ),

              // ── Note minimale (0–5 ★).
              Text(
                minRating <= 0
                    ? 'Note : toutes'
                    : 'Note minimale : ${minRating.toStringAsFixed(1)} ★',
                style: AppTextStyles.bodyMedium,
              ),
              Slider(
                value: minRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: minRating <= 0 ? 'Toutes' : '${minRating.toStringAsFixed(1)} ★',
                onChanged: (v) => setSheetState(() => minRating = v),
              ),

              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        // Réinitialisation rapide depuis le sheet.
                        ref
                            .read(searchControllerProvider.notifier)
                            .applyFilters(
                              maxPrice: null,
                              minRating: 0,
                              insuredOnly: false,
                              availableOnly: false,
                              clearRadius: true,
                            );
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        ref
                            .read(searchControllerProvider.notifier)
                            .applyFilters(
                              maxPrice: maxPrice >= 100 ? null : maxPrice,
                              minRating: minRating,
                              radiusKm: hasLocation ? radiusKm : null,
                              clearRadius: !hasLocation,
                            );
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers catégories / badges ───────────────────────────────────────

  /// Badges de garanties affichés sur la carte :
  /// - « SIRET vérifié » : tous les pros (statut `approved` contrôlé
  ///   côté Firestore avant publication) ;
  /// - « Garantie Décennale » : métiers du gros œuvre (obligation légale) ;
  /// - « Agréé assurances » : proxy note ≥ 4.5 / ≥ 10 avis (le champ
  ///   dédié n'existe pas encore — voir SearchState.insuredOnly).
  List<String> _badgesFor(Professional pro) {
    final badges = <String>['SIRET vérifié'];
    const structural = {'Maçonnerie', 'Couverture'};
    if (pro.categories.any(structural.contains)) {
      badges.add('Garantie Décennale');
    }
    if (pro.ratingAvg >= 4.5 && pro.ratingCount >= 10) {
      badges.add('Agréé assurances');
    }
    return badges;
  }

  static const Map<String, Color> _categoryColors = {
    'Plomberie': AppColors.plomberie,
    'Électricité': AppColors.electricite,
    'Électricien': AppColors.electricite,
    'Menuiserie': AppColors.menuiserie,
    'Peinture': AppColors.peinture,
    'Maçonnerie': AppColors.maconnerie,
    'Soudure': AppColors.soudure,
    'Couverture': AppColors.couverture,
    'Ménage': AppColors.menage,
    'Serrurerie': AppColors.serrurerie,
    'Mécanique': AppColors.mecanique,
  };

  static const Map<String, Color> _categoryBgColors = {
    'Plomberie': AppColors.plomberieLight,
    'Électricité': AppColors.electriciteLight,
    'Électricien': AppColors.electriciteLight,
    'Menuiserie': AppColors.menuiserieLight,
    'Peinture': AppColors.peintureLight,
    'Maçonnerie': AppColors.maconnerieLight,
    'Soudure': AppColors.soudureLight,
    'Couverture': AppColors.couvertureLight,
    'Ménage': AppColors.menageLight,
    'Serrurerie': AppColors.serrurerieLight,
    'Mécanique': AppColors.mecaniqueLight,
  };

  Color _categoryColor(Professional pro) {
    if (pro.categories.isEmpty) return AppColors.primary;
    final base = _categoryColors[pro.categories.first] ?? AppColors.primary;
    // En sombre : mélanger vers la couleur de texte du thème.
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.lerp(base, Theme.of(context).colorScheme.onSurface, 0.35)!;
    }
    return base;
  }

  Color _categoryBgColor(Professional pro) {
    if (pro.categories.isEmpty) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    final base =
        _categoryBgColors[pro.categories.first] ?? Theme.of(context).colorScheme.primaryContainer;
    // En sombre : mélanger vers la surface du thème.
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.lerp(base, Theme.of(context).colorScheme.surface, 0.65)!;
    }
    return base;
  }
}

/// Marqueur de prix personnalisé (« 45€/h ») avec point de statut
/// vert/orange — utilisé sur la mini-map.
class _PriceMarker extends StatelessWidget {
  final double price;
  final bool available;

  const _PriceMarker({required this.price, required this.available});

  @override
  Widget build(BuildContext context) {
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = available
        ? (onDark ? const Color(0xFF4ADE80) : AppColors.success)
        : (onDark ? const Color(0xFFFBBF24) : AppColors.warning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '${price.toStringAsFixed(0)}€/h',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip compact des filtres rapides (icône + libellé, état sélectionné).
class _QuickFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: cs.surface,
        side: BorderSide(
          color: selected ? AppColors.primary : cs.outlineVariant,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? Colors.white : AppColors.primary,
        ),
        label: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
