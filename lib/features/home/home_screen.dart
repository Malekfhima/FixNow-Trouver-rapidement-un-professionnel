import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/service_icon_card.dart';
import 'package:fixnow/core/widgets/pro_card.dart';

/// Client Home screen — reproduces the main layout from the mockups.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              _buildHeader(context),
              const SizedBox(height: AppSpacing.xl),
              _buildSearchBar(context),
              const SizedBox(height: AppSpacing.xl),
              _buildPromoBanner(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildServicesGrid(context),
              const SizedBox(height: AppSpacing.xxl),
              _buildPopularSection(context),
              const SizedBox(height: AppSpacing.xxxxxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryContainer,
            child: const Icon(Icons.person, color: AppColors.primary, size: 28),
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
                  'Jean Dupont',
                  style: AppTextStyles.h2,
                ),
              ],
            ),
          ),

          // Notification bell with badge
          GestureDetector(
            onTap: () {
              // TODO: Navigate to notifications
            },
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
                // Badge
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
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
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
                      // TODO: Navigate to booking
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

  Widget _buildPopularSection(BuildContext context) {
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
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: _mockPros.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, index) {
              final pro = _mockPros[index];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.82,
                child: ProCard(
                  name: pro.name,
                  category: pro.category,
                  categoryColor: pro.categoryColor,
                  categoryBgColor: pro.categoryBgColor,
                  rating: pro.rating,
                  reviewCount: pro.reviewCount,
                  price: pro.price,
                  onViewProfile: () =>
                      context.push('/pro/${pro.id}'),
                  onBook: () => context.push('/booking/new'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Local helpers ──────────────────────────────────────────────────────

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  _ServiceItem(this.icon, this.label, this.color, this.bgColor);
}

class _MockPro {
  final String id;
  final String name;
  final String category;
  final Color categoryColor;
  final Color categoryBgColor;
  final double rating;
  final int reviewCount;
  final double price;

  const _MockPro({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryColor,
    required this.categoryBgColor,
    required this.rating,
    required this.reviewCount,
    required this.price,
  });
}

const _mockPros = [
  _MockPro(
    id: '1',
    name: 'Marc Lefebvre',
    category: 'Plombier',
    categoryColor: AppColors.plomberie,
    categoryBgColor: AppColors.plomberieLight,
    rating: 4.8,
    reviewCount: 127,
    price: 45,
  ),
  _MockPro(
    id: '2',
    name: 'Sophie Martin',
    category: 'Électricien',
    categoryColor: AppColors.electricite,
    categoryBgColor: AppColors.electriciteLight,
    rating: 4.9,
    reviewCount: 89,
    price: 52,
  ),
  _MockPro(
    id: '3',
    name: 'Ahmed Benali',
    category: 'Menuisier',
    categoryColor: AppColors.menuiserie,
    categoryBgColor: AppColors.menuiserieLight,
    rating: 4.7,
    reviewCount: 64,
    price: 0,
  ),
];
