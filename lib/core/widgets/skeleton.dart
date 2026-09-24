import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fixnow/core/theme/app_theme.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SKELETON LOADING — placeholders en forme du contenu réel (shimmer)
//
// Utilisé par tous les écrans le temps du chargement des données afin
// d'éviter les « sauts » de mise en page : la structure affichée pendant
// le chargement reproduit exactement celle du contenu final.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Shimmer wrapper — couleurs adaptées au thème clair/sombre.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }
}

/// Bloc de base : rectangle arrondi dont la couleur suit le thème.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Cercle de base (avatars).
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Cartes ───────────────────────────────────────────────────────────────

/// Placeholder de [ProCard] (recherche, accueil).
class ProCardSkeleton extends StatelessWidget {
  const ProCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Skeleton(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Row(
          children: [
            SkeletonCircle(size: 60),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonBox(
                            height: 20, radius: AppRadius.xs),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      SkeletonBox(width: 44, height: 14, radius: AppRadius.xs),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 100, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Column(
              children: [
                SkeletonBox(width: 76, height: 28),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 76, height: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder de carte de demande (« Mes commandes », dashboard pro, admin).
class RequestCardSkeleton extends StatelessWidget {
  const RequestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Skeleton(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 84, height: 20, radius: AppRadius.xs),
                Spacer(),
                SkeletonBox(width: 64, height: 12, radius: AppRadius.xs),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: AppSpacing.xs),
            SkeletonBox(width: 180, height: 14),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(width: 140, height: 12, radius: AppRadius.xs),
          ],
        ),
      ),
    );
  }
}

/// Placeholder d'une conversation (liste de messages).
class ChatTileSkeleton extends StatelessWidget {
  const ChatTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Skeleton(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Row(
          children: [
            SkeletonCircle(size: 44),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: double.infinity, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            SkeletonBox(width: 36, height: 12, radius: AppRadius.xs),
          ],
        ),
      ),
    );
  }
}

/// Placeholder d'une notification.
class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Skeleton(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonCircle(size: 40),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 72, height: 10, radius: AppRadius.xs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Écrans ───────────────────────────────────────────────────────────────

/// Placeholder des messages d'une conversation.
class MessageBubblesSkeleton extends StatelessWidget {
  const MessageBubblesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const heights = <double>[40, 32, 48, 36, 28, 44];
    const widths = [0.62, 0.45, 0.68, 0.5, 0.4, 0.6];
    const mine = [false, true, false, true, false, true];
    return Skeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: heights.length,
        itemBuilder: (context, i) {
          final bubble = Align(
            alignment: mine[i] ? Alignment.centerRight : Alignment.centerLeft,
            child: SkeletonBox(
              width: MediaQuery.of(context).size.width * widths[i],
              height: heights[i],
              radius: AppRadius.lg,
            ),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: bubble,
          );
        },
      ),
    );
  }
}

/// Placeholder de la page « profil professionnel » (bannière + infos + galerie).
class ProProfileSkeleton extends StatelessWidget {
  const ProProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final topPad = MediaQuery.of(context).padding.top;
    return Skeleton(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière + avatar
            Container(
              height: 240 + topPad,
              width: double.infinity,
              color: colors.surfaceContainerHigh,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 180, height: 22),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      SkeletonBox(width: 96, height: 24, radius: AppRadius.xs),
                      SizedBox(width: AppSpacing.sm),
                      SkeletonBox(width: 120, height: 16, radius: AppRadius.xs),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 220, height: 14),
                  SizedBox(height: AppSpacing.xl),
                  SkeletonBox(width: 130, height: 16),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 240, height: 12),
                  SizedBox(height: AppSpacing.xl),
                  SkeletonBox(width: 110, height: 16),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonBox(height: 96, radius: AppRadius.xs),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: SkeletonBox(height: 96, radius: AppRadius.xs),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: SkeletonBox(height: 96, radius: AppRadius.xs),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder d'un formulaire (édition de profil, etc.).
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de section + puces de sélection
            SkeletonBox(width: 90, height: 16),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SkeletonBox(width: 84, height: 32),
                SkeletonBox(width: 104, height: 32),
                SkeletonBox(width: 72, height: 32),
                SkeletonBox(width: 96, height: 32),
                SkeletonBox(width: 80, height: 32),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(width: 130, height: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 52, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(width: 160, height: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 52, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(width: 110, height: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 140, radius: AppRadius.lg),
            SizedBox(height: AppSpacing.xl),
            SkeletonBox(width: 140, height: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 52, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }
}

// ── Listes prêtes à l'emploi ─────────────────────────────────────────────

/// Liste verticale de [ProCardSkeleton] (résultats de recherche).
class ProCardSkeletonList extends StatelessWidget {
  const ProCardSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (_, __) => const ProCardSkeleton(),
    );
  }
}

/// Rangée horizontale de cartes (section « Populaire » de l'accueil).
class ProCardSkeletonRow extends StatelessWidget {
  const ProCardSkeletonRow({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (_, __) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.82,
          child: const ProCardSkeleton(),
        ),
      ),
    );
  }
}

/// Liste verticale de [RequestCardSkeleton] (commandes, demandes pro, admin).
class RequestCardSkeletonList extends StatelessWidget {
  const RequestCardSkeletonList({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.spacing = AppSpacing.lg,
  });

  final int count;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (_, __) => const RequestCardSkeleton(),
    );
  }
}

/// Liste verticale de [ChatTileSkeleton].
class ChatSkeletonList extends StatelessWidget {
  const ChatSkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const ChatTileSkeleton(),
    );
  }
}

/// Liste verticale de [NotificationTileSkeleton].
class NotificationSkeletonList extends StatelessWidget {
  const NotificationSkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const NotificationTileSkeleton(),
    );
  }
}
