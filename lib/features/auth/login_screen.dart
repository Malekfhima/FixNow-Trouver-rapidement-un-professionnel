import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/widgets/outline_button.dart';

/// Login screen with email/password, Google, and phone options.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              Text('Bienvenue\nsur FixNow', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connectez-vous pour trouver le bon professionnel',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),
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
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Mot de passe oublié ?',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Se connecter',
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text('ou', style: AppTextStyles.bodySmall),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Continuer avec Google',
                onPressed: () {},
                isExpanded: true,
                icon: const Icon(Icons.g_mobiledata, size: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlineButton(
                label: 'Continuer avec téléphone',
                onPressed: () => context.push('/phone-auth'),
                isExpanded: true,
                borderColor: AppColors.border,
                foregroundColor: AppColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.xxxxxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text(
                      'S\'inscrire',
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
