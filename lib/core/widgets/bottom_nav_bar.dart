import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/chat/chat_controller.dart';

/// Custom bottom navigation bar matching the FixNow design.
class BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Compteur réel : messages non lus (onglet Chat). Les notifications
    // non lues ont leur propre badge sur la cloche de l'accueil.
    final unreadMessages = ref.watch(unreadMessagesCountProvider);
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
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
                badge: _formatBadge(unreadMessages.valueOrNull),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Commandes',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
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

  /// "12" / « 99+ » — masqué à 0 (le badge disparaît).
  static String? _formatBadge(int? count) {
    if (count == null || count <= 0) return null;
    return count > 99 ? '99+' : '$count';
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                  ? colors.primary
                  : Colors.transparent,
              borderRadius: AppRadius.fullAll,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                  size: 24,
                ),                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: context.semanticColors.accent,
                        borderRadius: AppRadius.fullAll,
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
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
              color: isActive
                  ? colors.primary
                  : colors.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
