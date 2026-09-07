import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Outline button — secondary action style.
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;
  final double? height;
  final Color? borderColor;
  final Color? foregroundColor;

  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isExpanded = false,
    this.height,
    this.borderColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? AppColors.primary,
        minimumSize: Size(0, height ?? 44),
        textStyle: AppTextStyles.buttonMedium,
        side: BorderSide(
          color: borderColor ?? AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
        ),
      ),
      child: Text(label),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}
