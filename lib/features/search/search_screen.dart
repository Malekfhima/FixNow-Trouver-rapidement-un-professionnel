import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/pro_card.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/search/search_controller.dart';
import 'package:fixnow/models/professional_model.dart';

/// Search screen with filters and professional listings.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

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
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Check for initial category in query params.
    // GoRouter.maybeOf : l'écran reste montable même hors route GoRouter
    // (tests widget, deep-link raté) — aucune exception non gérée.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = GoRouter.maybeOf(context);
      final category = router?.state.uri.queryParameters['category'];
      if (category != null && _categories.contains(category)) {
        final index = _categories.indexOf(category);
        _tabController.animateTo(index);
        ref.read(searchControllerProvider.notifier).updateCategory(category);
      } else {
        ref.read(searchControllerProvider.notifier).search();
      }
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(searchControllerProvider.notifier).updateCategory(_categories[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Rechercher'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref.read(searchControllerProvider.notifier).updateQuery(value),
              decoration: InputDecoration(
                hintText: 'Rechercher un service ou un pro...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        tooltip: 'Effacer la recherche',
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchControllerProvider.notifier).updateQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filters bar: sort + min rating + max price (scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                _FilterDropdown<SearchSort>(
                  value: searchState.sort,
                  label: 'Trier par',
                  icon: Icons.sort_rounded,
                  width: 200,
                  items: const [
                    DropdownMenuItem(
                      value: SearchSort.rating,
                      child: Text('Meilleures notes', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: SearchSort.priceAsc,
                      child: Text('Prix croissant', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: SearchSort.priceDesc,
                      child: Text('Prix décroissant', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (v) => ref
                      .read(searchControllerProvider.notifier)
                      .applyFilters(sort: v),
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterDropdown<double>(
                  value: searchState.minRating,
                  label: 'Note min.',
                  icon: Icons.star_rounded,
                  width: 140,
                  items: const [
                    DropdownMenuItem(value: 0.0, child: Text('Toutes', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 3.0, child: Text('3+ ★', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 4.0, child: Text('4+ ★', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 4.5, child: Text('4.5+ ★', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => ref
                      .read(searchControllerProvider.notifier)
                      .applyFilters(minRating: v ?? 0),
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterDropdown<double?>(
                  value: searchState.maxPrice,
                  label: 'Prix max',
                  icon: Icons.euro_rounded,
                  width: 140,
                  items: const [
                    DropdownMenuItem<double?>(value: null, child: Text('Tous', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem<double?>(value: 30, child: Text('≤ 30 €', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem<double?>(value: 50, child: Text('≤ 50 €', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem<double?>(value: 75, child: Text('≤ 75 €', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => ref
                      .read(searchControllerProvider.notifier)
                      .applyFilters(maxPrice: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            labelStyle: AppTextStyles.buttonMedium,
            unselectedLabelStyle: AppTextStyles.buttonMedium,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: _categories.map((c) => Tab(text: c)).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Results
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
                                    category: searchState.selectedCategory,
                                  ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : searchState.results.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            itemCount: searchState.results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                            itemBuilder: (context, index) {
                              final pro = searchState.results[index];
                              return ProCard(
                                name: pro.name,
                                category: pro.categories.isNotEmpty
                                    ? pro.categories.first
                                    : 'Artisan',
                                categoryColor: _categoryColor(pro),
                                categoryBgColor: _categoryBgColor(pro),
                                rating: pro.ratingAvg,
                                reviewCount: pro.ratingCount,
                                price: pro.hourlyRate,
                                imageUrl: pro.avatarUrl,
                                onViewProfile: () => context.push('/pro/${pro.uid}'),
                                onBook: () => _openBookingWithPro(pro.uid),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Aucun professionnel trouvé',
      message: 'Essayez une autre catégorie ou retirez vos filtres.',
      actionLabel: 'Réinitialiser les filtres',
      onAction: () {
        _tabController.animateTo(0);
        ref.read(searchControllerProvider.notifier).applyFilters(
              maxPrice: null,
              minRating: 0,
              sort: SearchSort.rating,
            );
      },
    );
  }

  void _openBookingWithPro(String proId) {
    context.push('/booking/new?proId=$proId');
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
    if (pro.categories.isEmpty) return Theme.of(context).colorScheme.primaryContainer;
    final base = _categoryBgColors[pro.categories.first] ?? Theme.of(context).colorScheme.primaryContainer;
    // En sombre : mélanger vers la surface du thème.
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.lerp(base, Theme.of(context).colorScheme.surface, 0.65)!;
    }
    return base;
  }
}

/// Compact filter dropdown with fixed width, dense layout and small icon.
class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData icon;
  final double width;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _FilterDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.width,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        isDense: true,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          prefixIcon: Icon(icon, size: 18),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 0,
          ),
        ),
      ),
    );
  }
}
