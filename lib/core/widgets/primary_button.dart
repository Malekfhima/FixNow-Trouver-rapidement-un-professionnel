import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Primary filled button — the main CTA style.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final double? height;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: Size(0, height ?? 52),
        textStyle: AppTextStyles.buttonLarge,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
        ),
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}
