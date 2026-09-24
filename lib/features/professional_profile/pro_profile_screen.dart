import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/widgets/outline_button.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/professional_profile/pro_profile_controller.dart';
import 'package:fixnow/models/review_model.dart';
import 'package:intl/intl.dart';

/// Professional profile detail screen — data-driven from Firestore.
class ProProfileScreen extends ConsumerWidget {
  final String proId;
  const ProProfileScreen({super.key, required this.proId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proProfileControllerProvider(proId));

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const ProProfileSkeleton(),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              const Text('Erreur de chargement', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.error!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final pro = state.pro;
    if (pro == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              const Text('Professionnel introuvable', style: AppTextStyles.h4),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Hero banner
              SliverToBoxAdapter(
                child: Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded,
                              color: Theme.of(context).colorScheme.onPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      // Avatar
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          backgroundImage: pro.avatarUrl != null
                              ? NetworkImage(pro.avatarUrl!)
                              : null,
                          child: pro.avatarUrl == null
                              ? Icon(Icons.person,
                                  color: Theme.of(context).colorScheme.onPrimary, size: 50)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pro.name.isNotEmpty ? pro.name : 'Professionnel',
                                  style: AppTextStyles.h2,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    if (pro.categories.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: Text(
                                          pro.categories.first,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                    ],
                                    const Icon(Icons.star,
                                        color: AppColors.warning, size: 16),
                                    Text(
                                      ' ${pro.ratingAvg.toStringAsFixed(1)} (${pro.ratingCount} avis)',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pro.city.isNotEmpty ? pro.city : 'Zone non renseignée',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                          Text('${pro.hourlyRate.toStringAsFixed(0)} €/heure',
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.primary,
                              )),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text('À propos de moi', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        pro.bio.isNotEmpty
                            ? pro.bio
                            : 'Aucune description pour le moment.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // Titre masqué quand il n'y a pas de photos :
                      // évite un grand vide entre « À propos » et « Avis ».
                      if (pro.gallery.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const Text('Réalisations', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ),

              // Photo gallery grid
              if (pro.gallery.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.network(
                          pro.gallery[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      childCount: pro.gallery.length,
                    ),
                  ),
                ),

              // Reviews section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Avis', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.md),
                      if (state.reviews.isEmpty)
                        const Text(
                          'Aucun avis pour le moment',
                          style: AppTextStyles.bodySmall,
                        )
                      else
                        ...state.reviews.map((review) => _ReviewTile(review: review)),
                    ],
                  ),
                ),
              ),

              // Bottom spacing for fixed buttons
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),

          // Fixed bottom buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlineButton(
                      label: 'Message',
                      isExpanded: true,
                      // Même hauteur que le bouton principal (52) pour
                      // que la barre soit alignée.
                      height: 52,
                      onPressed: () => context.push('/chat/new?proId=$proId'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Réserver maintenant',
                      isExpanded: true,
                      onPressed: () =>
                          context.push('/booking/new?proId=$proId'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single review row displayed in the profile.
class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.warning,
                );
              }),
              const Spacer(),
              Text(
                DateFormat('dd/MM/yyyy').format(review.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.comment, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
