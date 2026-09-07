import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Orders / service requests screen.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes commandes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textHint),
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
      ),
    );
  }
}
