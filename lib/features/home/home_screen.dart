import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/service_icon_card.dart';
import 'package:fixnow/core/widgets/pro_card.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/features/notifications/notifications_controller.dart';
import 'package:shimmer/shimmer.dart';

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
      backgroundColor: AppColors.background,
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
                _buildPopularSection(context, homeState),
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
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage:
                user?.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user?.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello 👋',
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

          // Notification bell with badge
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                // Badge — real unread notifications count
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
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
            color: AppColors.white,
            borderRadius: AppRadius.xlAll,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.textHint,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Rechercher un service...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
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
                      color: AppColors.accent,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: const Text(
                      'OFFRE LIMITÉE',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Économisez 25%',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    'aujourd\'hui !',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sur votre premier service réservé',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 13,
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
                      foregroundColor: AppColors.white,
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: AppRadius.lgAll,
              ),
              child: const Center(
                child: Icon(
                  Icons.engineering_rounded,
                  color: Colors.white,
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
      _ServiceItem(Icons.plumbing_rounded, 'Plombier', AppColors.plomberie, AppColors.plomberieLight),
      _ServiceItem(Icons.electrical_services_rounded, 'Électricien', AppColors.electricite, AppColors.electriciteLight),
      _ServiceItem(Icons.carpenter_rounded, 'Menuisier', AppColors.menuiserie, AppColors.menuiserieLight),
      _ServiceItem(Icons.format_paint_rounded, 'Peintre', AppColors.peinture, AppColors.peintureLight),
      _ServiceItem(Icons.construction_rounded, 'Maçon', AppColors.maconnerie, AppColors.maconnerieLight),
      _ServiceItem(Icons.build_circle_rounded, 'Soudeur', AppColors.soudure, AppColors.soudureLight),
      _ServiceItem(Icons.home_repair_service_rounded, 'Couvreur', AppColors.couverture, AppColors.couvertureLight),
      _ServiceItem(Icons.more_horiz_rounded, 'Voir plus', AppColors.textSecondary, AppColors.soudureLight),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
              childAspectRatio: 0.85,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              return ServiceIconCard(
                icon: s.icon,
                label: s.label,
                iconColor: s.color,
                backgroundColor: s.bgColor,
                onTap: () => context.push('/search?category=${s.label}'),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Popular Section ────────────────────────────────────────────────

  Widget _buildPopularSection(BuildContext context, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Populaire près de vous', style: AppTextStyles.h3),
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
          _buildShimmerList()
        else if (state.error != null)
          Center(child: Text('Erreur: ${state.error}'))
        else if (state.popularPros.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('Aucun professionnel trouvé'),
            ),
          )
        else
          SizedBox(
            height: 160,
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
                    categoryColor: _categoryColor(pro.categories.firstOrNull),
                    categoryBgColor: _categoryBgColor(pro.categories.firstOrNull),
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

  Widget _buildShimmerList() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgAll,
            ),
          ),
        ),
      ),
    );
  }

  // ── Local helpers ──────────────────────────────────────────────────────

  Color _categoryColor(String? category) {
    final map = <String, Color>{
      'Plombier': AppColors.plomberie,
      'Électricien': AppColors.electricite,
      'Menuisier': AppColors.menuiserie,
      'Peintre': AppColors.peinture,
      'Maçon': AppColors.maconnerie,
      'Soudeur': AppColors.soudure,
      'Couvreur': AppColors.couverture,
      'Ménage': AppColors.menage,
      'Artisan': AppColors.textSecondary,
    };
    return map[category] ?? AppColors.textSecondary;
  }

  Color _categoryBgColor(String? category) {
    final map = <String, Color>{
      'Plombier': AppColors.plomberieLight,
      'Électricien': AppColors.electriciteLight,
      'Menuisier': AppColors.menuiserieLight,
      'Peintre': AppColors.peintureLight,
      'Maçon': AppColors.maconnerieLight,
      'Soudeur': AppColors.soudureLight,
      'Couvreur': AppColors.couvertureLight,
      'Ménage': AppColors.menageLight,
      'Artisan': AppColors.soudureLight,
    };
    return map[category] ?? AppColors.soudureLight;
  }
}

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  _ServiceItem(this.icon, this.label, this.color, this.bgColor);
}
