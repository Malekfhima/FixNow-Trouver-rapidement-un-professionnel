import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';

/// Grande carte artisan de l'écran Recherche (interface hybride
/// Carte + Liste). Différente de la [ProCard] compacte de l'accueil :
/// photo avec pastille de statut, note précise + avis, distance,
/// arrivée estimée, badges de garanties et actions directes
/// (Message / Réserver, Profil optionnel).
class SearchProCard extends StatelessWidget {
  final String name;
  final String category;
  final Color categoryColor;
  final Color categoryBgColor;

  /// Note exacte affichée (ex. 4.9) et nombre d'avis.
  final double rating;
  final int reviewCount;
  final double price;
  final String? imageUrl;

  /// Statut « en direct » : vert = disponible (jours déclarés),
  /// orange = indisponible. Aucune donnée temps réel derrière :
  /// dérivé de `availability` (voir SearchController._hasAvailability).
  final bool available;

  /// Distance en km jusqu'au pro (null = pas de position utilisateur).
  final double? distanceKm;

  /// Temps d'arrivée estimé en minutes (null = indicateur masqué).
  final int? etaMinutes;

  /// Badges de garanties (« SIRET vérifié », « Garantie Décennale »,
  /// « Agréé assurances »…).
  final List<String> badges;

  final VoidCallback? onViewProfile;
  final VoidCallback? onMessage;
  final VoidCallback? onBook;

  const SearchProCard({
    super.key,
    required this.name,
    required this.category,
    required this.categoryColor,
    required this.categoryBgColor,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.available,
    required this.badges,
    this.imageUrl,
    this.distanceKm,
    this.etaMinutes,
    this.onViewProfile,
    this.onMessage,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onDark = Theme.of(context).brightness == Brightness.dark;
    // Pastille de statut : vert (disponible) / orange (indisponible),
    // lisible sur les deux modes.
    final statusColor = available
        ? (onDark ? const Color(0xFF4ADE80) : AppColors.success)
        : (onDark ? const Color(0xFFFBBF24) : AppColors.warning);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── En-tête : avatar + statut, nom + note, badge ETA.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppAvatar(
                    url: imageUrl,
                    radius: 26,
                    foregroundColor: cs.onPrimaryContainer,
                  ),
                  // Pastille de statut vert/orange (bord de l'avatar).
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    // Note précise + distance (FittedBox : jamais
                    // d'overflow à 320 dp × 1.5×).
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.tertiaryLight),
                          const SizedBox(width: 2),
                          Text(
                            '${rating.toStringAsFixed(1)} '
                            '($reviewCount avis)',
                            style: AppTextStyles.caption.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (distanceKm != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(Icons.location_on_rounded,
                                size: 13,
                                color: cs.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              '${distanceKm!.toStringAsFixed(1)} km de vous',
                              style: AppTextStyles.caption.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Badge « Arrivée estimée 12 min » (compact, à droite).
              if (etaMinutes != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 13, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            'Arrivée estimée $etaMinutes min',
                            style: AppTextStyles.caption.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Rangée : chip catégorie + badges de garanties.
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
                    color: categoryBgColor,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    category,
                    style: AppTextStyles.caption.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final badge in badges) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _GuaranteeBadge(label: badge),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Pied : prix (grand) + actions directes.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: price == 0
                            ? 'Sur devis'
                            : '${price.toStringAsFixed(0)} €',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                        children: price == 0
                            ? null
                            : [
                                TextSpan(
                                  text: ' /heure',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Engagement transparent',
                      style: AppTextStyles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Actions : Message (outlined) + Réserver (plein) — et
              // Profil optionnel ; Flexible + FittedBox : les libellés
              // réduisent leur échelle plutôt que de déborder à 1.5×.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onViewProfile != null) ...[
                      OutlinedButton(
                        onPressed: onViewProfile,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          textStyle: AppTextStyles.buttonSmall,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smAll,
                          ),
                        ),
                        child: const Text('Profil'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    OutlinedButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        textStyle: AppTextStyles.buttonSmall,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smAll,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(72, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        // Bleu plein #2F6BFF identique dans les deux modes.
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        textStyle: AppTextStyles.buttonSmall,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smAll,
                        ),
                      ),
                      child: const Text('Réserver'),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge de garantie compact (pastille neutre avec icône bouclier).
class _GuaranteeBadge extends StatelessWidget {
  final String label;

  const _GuaranteeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    // Vert « vérifié » identique au badge du ProCard (clair/sombre).
    final fg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.10),
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
