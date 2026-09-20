import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/features/booking/booking_controller.dart';
import 'package:fixnow/features/professional_profile/pro_profile_controller.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:intl/intl.dart';

/// Orders / service requests screen.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(clientRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes commandes'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: requestsAsync.when(
        data: (requests) => requests.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(clientRequestsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _RequestCard(request: request);
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucune commande',
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vos demandes de service\napparaîtront ici',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final ServiceRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text(
          'Le professionnel sera notifié. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Annuler la demande',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => ref
          .read(bookingControllerProvider.notifier)
          .cancelRequest(widget.request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final statusColor = _getStatusColor(request.status);
    final canCancel = request.status == ServiceRequestStatus.pending ||
        request.status == ServiceRequestStatus.quoted;
    final hasQuote = request.quotePrice != null &&
        (request.status == ServiceRequestStatus.quoted ||
            request.status == ServiceRequestStatus.accepted ||
            request.status == ServiceRequestStatus.inProgress);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  _getStatusLabel(request.status).toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
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
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Pro name (resolved via FutureProvider.family)
          if (request.proId != null)
            Row(
              children: [
                const Icon(Icons.engineering_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Prestataire : ${ref.watch(proByIdProvider(request.proId!)).valueOrNull?.name ?? '…'}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.address,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Quote block
          if (hasQuote) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devis : ${request.quotePrice!.toStringAsFixed(0)} €',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (request.quoteNote?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      request.quoteNote!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (request.price != null &&
              request.status != ServiceRequestStatus.quoted) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.quotePrice != null ? 'Prix convenu' : 'Budget estimé',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  '${request.price!.toInt()} €',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],

          // Actions
          if ((canCancel && !_busy) || request.status == ServiceRequestStatus.completed)
            ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (request.status == ServiceRequestStatus.completed)
                  Expanded(
                    child: PrimaryButton(
                      label: 'Noter le pro',
                      isExpanded: true,
                      onPressed: () => context.push(
                        '/review/${request.id}?proId=${request.proId ?? ''}',
                      ),
                    ),
                  ),
                if (canCancel) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirmCancel,
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.error),
                      label: const Text(
                        'Annuler',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.lgAll),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pending: return AppColors.warning;
      case ServiceRequestStatus.accepted: return AppColors.primary;
      case ServiceRequestStatus.declined: return AppColors.error;
      case ServiceRequestStatus.quoted: return AppColors.accent;
      case ServiceRequestStatus.inProgress: return Colors.blue;
      case ServiceRequestStatus.completed: return AppColors.success;
      case ServiceRequestStatus.cancelled: return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pending: return 'En attente';
      case ServiceRequestStatus.accepted: return 'Acceptée';
      case ServiceRequestStatus.declined: return 'Refusée';
      case ServiceRequestStatus.quoted: return 'Devis reçu';
      case ServiceRequestStatus.inProgress: return 'En cours';
      case ServiceRequestStatus.completed: return 'Terminée';
      case ServiceRequestStatus.cancelled: return 'Annulée';
    }
  }
}
