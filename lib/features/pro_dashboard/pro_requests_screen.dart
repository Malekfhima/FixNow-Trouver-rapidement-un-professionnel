import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/models/service_request_state_machine.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/widgets/outline_button.dart';
import 'package:fixnow/features/pro_dashboard/pro_requests_controller.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:intl/intl.dart';

/// Pro dashboard — incoming requests with accept / decline / quote actions.
class ProRequestsScreen extends ConsumerWidget {
  const ProRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proRequestsControllerProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Mes demandes'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Nouvelles'),
              Tab(text: 'En cours'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(child: Text('Erreur : ${state.error}'))
                : TabBarView(
                    children: [
                      _PendingTab(requests: state.pending),
                      _ActiveTab(requests: state.active),
                      _HistoryList(requests: state.history),
                    ],
                  ),
      ),
    );
  }
}

// ── Pending tab ─────────────────────────────────────────────────────────

class _PendingTab extends ConsumerWidget {
  final List<ServiceRequest> requests;
  const _PendingTab({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) return const _EmptyView();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _PendingCard(request: request);
      },
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  final ServiceRequest request;
  const _PendingCard({required this.request});

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      AppAlerts.error(context, error);
    }
  }

  Future<void> _openQuoteDialog() async {
    final priceController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final quoted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proposer un devis'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix (€)',
                  prefixIcon: Icon(Icons.euro),
                ),
                validator: (v) {
                  final value = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (value == null || value <= 0) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Détail du devis (optionnel)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (quoted != true || !mounted) return;

    // Validation robuste : nombre positif (l'ancien code crashait sur
    // une entrée non numérique).
    final price = double.tryParse(
        priceController.text.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      if (mounted) {
        AppAlerts.warning(context, 'Entrez un prix valide (nombre positif)');
      }
      return;
    }
    await _run(
      () => ref.read(proRequestsControllerProvider.notifier).sendQuote(
            request: widget.request,
            price: price,
            note: noteController.text.trim(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

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
          _RequestHeader(request: request),
          const SizedBox(height: AppSpacing.md),
          _ActionRow(
            children: [
              Expanded(
                child: OutlineButton(
                  label: 'Refuser',
                  isExpanded: true,
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () => ref
                                .read(proRequestsControllerProvider.notifier)
                                .declineRequest(request),
                          ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlineButton(
                  label: 'Devis',
                  isExpanded: true,
                  onPressed:
                      _busy ? null : _openQuoteDialog,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Accepter',
                  isExpanded: true,
                  onPressed: _busy
                      ? null
                      : () => _run(
                            () => ref
                                .read(proRequestsControllerProvider.notifier)
                                .acceptRequest(request),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active tab ──────────────────────────────────────────────────────────

class _ActiveTab extends ConsumerWidget {
  final List<ServiceRequest> requests;
  const _ActiveTab({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) return const _EmptyView();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final request = requests[index];
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
              _RequestHeader(request: request),
              if (request.quotePrice != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Devis : ${request.quotePrice!.toStringAsFixed(0)} €'
                  '${request.quoteNote?.isNotEmpty == true ? ' — ${request.quoteNote}' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _ActionRow(
                children: [
                  // State machine : uniquement les actions valides du pro
                  if (request.canTransitionTo(
                      ServiceRequestStatus.inProgress, ActorRole.pro))
                    Expanded(
                      child: PrimaryButton(
                        label: 'Démarrer',
                        isExpanded: true,
                        onPressed: () => ref
                            .read(proRequestsControllerProvider.notifier)
                            .startWork(request),
                      ),
                    ),
                  if (request.status == ServiceRequestStatus.inProgress) ...[
                    Expanded(
                      child: OutlineButton(
                        label: 'Message',
                        isExpanded: true,
                        onPressed: () => context.push('/chat'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Terminer',
                        isExpanded: true,
                        onPressed: () => ref
                            .read(proRequestsControllerProvider.notifier)
                            .completeWork(request),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── History tab ─────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final List<ServiceRequest> requests;
  const _HistoryList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const _EmptyView();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final request = requests[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RequestHeader(request: request),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────

class _RequestHeader extends StatelessWidget {
  final ServiceRequest request;
  const _RequestHeader({required this.request});

  String get _statusLabel {
    switch (request.status) {
      case ServiceRequestStatus.pending:
        return 'Nouvelle demande';
      case ServiceRequestStatus.accepted:
        return 'Acceptée';
      case ServiceRequestStatus.declined:
        return 'Refusée';
      case ServiceRequestStatus.quoted:
        return 'Devis envoyé';
      case ServiceRequestStatus.inProgress:
        return 'En cours';
      case ServiceRequestStatus.completed:
        return 'Terminée';
      case ServiceRequestStatus.cancelled:
        return 'Annulée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _statusLabel.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              DateFormat('dd MMM yyyy').format(request.createdAt),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          request.description,
          style: AppTextStyles.bodyMedium
              .copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                request.address,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (request.scheduledDate != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(
                DateFormat('dd/MM').format(request.scheduledDate!),
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final List<Widget> children;
  const _ActionRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(children: children);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucune demande ici',
            style: AppTextStyles.h4.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Les nouvelles demandes apparaîtront dans cet onglet',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
