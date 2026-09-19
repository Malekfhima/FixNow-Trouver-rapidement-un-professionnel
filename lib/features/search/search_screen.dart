import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/pro_card.dart';
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

  final _categories = [
    'Tous',
    'Plomberie',
    'Électricien',
    'Menuiserie',
    'Peinture',
    'Maçonnerie',
    'Soudure',
    'Ménage',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Check for initial category in query params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GoRouterState.of(context);
      final category = state.uri.queryParameters['category'];
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rechercher'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
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

          // Category tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
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
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null
                    ? Center(child: Text('Erreur: ${searchState.error}'))
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun professionnel trouvé',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
    return _categoryColors[pro.categories.first] ?? AppColors.primary;
  }

  Color _categoryBgColor(Professional pro) {
    if (pro.categories.isEmpty) return AppColors.primaryContainer;
    return _categoryBgColors[pro.categories.first] ?? AppColors.primaryContainer;
  }
}
