import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, PhoneAuthCredential;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/config/app_runtime.dart' show phoneAuthEnabled;
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/features/auth/auth_controller.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Mode de réinitialisation : par email (lien Firebase) ou par SMS (OTP).
enum _ResetMode { email, phone }

/// Étapes du parcours « par téléphone ».
enum _PhoneStep { number, code, password }

/// Forgot password screen — reset par EMAIL (lien Firebase) ou par
/// TÉLÉPHONE (code SMS puis nouveau mot de passe).
///
/// Le parcours SMS ne fonctionne que pour un numéro LIÉ au compte
/// (ajouté à l'inscription) : sinon Firebase créerait un compte vide —
/// le cas est détecté et expliqué à l'utilisateur.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  // ── Email ────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  // ── Téléphone ────────────────────────────────────────────────────
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetMode _mode = _ResetMode.email;
  _PhoneStep _phoneStep = _PhoneStep.number;
  bool _verifyInProgress = false;
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Email : envoi du lien ────────────────────────────────────────

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

  // ── Téléphone : envoi / renvoi du code SMS ───────────────────────

  Future<void> _requestCode() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

    setState(() => _verifyInProgress = true);

    try {
      await ref.read(firebaseAuthServiceProvider).verifyPhoneNumber(
            phoneNumber: _phoneController.text.trim(),
            onCompleted: (credential) {
              // Code récupéré automatiquement (auto-retrieval).
              _handleVerifiedCredential(credential);
            },
            onFailed: (error) {
              if (!mounted) return;
              setState(() => _verifyInProgress = false);
              AppAlerts.fromError(context, error);
            },
            onCodeSent: (verificationId, resendToken) {
              if (!mounted) return;
              setState(() {
                _verifyInProgress = false;
                _verificationId = verificationId;
                _resendToken = resendToken;
                _phoneStep = _PhoneStep.code;
              });
            },
            onAutoRetrieval: (verificationId) {
              _verificationId = verificationId;
            },
            resendToken: _resendToken,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifyInProgress = false);
      AppAlerts.fromError(context, e);
    }
  }

  // ── Téléphone : vérification du code puis contrôles ──────────────

  Future<void> _submitCode() async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      AppAlerts.warning(context, 'Aucun code de vérification disponible');
      return;
    }
    if (!(_codeFormKey.currentState?.validate() ?? false)) return;

    final authService = ref.read(firebaseAuthServiceProvider);
    setState(() => _verifyInProgress = true);
    try {
      final credential = authService.phoneCredential(
        verificationId: verificationId,
        smsCode: _smsController.text.trim(),
      );
      await _handleVerifiedCredential(credential);
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifyInProgress = false);
      AppAlerts.fromError(context, e);
    }
  }

  Future<void> _handleVerifiedCredential(PhoneAuthCredential credential) async {
    final authService = ref.read(firebaseAuthServiceProvider);
    setState(() => _verifyInProgress = true);
    try {
      final userCredential = await authService.signInWithPhone(credential);
      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-current-user');
      }

      // 1) Le numéro doit appartenir à un compte EXISTANT : sinon la
      //    vérification vient de créer un compte vide.
      final created = user.metadata.creationTime;
      final freshAccount = created == null ||
          DateTime.now().difference(created) < const Duration(minutes: 2);

      // 2) Le compte doit avoir un mot de passe (comptes créés par email) :
      //    un compte « téléphone » se connecte par SMS, pas par mot de passe.
      final hasPassword =
          user.providerData.any((info) => info.providerId == 'password');

      if (freshAccount || !hasPassword) {
        await authService.signOut();
        if (!mounted) return;
        setState(() {
          _verifyInProgress = false;
          _phoneStep = _PhoneStep.number;
          _smsController.clear();
          _verificationId = null;
          _resendToken = null;
        });
        AppAlerts.warning(
          context,
          freshAccount
              ? "Aucun compte existant n'est associé à ce numéro. "
                  'Inscrivez-vous avec votre email (le numéro se lie à '
                  "l'inscription) ou réinitialisez par email."
              : 'Ce compte se connecte par téléphone : aucun mot de passe '
                  'à réinitialiser. Utilisez « Continuer avec téléphone ».',
        );
        return;
      }

      setState(() {
        _verifyInProgress = false;
        _phoneStep = _PhoneStep.password;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifyInProgress = false);
      AppAlerts.fromError(context, e);
    }
  }

  // ── Téléphone : enregistrement du nouveau mot de passe ───────────

  Future<void> _savePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_passwordController.text);

    if (!mounted) return;

    if (!ok) {
      final error = ref.read(authControllerProvider).error;
      AppAlerts.error(context, error ?? 'Échec de la mise à jour');
      return;
    }

    // La session provient du code SMS : on la ferme pour revenir à un
    // écran de connexion neutre.
    await ref.read(firebaseAuthServiceProvider).signOut();
    if (!mounted) return;

    AppAlerts.success(
      context,
      'Mot de passe mis à jour ! Connectez-vous avec votre nouveau '
      'mot de passe.',
    );
    context.go('/login');
  }

  // ── UI ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
              _mode == _ResetMode.email
                  ? "Saisissez votre adresse email, nous vous enverrons un "
                      'lien pour créer un nouveau mot de passe.'
                  : 'Vérifiez votre numéro par SMS, puis choisissez un '
                      'nouveau mot de passe.',
              key: const ValueKey('reset-description'),
              style: AppTextStyles.bodyLarge.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Bascule Email / Téléphone ─────────────────────
            if (phoneAuthEnabled) ...[
              SegmentedButton<_ResetMode>(
                segments: const [
                  ButtonSegment(
                    value: _ResetMode.email,
                    label: Text('Email'),
                    icon: Icon(Icons.mail_outline, size: 18),
                  ),
                  ButtonSegment(
                    value: _ResetMode.phone,
                    label: Text('Téléphone'),
                    icon: Icon(Icons.phone_outlined, size: 18),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => setState(() {
                  _mode = selection.first;
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.xxxxl),

            if (_mode == _ResetMode.email)
              _buildEmailSection(success)
            else
              _buildPhoneSection(),

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
    );
  }

  // ── Parcours EMAIL ───────────────────────────────────────────────

  Widget _buildEmailSection(Color success) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }

  // ── Parcours TÉLÉPHONE ───────────────────────────────────────────

  Widget _buildPhoneSection() {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

    switch (_phoneStep) {
      case _PhoneStep.number:
        return Form(
          key: _phoneFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _phoneController,
                validator: (value) {
                  final digits =
                      value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                  if (digits.length < 8) {
                    return 'Numéro invalide (ex. +33 6 12 34 56 78)';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _requestCode(),
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  hintText: '+33 6 12 34 56 78',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Le numéro doit avoir été lié à votre compte à '
                "l'inscription (sinon, réinitialisez par email).",
                style: AppTextStyles.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Recevoir le code SMS',
                isLoading: _verifyInProgress || authState.isLoading,
                onPressed: _verifyInProgress ? null : _requestCode,
              ),
            ],
          ),
        );

      case _PhoneStep.code:
        return Form(
          key: _codeFormKey,
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
                    Icon(Icons.sms_outlined, color: cs.primary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Code envoyé au ${_phoneController.text}',
                        key: const ValueKey('sms-banner'),
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
              TextFormField(
                controller: _smsController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitCode(),
                maxLength: 6,
                textAlign: TextAlign.center,
                validator: (value) {
                  final code = value?.trim() ?? '';
                  if (code.length != 6) {
                    return 'Le code comporte 6 chiffres';
                  }
                  return null;
                },
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
                isLoading: _verifyInProgress || authState.isLoading,
                onPressed: _verifyInProgress ? null : _submitCode,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: _verifyInProgress
                      ? null
                      : () => setState(() {
                            _phoneStep = _PhoneStep.number;
                            _smsController.clear();
                          }),
                  child: Text(
                    'Changer de numéro',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case _PhoneStep.password:
        return Form(
          key: _passwordFormKey,
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
                    Icon(Icons.verified_user_outlined,
                        color: cs.primary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Numéro vérifié — choisissez un nouveau mot de passe',
                        key: const ValueKey('verified-banner'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                validator: Validators.password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  hintText: 'Nouveau mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirmController,
                validator: (value) =>
                    Validators.confirmPassword(value, _passwordController.text),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _savePassword(),
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  hintText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Enregistrer le mot de passe',
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ? null : _savePassword,
              ),
            ],
          ),
        );
    }
  }
}
