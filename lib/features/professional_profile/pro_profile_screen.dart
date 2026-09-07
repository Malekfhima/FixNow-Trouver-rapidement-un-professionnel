import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/widgets/outline_button.dart';

/// Professional profile detail screen.
class ProProfileScreen extends StatelessWidget {
  final String proId;
  const ProProfileScreen({super.key, required this.proId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Hero banner
              SliverToBoxAdapter(
                child: Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: AppColors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Placeholder avatar
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.person,
                              color: AppColors.white, size: 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Marc Lefebvre', style: AppTextStyles.h2),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.plomberieLight,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Text(
                                        'Plombier',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.plomberie,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Icons.star,
                                        color: AppColors.warning, size: 16),
                                    Text(
                                      ' 4.8 (127 avis)',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 4),
                          Text('Paris 11ème, 2.3 km',
                              style: AppTextStyles.bodySmall),
                          const Spacer(),
                          Text('45 €/heure',
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.primary,
                              )),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('À propos de moi', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Plombier certifié avec 8 ans d\'expérience. '
                        'Spécialisé dans la rénovation de salles de bain '
                        'et le dépannage urgent. Intervention rapide '
                        'et travail soigné garanti.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Réalisations', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),

              // Photo gallery grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.photo,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    childCount: 9,
                  ),
                ),
              ),

              // Reviews section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avis', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Aucun avis pour le moment',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom spacing for fixed buttons
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),

          // Fixed bottom buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlineButton(
                      label: 'Message',
                      isExpanded: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Réserver maintenant',
                      isExpanded: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
