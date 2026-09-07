import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Custom bottom navigation bar matching the FixNow design.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Commandes',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                badge: 3,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: AppRadius.fullAll,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.white : AppColors.textHint,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textHint,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
