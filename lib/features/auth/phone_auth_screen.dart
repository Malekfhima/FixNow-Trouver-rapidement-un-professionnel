import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/features/auth/auth_controller.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/models/user_model.dart';

/// Écran de connexion par téléphone (OTP).
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();

  bool _verifyInProgress = false;
  bool _smsSent = false;
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _verifyInProgress = true;
      });

      try {
        await ref.read(firebaseAuthServiceProvider).verifyPhoneNumber(
              phoneNumber: _phoneController.text.trim(),
              onCompleted: (credential) {
                // auto-login si le SMS arrive avant le timeout
                _verifyInProgress = false;
                if (mounted) {
                  setState(() {
                    _smsSent = true;
                  });
                  _submitCodeFromUI();
                }
              },
              onFailed: (error) {
                setState(() {
                  _verifyInProgress = false;
                });
                if (mounted) {
                  AppAlerts.fromError(context, error);
                }
              },
              onCodeSent: (verificationId, resendToken) {
                setState(() {
                  _verifyInProgress = false;
                  _smsSent = true;
                  _verificationId = verificationId;
                  _resendToken = resendToken;
                });
              },
              onAutoRetrieval: (verificationId) {
                setState(() {
                  _verificationId = verificationId;
                });
              },
              resendToken: _resendToken,
            );
      } catch (e) {
        setState(() {
          _verifyInProgress = false;
        });
        if (mounted) {
          AppAlerts.fromError(context, e);
        }
      }
    }
  }

  Future<void> _submitCodeFromUI() async {
    if (_verificationId == null) {
      AppAlerts.warning(context, 'Aucun code de vérification disponible');
      return;
    }

    if (_smsController.text.trim().length < 6) {
      AppAlerts.error(context, 'Code SMS invalide');
      return;
    }

    final authService = ref.read(firebaseAuthServiceProvider);
    setState(() {
      _verifyInProgress = true;
    });

    try {
      final userCredential = await authService.signInWithPhoneCredential(
        verificationId: _verificationId!,
        smsCode: _smsController.text.trim(),
      );

      // First SMS login: create the Firestore profile (rules allow
      // create only for one's own doc).
      final fbUser = userCredential.user;
      if (fbUser != null) {
        await ref.read(firestoreServiceProvider).ensureUser(
              AppUser(
                uid: fbUser.uid,
                name: 'Utilisateur',
                email: fbUser.email ?? '',
                phone: fbUser.phoneNumber,
                createdAt: DateTime.now(),
              ),
            );
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _verifyInProgress = false;
      });
      if (mounted) {
        AppAlerts.fromError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

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
                  color: cs.primaryContainer,
                  borderRadius: AppRadius.lgAll,
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: cs.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),

              // ── Heading ───────────────────────────────────────
              Text(
                'Connexion\npar téléphone',
                style: AppTextStyles.displayMedium.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nous vous enverrons un code SMS pour vous connecter '
                'à votre compte.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),

              // ── Step indicator ────────────────────────────────
              _StepIndicator(
                currentStep: _smsSent ? 1 : 0,
                steps: const ['Numéro', 'Code SMS'],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Phone field ───────────────────────────────────
              TextFormField(
                controller: _phoneController,
                validator: (v) {
                  final digits =
                      v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                  if (digits.length < 8) {
                    return 'Numéro invalide (ex. +33 6 12 34 56 78)';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
                enabled: !_smsSent,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _requestCode(),
                decoration: const InputDecoration(
                  hintText: '+33 6 12 34 56 78',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Send code button ──────────────────────────────
              PrimaryButton(
                label: _smsSent ? 'Renvoyer le code' : 'Envoyer le code',
                isLoading: _verifyInProgress || authState.isLoading,
                onPressed: _requestCode,
              ),

              // ── SMS code section ──────────────────────────────
              if (_smsSent) ...[
                const SizedBox(height: AppSpacing.xxl),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: AppRadius.lgAll,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sms_outlined,
                              color: cs.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Code envoyé au ${_phoneController.text}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Entrez le code reçu par SMS',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _smsController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitCodeFromUI(),
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2.copyWith(
                          letterSpacing: 8,
                        ),
                        decoration: const InputDecoration(
                          hintText: '— — — — — —',
                          prefixIcon: Icon(Icons.pin_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: 'Vérifier le code',
                        isLoading: _verifyInProgress,
                        onPressed: _submitCodeFromUI,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxxxl),

              // ── Footer links ──────────────────────────────────
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Pas encore de compte ? ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: "S'inscrire",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push('/register'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Autre méthode ? ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: 'Google / Email',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push('/login'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple step indicator for the phone auth flow.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepIndicator({
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: i <= currentStep
                      ? cs.primary
                      : cs.outlineVariant,
                  borderRadius: AppRadius.fullAll,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: i <= currentStep
                      ? cs.primary
                      : cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: i <= currentStep
                      ? Icon(
                          Icons.check_rounded,
                          color: cs.onPrimary,
                          size: 16,
                        )
                      : Text(
                          '${i + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                steps[i],
                style: AppTextStyles.bodySmall.copyWith(
                  color: i <= currentStep
                      ? cs.primary
                      : cs.onSurfaceVariant,
                  fontWeight: i <= currentStep
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
