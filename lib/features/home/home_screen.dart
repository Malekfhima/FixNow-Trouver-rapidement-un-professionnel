import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/service_icon_card.dart';
import 'package:fixnow/core/widgets/pro_card.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/features/notifications/notifications_controller.dart';

/// Orange vif de la bannière Urgence et des indicateurs « éclair »
/// (spécifié dans la maquette : CTA « Demande Express »).
const Color _urgencyCta = Color(0xFFFF6B3D);

/// Bandeau sombre haut de gamme : dégradé #0F172A → #1E293B.
const List<Color> _urgencyGradient = [
  Color(0xFF0F172A),
  Color(0xFF1E293B),
];

/// Client Home screen — reproduces the main layout from the mockups.
///
/// Spec UI v2 :
/// - bandeau d'adresse sélectionnée (chevron → Mes adresses) +
///   compteur de pros en direct + cloche de notifications avec badge réel ;
/// - barre de recherche avec bouton filtres (indicateur actif) et
///   texte indicatif enrichi ;
/// - bannière « Urgence Dépannage 24/7 » (conteneur sombre, liseré
///   orange, badge ⚡ Dépannage Immédiat, CTA « Demande Express »,
///   arrivée moyenne 14 min) ;
/// - grille des services avec micro-badges de tarif indicatif ;
/// - section de réassurance `FixNowGuaranteeCard` (3 piliers).
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
                _buildGreeting(context, userProfile.valueOrNull),
                const SizedBox(height: AppSpacing.xl),
                _buildSearchBar(context),
                const SizedBox(height: AppSpacing.xl),
                _buildUrgencyBanner(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildServicesGrid(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildPopularSection(context, ref, homeState),
                const SizedBox(height: AppSpacing.xxl),
                const FixNowGuaranteeCard(),
                const SizedBox(height: AppSpacing.xxxxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header : adresse + pros actifs + cloche ────────────────────────

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    // Adresse sélectionnée : la 1ʳᵉ adresse enregistrée du profil,
    // sinon un libellé d'accroche qui ouvre aussi le sélecteur.
    final addresses = user?.addresses as List<dynamic>? ?? const [];
    final addressLabel = addresses.isNotEmpty
        ? (addresses.first.label as String)
        : 'Définir mon adresse';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          // ── Bandeau d'adresse sélectionnée (zone tactile 48 dp) :
          // ouvre l'écran Mes adresses (sélecteur d'adresses).
          Expanded(
            child: Tooltip(
              message: 'Changer d\'adresse',
              child: InkWell(
                onTap: () => context.push('/profile/addresses'),
                borderRadius: AppRadius.fullAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: AppRadius.fullAll,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Localisation',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              addressLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chevron déroulant → sélecteur d'adresses.
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Compteur de pros en direct (pastille compacte, FittedBox).
          const Flexible(child: _LiveProsChip()),

          const SizedBox(width: AppSpacing.md),

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
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
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

  // ── Salutation (dissociée du bandeau d'adresse) ─────────────────────

  Widget _buildGreeting(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Trouvez un artisan certifié en moins de 15 minutes',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Search Bar : placeholder enrichi + bouton filtres ──────────────

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
              // Texte indicatif enrichi : exemple concret de recherche.
              Expanded(
                child: Text(
                  'Ex : fuite d\'eau, serrure bloquée, tableau…',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── Bouton filtres avec indicateur actif (pastille orange :
              // des filtres sont appliqués). Ouvre l'écran Recherche.
              Tooltip(
                message: 'Filtres de recherche',
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        // Indicateur actif des filtres (badge orange).
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _urgencyCta,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bannière Urgence Dépannage 24/7 ────────────────────────────────

  Widget _buildUrgencyBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _urgencyGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.xlAll,
          border: const Border(
            // Liseré orange (spec « haut de gamme »).
            left: BorderSide(color: _urgencyCta, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: _urgencyCta.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rangée : badge ⚡ Dépannage Immédiat (< 20 min)
            //    + mention 24h/24 & 7j/7 (FittedBox : jamais d'overflow).
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _urgencyCta,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          'Dépannage Immédiat (< 20 min)',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '24h/24 & 7j/7',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Titre + accroche.
            Text(
              'Un problème urgent ?',
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                height: 1.25,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Des artisans certifiés prêts à intervenir chez vous, '
              'de jour comme de nuit.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),            const SizedBox(height: AppSpacing.lg),

            // ── CTA orange vif « Demande Express »
            //    + indicateur d'arrivée moyenne (14 min).
            // LayoutBuilder : côte à côte sur écran large, empilés sur
            // écran étroit (320 dp) — le bouton garde sa pleine largeur
            // et son libellé à 1.5× ne déborde jamais.
            LayoutBuilder(
              builder: (context, constraints) {
                final cta = ElevatedButton.icon(
                  onPressed: () {
                    // Urgence → recherche filtrée sur les catégories
                    // d'intervention express (sans route nouvelle).
                    context.push('/search');
                  },
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text('Demande Express'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _urgencyCta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    textStyle: AppTextStyles.buttonMedium,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                  ),
                );
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: double.infinity, child: cta),
                      const SizedBox(height: AppSpacing.md),
                      _buildEtaIndicator(context),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cta),
                    const SizedBox(width: AppSpacing.md),
                    _buildEtaIndicator(context),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Indicateur d'arrivée moyenne (mini-carte translucide).
  Widget _buildEtaIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arrivée moy.',
            style: AppTextStyles.caption.copyWith(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 14, color: _urgencyCta),
              const SizedBox(width: 2),
              Text(
                '14 min',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Services Grid ──────────────────────────────────────────────────

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      // `category` = nom exact utilisé dans Firestore (pro.categories) pour
      // que le filtre de l'écran Recherche fonctionne directement.
      // `badge` = micro-badge de tarif indicatif affiché au-dessus de
      // l'icône pastel (spécification « dès 45€/h », « 24/7 »…).
      _ServiceItem(Icons.plumbing_rounded, 'Plombier', AppColors.plomberie, AppColors.plomberieLight, 'Plomberie', 'dès 45€/h'),
      _ServiceItem(Icons.electrical_services_rounded, 'Électricien', AppColors.electricite, AppColors.electriciteLight, 'Électricité', 'dès 50€/h'),
      _ServiceItem(Icons.carpenter_rounded, 'Menuisier', AppColors.menuiserie, AppColors.menuiserieLight, 'Menuiserie', 'sur mesure'),
      _ServiceItem(Icons.format_paint_rounded, 'Peintre', AppColors.peinture, AppColors.peintureLight, 'Peinture', 'dès 35€/h'),
      _ServiceItem(Icons.construction_rounded, 'Maçon', AppColors.maconnerie, AppColors.maconnerieLight, 'Maçonnerie', 'dès 40€/h'),
      _ServiceItem(Icons.build_circle_rounded, 'Soudeur', AppColors.soudure, AppColors.soudureLight, 'Soudure', 'sur devis'),
      _ServiceItem(Icons.home_repair_service_rounded, 'Couvreur', AppColors.couverture, AppColors.couvertureLight, 'Couverture', '24/7'),
      _ServiceItem(Icons.more_horiz_rounded, 'Voir plus', Theme.of(context).colorScheme.onSurfaceVariant, AppColors.soudureLight, null, '+14 métiers'),
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
              // Cellules assez hautes pour micro-badge + icône + libellé
              // même à 1.5× de facteur de texte (aucun overflow sur 320 dp).
              childAspectRatio: 0.55,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              return ServiceIconCard(
                icon: s.icon,
                label: s.label,
                iconColor: s.color,
                backgroundColor: s.bgColor,
                badge: s.badge,
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
            // Assez haut pour la carte enrichie (badge certification)
            // à 1.5× de facteur de texte (icône + nom + prix + 2 boutons).
            height: 224,
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
                    // Spec : badge de certification vérifiée + délai
                    // d'arrivée estimé (base métier FixNow : vérification
                    // SIRET à l'inscription → « Garantie Décennale »
                    // pour les métiers du gros œuvre, sinon AXA).
                    certification: _certificationFor(pro.categories),
                    etaMinutes: 15,
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

  /// Badge de certification selon la catégorie du pro : « Garantie
  /// Décennale » pour le gros œuvre (obligation légale), « Vérifié &
  /// Assuré AXA » pour les autres interventions.
  static String _certificationFor(List<String> categories) {
    const structural = {'Maçonnerie', 'Couverture'};
    if (categories.any(structural.contains)) {
      return 'Garantie Décennale';
    }
    return 'Vérifié & Assuré AXA';
  }

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

/// Compteur de pros en direct — pastille compacte avec point vert
/// « en direct » et libellé « 18 pros actifs » (FittedBox : jamais
/// d'overflow à 320 dp × 1.5×).
class _LiveProsChip extends StatelessWidget {
  const _LiveProsChip();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.fullAll,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Point vert « en direct » (halo translucide).
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.semanticColors.success,
                boxShadow: [
                  BoxShadow(
                    color: context.semanticColors.success
                        .withValues(alpha: 0.35),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '18 pros actifs',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de réassurance FixNow — 3 piliers affichés en bas de l'accueil :
/// 1. Artisans vérifiés (SIRET contrôlé) ;
/// 2. Devis transparent (sans frais cachés) ;
/// 3. Assurance AXA jusqu'à 5 000 €.
///
/// Le fond suit la surface du thème ; le mode sombre reste lisible
/// (icônes sur `primaryContainer`, textes adaptés à la luminosité).
class FixNowGuaranteeCard extends StatelessWidget {
  const FixNowGuaranteeCard({super.key});

  static const _pillars = <({IconData icon, String title, String detail})>[
    (
      icon: Icons.badge_rounded,
      title: 'Artisans vérifiés',
      detail: 'SIRET contrôlé avant chaque inscription',
    ),
    (
      icon: Icons.receipt_long_rounded,
      title: 'Devis transparent',
      detail: 'Sans frais cachés, prix convenus à l\'avance',
    ),
    (
      icon: Icons.verified_user_rounded,
      title: 'Assurance AXA',
      detail: 'Jusqu\'à 5 000 € couverts par intervention',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'La garantie FixNow',
              style: AppTextStyles.h4.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            // Row + Expanded : 3 colonnes égales ; sur 320 dp × 1.5× les
            // textes passent sur plusieurs lignes sans jamais déborder.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _pillars.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GuaranteePillar(pillar: _pillars[i]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuaranteePillar extends StatelessWidget {
  final ({IconData icon, String title, String detail}) pillar;

  const _GuaranteePillar({required this.pillar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(
            pillar.icon,
            size: 20,
            color: cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          pillar.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          pillar.detail,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final String? category;

  /// Micro-badge de tarif indicatif (ex. « dès 45€/h », « 24/7 »).
  final String? badge;
  _ServiceItem(this.icon, this.label, this.color, this.bgColor, this.category,
      this.badge);
}
