import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/admin/admin_controller.dart';
import 'package:fixnow/models/professional_model.dart';

/// Admin dashboard: validation of pros, categories, basic stats.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final stats = ref.read(adminControllerProvider.notifier).stats;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Validation'),
            Tab(text: 'Pros'),
            Tab(text: 'Catégories'),
            Tab(text: 'Signalements'),
          ],
        ),
      ),
      body: state.isLoading
          ? const RequestCardSkeletonList(
              padding: EdgeInsets.all(AppSpacing.lg),
              spacing: AppSpacing.md,
            )
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Erreur : ${state.error}\n\n'
                      'Vérifie que ton compte a le rôle « admin » dans Firestore.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _ValidationTab(state: state),
                    _ProsTab(state: state),
                    _CategoriesTab(state: state),
                    const _ReportsTab(),
                  ],
                ),
      floatingActionButton: stats == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  ref.read(adminControllerProvider.notifier).load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
    );
  }
}

// ── Validation tab ──────────────────────────────────────────────────────

class _ValidationTab extends ConsumerWidget {
  final AdminState state;
  const _ValidationTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = state.pendingPros;
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_outlined, size: 64, color: AppColors.success),
            const SizedBox(height: AppSpacing.lg),
            Text('Aucun pro en attente',
                style: AppTextStyles.h4.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final pro = pending[index];
        return _ProCard(
          pro: pro,
          actions: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    ref.read(adminControllerProvider.notifier).rejectPro(pro),
                child: const Text('Refuser',
                    style: TextStyle(color: AppColors.error)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                label: 'Valider',
                onPressed: () =>
                    ref.read(adminControllerProvider.notifier).approvePro(pro),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Pros tab ────────────────────────────────────────────────────────────

class _ProsTab extends StatelessWidget {
  final AdminState state;
  const _ProsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final pros = state.allPros;
    if (pros.isEmpty) {
      return const Center(child: Text('Aucun professionnel'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: pros.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final pro = pros[index];
        return ListTile(
          leading: AppAvatar(
            url: pro.avatarUrl,
            radius: 20,
            foregroundColor: AppColors.primary,
          ),
          title: Text(pro.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${pro.city} · ${pro.categories.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: _StatusChip(status: pro.status),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ProStatus.pending => ('En attente', AppColors.warning),
      ProStatus.approved => ('Approuvé', AppColors.success),
      ProStatus.rejected => ('Refusé', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Categories tab ──────────────────────────────────────────────────────

class _CategoriesTab extends ConsumerWidget {
  final AdminState state;
  const _CategoriesTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = state.categories;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${categories.length} catégories',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _addCategoryDialog(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: const Icon(Icons.category_outlined,
                    color: AppColors.primary),
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  onPressed: () => ref
                      .read(adminControllerProvider.notifier)
                      .deleteCategory(category),
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                tileColor: Theme.of(context).colorScheme.surface,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addCategoryDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex : Jardinage'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(adminControllerProvider.notifier)
          .addCategory(controller.text.trim());
    }
    controller.dispose();
  }
}

// ── Reports tab ─────────────────────────────────────────────────────────

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(_openReportsProvider);

    return reportsAsync.when(
      data: (reports) => reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined,
                      size: 64, color: AppColors.success),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Aucun signalement en attente',
                      style: AppTextStyles.h4
                          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final report = reports[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${report['targetType'] ?? 'contenu'} · ${report['reason'] ?? 'non précisé'}',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Cible : ${report['targetId'] ?? '?'}',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => ref
                                  .read(adminControllerProvider.notifier)
                                  .resolveReport(report['id'] as String,
                                      valid: false),
                              child: const Text('Rejeter'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Modérer',
                              onPressed: () => ref
                                  .read(adminControllerProvider.notifier)
                                  .resolveReport(report['id'] as String,
                                      valid: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      loading: () => const RequestCardSkeletonList(
        padding: EdgeInsets.all(AppSpacing.lg),
        spacing: AppSpacing.md,
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Erreur de chargement',
                style: AppTextStyles.h4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ErrorMapper.message(e),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => ref.invalidate(_openReportsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _openReportsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminControllerProvider.notifier).openReportsStream();
});

// ── Shared pro card ─────────────────────────────────────────────────────

class _ProCard extends StatelessWidget {
  final Professional pro;
  final List<Widget> actions;
  const _ProCard({required this.pro, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                url: pro.avatarUrl,
                radius: 20,
                foregroundColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pro.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${pro.city} · ${pro.categories.join(', ')} · ${pro.hourlyRate.toInt()} €/h',
                      style: AppTextStyles.caption
                          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pro.bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(pro.bio,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(children: actions),
        ],
      ),
    );
  }
}
