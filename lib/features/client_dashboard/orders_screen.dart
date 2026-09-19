import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/booking/booking_controller.dart';
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
                    return _buildRequestCard(request);
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildRequestCard(ServiceRequest request) {
    final statusColor = _getStatusColor(request.status);

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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
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
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
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
          if (request.price != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget estimé', style: AppTextStyles.bodySmall),
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
        ],
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
