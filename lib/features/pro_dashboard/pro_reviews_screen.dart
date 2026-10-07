import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/core/widgets/star_rating.dart';
import 'package:fixnow/models/review_model.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Écran « Mes avis » du professionnel : note moyenne + tous les avis reçus.
class ProReviewsScreen extends ConsumerWidget {
  const ProReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mes avis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: uid == null
          ? const Center(child: Text('Non connecté'))
          : ref.watch(proReviewsProvider(uid)).when(
              loading: () => const RequestCardSkeletonList(),
              error: (e, _) => ErrorState(
                error: ErrorMapper.message(e),
                onRetry: () => ref.invalidate(proReviewsProvider(uid)),
              ),
              data: (reviews) => _ReviewsBody(reviews: reviews),
            ),
    );
  }
}

/// Tous les avis du professionnel connecté (triés du plus récent au plus
/// ancien par la requête Firestore).
final proReviewsProvider =
    FutureProvider.family.autoDispose<List<Review>, String>((ref, proId) {
  return ref.watch(firestoreServiceProvider).getProReviews(proId);
});

/// Nom public de l'auteur d'un avis (publicProfiles — jamais users/{uid}).
final reviewerNameProvider =
    FutureProvider.family.autoDispose<String, String>((ref, uid) async {
  final profile = await ref.watch(firestoreServiceProvider).getPublicProfile(uid);
  return profile?.name ?? 'Client';
});

class _ReviewsBody extends StatelessWidget {
  final List<Review> reviews;

  const _ReviewsBody({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            const Text('Aucun avis pour le moment', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Terminez une prestation : vos clients pourront vous noter.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final count = reviews.length;
    final avg =
        reviews.fold<int>(0, (total, r) => total + r.rating) / count;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // ── Résumé : note moyenne ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.lgAll,
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: AppTextStyles.h2.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StarRating(rating: avg, size: 18),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$count avis de clients',
                      style: AppTextStyles.caption.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Liste des avis ────────────────────────────────────────────
        ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(reviewerNameProvider(review.clientId)).valueOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppAvatar(
                radius: 16,
                foregroundColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name ?? 'Client',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StarRating(rating: review.rating.toDouble(), size: 16),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(review.comment, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            DateFormat('dd/MM/yyyy').format(review.createdAt),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
