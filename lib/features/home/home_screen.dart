import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';
import 'package:fixnow/core/widgets/service_icon_card.dart';
import 'package:fixnow/core/widgets/pro_card.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/features/notifications/notifications_controller.dart';

/// Client Home screen — reproduces the main layout from the mockups.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openBookingWithPro(BuildContext context, String proId) {
    context.push('/booking/new?proId=$proId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeControllerProvider.notifier).fetchData(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildHeader(context, ref, userProfile.valueOrNull),
                const SizedBox(height: AppSpacing.xl),
                _buildSearchBar(context),
                const SizedBox(height: AppSpacing.xl),
                _buildPromoBanner(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildServicesGrid(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildPopularSection(context, ref, homeState),
                const SizedBox(height: AppSpacing.xxxxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          // Avatar
          AppAvatar(
            url: user?.avatarUrl,
            radius: 24,
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour 👋',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  user?.name ?? 'Utilisateur',
                  style: AppTextStyles.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Notification bell with badge (zone tactile 48 dp + tooltip)
          IconButton(
            tooltip: 'Voir les notifications',
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                // Badge — compteur réel de notifications non lues (AA).
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minHeight: 16),
                      decoration: BoxDecoration(
                        color: context.semanticColors.accent,
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.xlAll,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Rechercher un service...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Promo Banner ───────────────────────────────────────────────────

  Widget _buildPromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.xlAll,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      'OFFRE LIMITÉE',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Économisez 25%',
                    style: AppTextStyles.h2.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'aujourd\'hui !',
                    style: AppTextStyles.h2.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sur votre premier service réservé',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/search');
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Réserver maintenant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      textStyle: AppTextStyles.buttonMedium,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdAll,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Artisan illustration placeholder
            const SizedBox(width: AppSpacing.lg),
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.15),
                borderRadius: AppRadius.lgAll,
              ),
              child: Center(
                child: Icon(
                  Icons.engineering_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Services Grid ──────────────────────────────────────────────────

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      // `category` = nom exact utilisé dans Firestore (pro.categories) pour
      // que le filtre de l'écran Recherche fonctionne directement.
      _ServiceItem(Icons.plumbing_rounded, 'Plombier', AppColors.plomberie, AppColors.plomberieLight, 'Plomberie'),
      _ServiceItem(Icons.electrical_services_rounded, 'Électricien', AppColors.electricite, AppColors.electriciteLight, 'Électricité'),
      _ServiceItem(Icons.carpenter_rounded, 'Menuisier', AppColors.menuiserie, AppColors.menuiserieLight, 'Menuiserie'),
      _ServiceItem(Icons.format_paint_rounded, 'Peintre', AppColors.peinture, AppColors.peintureLight, 'Peinture'),
      _ServiceItem(Icons.construction_rounded, 'Maçon', AppColors.maconnerie, AppColors.maconnerieLight, 'Maçonnerie'),
      _ServiceItem(Icons.build_circle_rounded, 'Soudeur', AppColors.soudure, AppColors.soudureLight, 'Soudure'),
      _ServiceItem(Icons.home_repair_service_rounded, 'Couvreur', AppColors.couverture, AppColors.couvertureLight, 'Couverture'),
      _ServiceItem(Icons.more_horiz_rounded, 'Voir plus', Theme.of(context).colorScheme.onSurfaceVariant, AppColors.soudureLight, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text('Services les plus réservés', style: AppTextStyles.h3),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.sm,
              // Cellules assez hautes pour icône + libellé même à
              // 1.5× de facteur de texte (aucun overflow sur 320 dp).
              childAspectRatio: 0.65,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              return ServiceIconCard(
                icon: s.icon,
                label: s.label,
                iconColor: s.color,
                backgroundColor: s.bgColor,
                onTap: () => context.push(
                  s.category == null
                      ? '/search'
                      : '/search?category=${Uri.encodeComponent(s.category!)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Popular Section ────────────────────────────────────────────────

  Widget _buildPopularSection(BuildContext context, WidgetRef ref, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              // Flexible : le titre passe sur 2 lignes plutôt que de
              // déborder à 320 dp × 1.5 de facteur de texte.
              const Flexible(
                child: Text(
                  'Populaire près de vous',
                  style: AppTextStyles.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => context.push('/search'),
                child: Text(
                  'Voir tout',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.isLoading)
          const ProCardSkeletonRow()
        else if (state.error != null)
          ErrorState(
            error: state.error,
            onRetry: () => ref.read(homeControllerProvider.notifier).fetchData(),
          )
        else if (state.popularPros.isEmpty)
          EmptyState(
            icon: Icons.handyman_outlined,
            title: 'Aucun professionnel trouvé',
            message: 'Les professionnels disponibles apparaîtront ici.',
            actionLabel: 'Voir tout',
            onAction: () => context.push('/search'),
          )
        else
          SizedBox(
            // Assez haut pour la carte à 1.5× de facteur de texte
            // (icône + nom + prix + 2 boutons de 48 dp).
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: state.popularPros.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
              itemBuilder: (context, index) {
                final pro = state.popularPros[index];
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: ProCard(
                    name: pro.name,
                    category: pro.categories.isNotEmpty ? pro.categories.first : 'Artisan',
                    categoryColor: _categoryColor(context, pro.categories.firstOrNull),
                    categoryBgColor: _categoryBgColor(context, pro.categories.firstOrNull),
                    rating: pro.ratingAvg,
                    reviewCount: pro.ratingCount,
                    price: pro.hourlyRate,
                    imageUrl: pro.avatarUrl,
                    onViewProfile: () => context.push('/pro/${pro.uid}'),
                    onBook: () => _openBookingWithPro(context, pro.uid),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Local helpers ──────────────────────────────────────────────────────

  Color _categoryColor(BuildContext context, String? category) {
    // Clés = noms de catégories tels qu'enregistrés dans Firestore.
    final map = <String, Color>{
      'Plomberie': AppColors.plomberie,
      'Électricité': AppColors.electricite,
      'Menuiserie': AppColors.menuiserie,
      'Peinture': AppColors.peinture,
      'Maçonnerie': AppColors.maconnerie,
      'Soudure': AppColors.soudure,
      'Couverture': AppColors.couverture,
      'Ménage': AppColors.menage,
      'Serrurerie': AppColors.serrurerie,
      'Mécanique': AppColors.mecanique,
      'Artisan': Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final base = map[category] ?? Theme.of(context).colorScheme.onSurfaceVariant;
    // En sombre : mélanger vers la couleur de texte du thème (jamais de
    // blanc « en dur ») pour garder le contraste.
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.lerp(base, Theme.of(context).colorScheme.onSurface, 0.35)!;
    }
    return base;
  }

  Color _categoryBgColor(BuildContext context, String? category) {
    // Clés = noms de catégories tels qu'enregistrés dans Firestore.
    final map = <String, Color>{
      'Plomberie': AppColors.plomberieLight,
      'Électricité': AppColors.electriciteLight,
      'Menuiserie': AppColors.menuiserieLight,
      'Peinture': AppColors.peintureLight,
      'Maçonnerie': AppColors.maconnerieLight,
      'Soudure': AppColors.soudureLight,
      'Couverture': AppColors.couvertureLight,
      'Ménage': AppColors.menageLight,
      'Serrurerie': AppColors.serrurerieLight,
      'Mécanique': AppColors.mecaniqueLight,
      'Artisan': AppColors.soudureLight,
    };
    final base = map[category] ?? AppColors.soudureLight;
    // En sombre : mélanger vers la surface du thème (jamais de noir « en dur »).
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.lerp(base, Theme.of(context).colorScheme.surface, 0.65)!;
    }
    return base;
  }
}

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final String? category;
  _ServiceItem(this.icon, this.label, this.color, this.bgColor, this.category);
}
