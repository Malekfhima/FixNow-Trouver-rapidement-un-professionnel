import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Client profile / settings screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            // Avatar & name
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryContainer,
              child:
                  const Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Jean Dupont', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.xs),
            Text('jean.dupont@email.com', style: AppTextStyles.bodySmall),

            const SizedBox(height: AppSpacing.xxl),

            _MenuItem(
              icon: Icons.person_outline,
              label: 'Modifier le profil',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              label: 'Mes adresses',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.help_outline,
              label: 'Aide & support',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.info_outline,
              label: 'À propos',
              onTap: () {},
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.lgAll,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label, style: AppTextStyles.bodyMedium),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
    );
  }
}
