import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const Spacer(),
                    // Rating
                    const Icon(Icons.star, color: AppColors.warning, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ' ($reviewCount)',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                Text(
                  name,
                  style: AppTextStyles.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),

                Text(
                  price == 0
                      ? 'Sur devis'
                      : '${price.toStringAsFixed(0)} € / heure',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Buttons
          Column(
            children: [
              OutlinedButton(
                onPressed: onViewProfile,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    vertical: AppSpacing.xs + 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.primaryContainer,
      backgroundImage:
          imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? const Icon(Icons.person, color: AppColors.primary, size: 30)
          : null,
    );
  }
}
