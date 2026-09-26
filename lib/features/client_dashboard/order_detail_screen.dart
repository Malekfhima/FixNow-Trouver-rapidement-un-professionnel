import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/user_model.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';

/// Détail d'une demande de service, ouvert depuis une notification push
/// (`newRequest` → route `/orders/{requestId}`).
///
/// Affiche la demande (statut, description, date, devis du pro) et les
/// actions client autorisées par la machine à états des règles Firestore :
/// accepter un devis reçu (quoted → accepted) ou annuler (→ cancelled).
class OrdersDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const OrdersDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<OrdersDetailScreen> createState() => _OrdersDetailScreenState();
}

class _OrdersDetailScreenState extends ConsumerState<OrdersDetailScreen> {
  bool _acting = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final requestAsync = ref.watch(_requestProvider(widget.requestId));
    final proId = requestAsync.valueOrNull?.proId;
    final proAsync = proId == null
        ? const AsyncValue<AppUser?>.data(null)
        : ref.watch(_proProvider(proId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Détail de la demande'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: requestAsync.when(
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
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.lg),
                Text(ErrorMapper.message(e), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(_requestProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (request) {
          if (request == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      size: 64, color: AppColors.warning),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Demande introuvable',
                      style: AppTextStyles.h4.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return _RequestDetail(
            request: request,
            pro: proAsync.valueOrNull,
            acting: _acting,
            onAcceptQuote: () => _transition(request, ServiceRequestStatus.accepted),
            onDecline: () => _transition(request, ServiceRequestStatus.cancelled),
          );
        },
      ),
    );
  }

  Future<void> _transition(
    ServiceRequest request,
    ServiceRequestStatus target,
  ) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateRequestStatus(request.id, target);
      if (!mounted) return;
      AppAlerts.success(
          context, target == ServiceRequestStatus.accepted ? 'Devis accepté' : 'Demande annulée');
      context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      AppAlerts.error(context, ErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }
}

/// Streams the request document (null when missing or unreadable).
final _requestProvider = StreamProvider.family
    .autoDispose<ServiceRequest?, String>((ref, requestId) {
  return ref
      .watch(firestoreServiceProvider)
      .requestStream(requestId);
});

/// Streams the public identity of the assigned pro.
final _proProvider =
    StreamProvider.family.autoDispose<AppUser?, String>((ref, proId) {
  return ref.watch(firestoreServiceProvider).userStream(proId);
});

class _RequestDetail extends StatelessWidget {
  final ServiceRequest request;
  final AppUser? pro;
  final bool acting;
  final VoidCallback onAcceptQuote;
  final VoidCallback onDecline;

  const _RequestDetail({
    required this.request,
    required this.pro,
    required this.acting,
    required this.onAcceptQuote,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (request.status) {
      ServiceRequestStatus.pending => 'En attente de réponse',
      ServiceRequestStatus.accepted => 'Devis accepté',
      ServiceRequestStatus.quoted => 'Devis reçu',
      ServiceRequestStatus.inProgress => 'Intervention en cours',
      ServiceRequestStatus.completed => 'Prestation terminée',
      ServiceRequestStatus.declined => 'Refusée par le pro',
      ServiceRequestStatus.cancelled => 'Annulée',
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(
                    url: pro?.avatarUrl,
                    radius: 24,
                    foregroundColor: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pro?.name ?? 'Professionnel',
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text(statusLabel,
                            style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(request.description,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis),
              if (request.scheduledDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Intervention prévue le '
                  '${request.scheduledDate!.day}/${request.scheduledDate!.month}/${request.scheduledDate!.year}',
                  style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Devis (champ `price` réservé au pro, jamais écrit par le client).
        if (request.price != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.request_quote_rounded,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Devis : ${request.price!.toStringAsFixed(0)} €',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        if (request.price != null) const SizedBox(height: AppSpacing.md),

        // Actions client : accepter un devis reçu ou annuler une demande
        // en attente (transitions autorisées par les règles Firestore).
        if (request.status == ServiceRequestStatus.quoted ||
            request.status == ServiceRequestStatus.pending)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: acting ? null : onDecline,
                  child: const Text('Annuler'),
                ),
              ),
              if (request.status == ServiceRequestStatus.quoted) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: acting ? null : onAcceptQuote,
                    child: const Text('Accepter le devis'),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
