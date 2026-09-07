import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// A pastel card with an icon and label used in the services grid on Home.
class ServiceIconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const ServiceIconCard({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              color: AppColors.textPrimary,
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
