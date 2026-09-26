import 'package:flutter/material.dart';

import 'package:fixnow/core/theme/app_theme.dart';

/// Affichage du rating par étoiles (1 à 5), réutilisable partout.
///
/// Deux usages :
/// - lecture seule : `StarRating(rating: 4.3)` — demi-étoiles précises ;
/// - interactif : `StarRating(rating: x, onRatingChanged: ...)` pour
///   la saisie d'un avis.
class StarRating extends StatelessWidget {
  /// Note affichée (0 à 5, fractions supportées : 4.3 → 4 étoiles pleines
  /// + une demi-étoile).
  final double rating;

  /// Taille d'une étoile (défaut 16).
  final double size;

  /// Callback de saisie (null = lecture seule, défaut).
  final ValueChanged<double>? onRatingChanged;

  /// Affiche la note chiffrée à côté des étoiles (ex. « 4.3 (12 avis) »).
  final bool showLabel;

  /// Nombre d'avis pour le label (affiche « avis » au singulier si 1).
  final int? reviewCount;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.onRatingChanged,
    this.showLabel = false,
    this.reviewCount,
  }) : assert(rating >= 0 && rating <= 5);

  @override
  Widget build(BuildContext context) {
    final color = context.semanticColors.warning;
    final clamped = rating.clamp(0.0, 5.0);

    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = clamped - i;
        final icon = value >= 0.75
            ? Icons.star_rounded
            : value >= 0.25
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? 1 : 0),
          child: Icon(icon, color: color, size: size),
        );
      }),
    );

    if (onRatingChanged == null) {
      return MergeSemantics(
        child: Semantics(
          label: 'Note : ${clamped.toStringAsFixed(1)} sur 5',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              stars,
              if (showLabel) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _label(clamped),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Mode interactif : chaque étoile est un bouton (zone ≥ 48 dp via
    // le padding, conforme accessibilité).
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = (i + 1).toDouble();
        final filled = clamped >= starValue - 0.25;
        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Attribuer $starValue étoile${starValue > 1 ? 's' : ''}',
          onPressed: () => onRatingChanged!(starValue),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: color,
            size: size + 8,
          ),
        );
      }),
    );
  }

  String _label(double value) {
    if (reviewCount == null) return value.toStringAsFixed(1);
    return '${value.toStringAsFixed(1)} ($reviewCount avis)';
  }
}
