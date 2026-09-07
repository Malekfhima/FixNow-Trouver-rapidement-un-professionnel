import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';

/// Booking / service request screen.
class BookingScreen extends StatelessWidget {
  final String? requestId;
  const BookingScreen({super.key, this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Réserver un service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Décrivez votre besoin', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Décrivez le problème ou le service souhaité...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Photos (optionnel)', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.lgAll,
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        color: AppColors.textHint),
                    const SizedBox(height: 4),
                    Text('Ajouter des photos',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Adresse', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.md),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Adresse d\'intervention',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Date souhaitée', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.md),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Choisir une date',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Budget estimé (optionnel)', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.md),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ex: 150 €',
                prefixIcon: Icon(Icons.euro),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxxl),
            PrimaryButton(
              label: 'Envoyer la demande',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
