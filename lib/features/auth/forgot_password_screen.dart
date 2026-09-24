import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/features/auth/auth_controller.dart';

/// Forgot password screen — sends a reset email via Firebase Auth.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text.trim());

    if (!mounted) return;

    if (ok) {
      setState(() => _emailSent = true);
    } else {
      final error = ref.read(authControllerProvider).error;
      AppAlerts.error(context, error ?? "Échec de l'envoi de l'email");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;
    final success =
        Theme.of(context).extension<SemanticColors>()?.success ??
            AppColors.success;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // ── Icon ──────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: AppRadius.lgAll,
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: cs.tertiary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),

              // ── Heading ───────────────────────────────────────
              Text(
                'Mot de passe\noublié ?',
                style: AppTextStyles.displayMedium.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Saisissez votre adresse email, nous vous enverrons un lien "
                'pour créer un nouveau mot de passe.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),

              if (!_emailSent) ...[
                // ── Email field ─────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _sendResetEmail(),
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'Adresse email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Submit ──────────────────────────────────────
                PrimaryButton(
                  label: 'Envoyer le lien',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _sendResetEmail,
                ),
              ] else ...[
                // ── Success state ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: success.withValues(alpha: 0.1),
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(
                      color: success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          color: cs.surface,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Email envoyé !',
                        style: AppTextStyles.h4.copyWith(
                          color: success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Vérifiez votre boîte de réception (et vos spams) '
                        'pour créer un nouveau mot de passe.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Resend button ──────────────────────────────
                PrimaryButton(
                  label: "Renvoyer l'email",
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _sendResetEmail,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // ── Back to login ─────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Retour à la connexion',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
