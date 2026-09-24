import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Outline button — secondary action style.
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final double? height;
  final Color? borderColor;
  final Color? foregroundColor;

  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.height,
    this.borderColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.primary,
        // 48 dp minimum : cible tactile accessible (WCAG 2.5.5).
        minimumSize: Size(0, height ?? 48),
        textStyle: AppTextStyles.buttonMedium,
        side: BorderSide(
          color: borderColor ?? AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
        ),
      ),
      // Le libellé se rétrécit au lieu de déborder/wrap sur 2 lignes,
      // et l'indicateur de chargement remplace le libellé pendant l'envoi
      // (anti double-clic : le bouton est aussi désactivé).
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
              ),
            ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}
