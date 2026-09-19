import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/auth/auth_controller.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/models/user_model.dart';

/// Client profile / settings screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);


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
              backgroundImage: user.valueOrNull?.avatarUrl != null
                  ? NetworkImage(user.valueOrNull!.avatarUrl!)
                  : null,
              child: user.valueOrNull?.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 40)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(user.valueOrNull?.name ?? 'Utilisateur', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.xs),
            Text(user.valueOrNull?.email ?? '', style: AppTextStyles.bodySmall),

            const SizedBox(height: AppSpacing.xxl),


            _MenuItem(
              icon: Icons.person_outline,
              label: 'Modifier le profil',
              onTap: () {
                final role = user.valueOrNull?.role;
                if (role == UserRole.pro) {
                  context.push('/pro-profile-edit');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('L\'édition du profil client arrive bientôt'),
                    ),
                  );
                }
              },
            ),
            if (user.valueOrNull?.role == UserRole.pro)
              _MenuItem(
                icon: Icons.work_outline,
                label: 'Mes demandes (pro)',
                onTap: () => context.push('/pro-dashboard'),
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
            if (kDebugMode)
              _MenuItem(
                icon: Icons.science_outlined,
                label: 'Seed démo (debug)',
                onTap: () => context.push('/debug-seed'),
              ),

            const SizedBox(height: AppSpacing.xxl),            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
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
            ),          ],
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
