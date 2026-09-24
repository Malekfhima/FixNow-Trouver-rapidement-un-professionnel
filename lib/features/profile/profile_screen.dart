import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';
import 'package:fixnow/features/auth/auth_controller.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/core/theme/theme_mode_controller.dart';
import 'package:fixnow/models/user_model.dart';

/// Client profile / settings screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);


    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            // Avatar & name
            AppAvatar(
              url: user.valueOrNull?.avatarUrl,
              radius: 40,
              foregroundColor: AppColors.primary,
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
                if (user.valueOrNull?.isPro ?? false) {
                  context.push('/pro-profile-edit');
                } else {
                  context.push('/profile/edit');
                }
              },
            ),
            if (user.valueOrNull?.isPro ?? false)
              _MenuItem(
                icon: Icons.work_outline,
                label: 'Mes demandes (pro)',
                onTap: () => context.push('/pro-dashboard'),
              )
            else
              _MenuItem(
                icon: Icons.add_business_outlined,
                label: 'Devenir professionnel',
                onTap: () async {
                  final ok = await ref
                      .read(authControllerProvider.notifier)
                      .becomePro();
                  if (!context.mounted) return;
                  if (ok) {
                    context.push('/pro-profile-edit');
                  } else {
                    final error = ref.read(authControllerProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error ?? 'Impossible de passer en compte professionnel',
                        ),
                      ),
                    );
                  }
                },
              ),
            if (user.valueOrNull?.role == UserRole.admin)
              _MenuItem(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Administration',
                onTap: () => context.push('/admin'),
              ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              label: 'Mes adresses',
              onTap: () => AppAlerts.info(
                context,
                'La gestion des adresses enregistrées arrive bientôt.',
              ),
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => context.push('/notifications'),
            ),

            // ── Theme selector (system / light / dark) ──────────────
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.lg),
                    const Expanded(
                      child: Text('Thème', style: AppTextStyles.bodyMedium),
                    ),
                    SegmentedButton<AppThemeMode>(
                      selected: {
                        ref.watch(themeModeControllerProvider).mode,
                      },
                      segments: const [
                        ButtonSegment(
                            value: AppThemeMode.system,
                            icon: Icon(Icons.settings_suggest_outlined,
                                size: 18),
                            tooltip: 'Système'),
                        ButtonSegment(
                            value: AppThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined, size: 18),
                            tooltip: 'Clair'),
                        ButtonSegment(
                            value: AppThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined, size: 18),
                            tooltip: 'Sombre'),
                      ],
                      onSelectionChanged: (selection) {
                        ref
                            .read(themeModeControllerProvider.notifier)
                            .setMode(selection.first);
                      },
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _MenuItem(
              icon: Icons.help_outline,
              label: 'Aide & support',
              onTap: () => _showSupportDialog(context),
            ),
            _MenuItem(
              icon: Icons.info_outline,
              label: 'À propos',
              onTap: () => _showAboutDialog(context),
            ),
            if (kDebugMode)
              _MenuItem(
                icon: Icons.science_outlined,
                label: 'Seed démo (debug)',
                onTap: () => context.push('/debug-seed'),
              ),

            const SizedBox(height: AppSpacing.xxl),
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (!context.mounted) return;
                  // Le router redirige déjà vers /login quand la session
                  // tombe ; on force la navigation au cas où.
                  context.go('/login');
                  final error = ref.read(authControllerProvider).error;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Déconnexion : $error')),
                    );
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

  // ── Aide & support ──────────────────────────────────────────────────
  void _showSupportDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: const Text('Aide & support', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Une question, un problème ? Notre équipe vous répond '
              'du lundi au samedi, de 9h à 18h.',
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('support@fixnow.app', style: AppTextStyles.bodyMedium),
              onTap: () => launchUrl(
                Uri(scheme: 'mailto', path: 'support@fixnow.app'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
              title: const Text('+33 1 23 45 67 89', style: AppTextStyles.bodyMedium),
              onTap: () => launchUrl(Uri(scheme: 'tel', path: '+33123456789')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ── À propos ────────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: const Text('À propos de FixNow', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: const Icon(Icons.handyman_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text('FixNow', style: AppTextStyles.h3),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Version 1.0.0',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'La marketplace locale qui met en relation clients et '
              'professionnels du service à domicile : plomberie, '
              'électricité, menuiserie et plus encore.',
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
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
        leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(label, style: AppTextStyles.bodyMedium),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
    );
  }
}
