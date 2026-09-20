import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/features/professional_profile/pro_profile_controller.dart';
import 'package:fixnow/models/review_model.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Rating screen: one review per completed service request.
/// Pushed as `/review/:requestId?proId=...`.
class ReviewScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ReviewScreen({super.key, required this.requestId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(String proId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _submitting = true);

    final review = Review(
      id: widget.requestId,
      requestId: widget.requestId,
      clientId: user.uid,
      proId: proId,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    String? error;
    try {
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.createReview(review);
      // Refresh the pro's aggregated rating (client-side aggregation).
      await firestore.recomputeProRating(proId);
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // Refresh the pro profile (rating visible right away).
    ref.invalidate(proProfileControllerProvider(proId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci pour votre avis !')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final proId = GoRouterState.of(context).uri.queryParameters['proId'];

    if (proId == null || proId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Noter le professionnel')),
        body: const Center(child: Text('Professionnel introuvable')),
      );
    }

    final proState = ref.watch(proProfileControllerProvider(proId));
    final pro = proState.pro ??
        ref.watch(proByIdProvider(proId)).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Noter le professionnel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pro summary
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: pro?.avatarUrl != null
                      ? NetworkImage(pro!.avatarUrl!)
                      : null,
                  child: pro?.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    pro?.name ?? 'Professionnel',
                    style: AppTextStyles.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Votre prestation est terminée 🎉', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Votre note aide les autres clients à choisir le bon professionnel.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Star selector
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final filled = index < _rating;
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.accent,
                      size: 42,
                    ),
                  );
                }),
              ),
            ),
            Center(
              child: Text(
                _ratingLabel(_rating),
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            TextFormField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              validator: (v) => Validators.required(v, 'Le commentaire'),
              decoration: const InputDecoration(
                hintText: 'Racontez votre expérience…',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            PrimaryButton(
              label: 'Envoyer mon avis',
              isLoading: _submitting,
              onPressed: () => _submit(proId),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Très déçu';
      case 2:
        return 'Déçu';
      case 3:
        return 'Correct';
      case 4:
        return 'Très bien';
      case 5:
        return 'Excellent !';
      default:
        return '';
    }
  }
}
