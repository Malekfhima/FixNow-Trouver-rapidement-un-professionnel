import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';

/// Registration screen.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxxxxl),
              Text('Créer un\ncompte', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Rejoignez la communauté FixNow',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'S\'inscrire',
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Déjà un compte ? ', style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'Se connecter',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
