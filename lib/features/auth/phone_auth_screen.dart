import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';

/// Phone number authentication screen with OTP verification.
class PhoneAuthScreen extends StatelessWidget {
  const PhoneAuthScreen({super.key});

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
              Text('Vérification\ntéléphone', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Entrez votre numéro pour recevoir un code OTP',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+33 6 12 34 56 78',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Envoyer le code',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
