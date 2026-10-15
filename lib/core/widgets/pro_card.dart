import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/star_rating.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';

/// Couleurs de la certification « vérifiée » (vert AA sur pastel clair),
/// identiques en clair et en sombre (le fond pastel reste clair).
const Color _verifiedFg = Color(0xFF15803D);
const Color _verifiedBg = Color(0xFFDCFCE7);

/// Orange de l'indicateur de délai d'arrivée (accent vif de la bannière
/// Urgence) — lisible sur les deux fonds de carte.
const Color _etaColor = Color(0xFFFF6B3D);

/// Horizontal card showing a professional in the "Popular near you" list.
///
/// Nouveautés spec UI :
/// - badge de certification « Vérifié & Assuré AXA » / « Garantie
///   Décennale » (bouclier vert) sous la note ;
/// - délai d'arrivée estimé (« Arrive en ~15 min ») avec icône éclair
///   orange ;
/// - robustesse conservée : FittedBox sur les rangées de badges et
///   ConstrainedBox sur les boutons (aucun overflow à 320 dp × 1.5×).
class ProCard extends StatelessWidget {
  final String name;
  final String category;
  final Color categoryColor;
  final Color categoryBgColor;
  final double rating;
  final int reviewCount;
  final double price;
  final String? imageUrl;
  final VoidCallback? onViewProfile;
  final VoidCallback? onBook;

  /// Délai d'arrivée estimé en minutes (null = indicateur masqué).
  final int? etaMinutes;

  /// Badge de certification affiché (null = masqué). Valeurs attendues :
  /// « Vérifié & Assuré AXA » ou « Garantie Décennale ».
  final String? certification;

  const ProCard({
    super.key,
    required this.name,
    required this.category,
    required this.categoryColor,
    required this.categoryBgColor,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.imageUrl,
    this.onViewProfile,
    this.onBook,
    this.etaMinutes,
    this.certification,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: colors.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(context),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge catégorie + note : FittedBox garantit l'absence
                // d'overflow quelles que soient la largeur (320 dp) et
                // l'échelle de texte (1.5×).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: categoryBgColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          category,
                          style: AppTextStyles.caption.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Rating par étoiles (couleur « texte » du thème :
                      // contraste AA, demi-étoiles précises).
                      StarRating(
                        rating: rating,
                        size: 14,
                        showLabel: true,
                        reviewCount: reviewCount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                Text(
                  name,
                  style: AppTextStyles.h4.copyWith(color: colors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Prix + délai d'arrivée estimé (éclair orange) :
                // FittedBox — jamais de débordement avec un long prix.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        price == 0
                            ? 'Sur devis'
                            : '${price.toStringAsFixed(0)} € / heure',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (etaMinutes != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.bolt_rounded,
                            size: 14, color: _etaColor),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Arrive en ~$etaMinutes min',
                          maxLines: 1,
                          style: AppTextStyles.caption.copyWith(
                            color: _etaColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge de certification vérifiée (bouclier vert).
                if (certification != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _verifiedBg,
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              size: 12, color: _verifiedFg),
                          const SizedBox(width: 3),
                          Text(
                            certification!,
                            style: AppTextStyles.caption.copyWith(
                              color: _verifiedFg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Buttons (largeur bridée : la carte reste stable de 320 dp
          // à 1.5× de facteur de texte — aucun overflow horizontal).
          // « Voir profil » = outlined, « Réserver » = plein bleu.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 116),
            child: Column(
              children: [
                OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    minimumSize: const Size(64, 48),
                    textStyle: AppTextStyles.buttonSmall,
                    side: const BorderSide(color: AppColors.primary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text('Voir profil'),
                ),
                const SizedBox(height: AppSpacing.xs),
                ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    minimumSize: const Size(64, 48),
                    // Bleu plein demandé par la spec (le thème sombre
                    // éclaircit : on garde le #2F6BFF dans les deux modes).
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    textStyle: AppTextStyles.buttonSmall,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text('Réserver'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppAvatar(
      url: imageUrl,
      radius: 30,
      foregroundColor: cs.onPrimaryContainer,
    );
  }
}
