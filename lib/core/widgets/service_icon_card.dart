import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// A pastel card with an icon and label used in the services grid on Home.
///
/// [badge] : micro-badge indicatif au-dessus de l'icône pastel
/// (ex. « dès 45€/h », « 24/7 ») — masqué si null.
class ServiceIconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final String? badge;

  const ServiceIconCard({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            // Micro-badge de tarif indicatif (pastille blanche compacte
            // contrainte à la largeur de la tuile : jamais de débordement).
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 68),
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.fullAll,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  badge!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.lgAll,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
