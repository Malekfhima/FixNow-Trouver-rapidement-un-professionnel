import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';

/// Horizontal card showing a professional in the "Popular near you" list.
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
          Expanded(              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        // Rating (couleur « texte » du thème : contraste AA)
                        Icon(Icons.star,
                            color: context.semanticColors.warning, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          ' ($reviewCount)',
                          style: AppTextStyles.caption,
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
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Buttons (largeur bridée : la carte reste stable de 320 dp
          // à 1.5× de facteur de texte — aucun overflow horizontal).
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
