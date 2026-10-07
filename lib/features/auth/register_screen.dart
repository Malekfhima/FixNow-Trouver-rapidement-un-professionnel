import 'package:firebase_auth/firebase_auth.dart' show PhoneAuthCredential;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/config/app_runtime.dart' show phoneAuthEnabled;
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/features/auth/auth_controller.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';

/// Registration screen.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  bool _isPro = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Étape 2 (optionnelle) : liaison du numéro au compte ───────
  bool _linkStep = false;
  bool _verifyInProgress = false;
  String? _verificationId;
  int? _resendToken;
  String _pendingPhone = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final phone = phoneAuthEnabled ? _phoneController.text.trim() : '';
      final success =
          await ref.read(authControllerProvider.notifier).register(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text,
                asPro: _isPro,
              );

      if (success && mounted) {
        if (phone.isNotEmpty) {
          // Étape 2 : lier le numéro au compte (réinitialisation SMS).
          setState(() {
            _pendingPhone = phone;
            _linkStep = true;
          });
          AppAlerts.success(
            context,
            'Compte créé ! Vérifiez votre numéro pour pouvoir '
            'réinitialiser votre mot de passe par SMS.',
          );
          return;
        }
        AppAlerts.success(
          context,
          'Compte créé ! Un email de vérification vient de vous être envoyé '
          '(pensez à vérifier vos spams).',
        );
        context.go('/');
      } else if (mounted) {
        final error = ref.read(authControllerProvider).error;
        AppAlerts.error(context, error ?? "Échec de l'inscription");
      }
    }
  }

  /// Création de compte avec Google (aucun mot de passe : le profil
  /// Firestore est créé par le contrôleur, comme à la connexion).
  Future<void> _registerWithGoogle() async {
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (success) {
      context.go('/');
    } else {
      final error = ref.read(authControllerProvider).error;
      AppAlerts.error(context, error ?? 'Échec de la connexion Google');
    }
  }

  // ── Étape 2 : liaison du numéro (code SMS) ─────────────────────

  Future<void> _requestCode() async {
    setState(() => _verifyInProgress = true);
    try {
      await ref.read(firebaseAuthServiceProvider).verifyPhoneNumber(
            phoneNumber: _pendingPhone,
            onCompleted: _linkCredential,
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

  Future<void> _submitCode() async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      AppAlerts.warning(context, 'Aucun code de vérification disponible');
      return;
    }
    final code = _smsController.text.trim();
    if (code.length != 6) {
      AppAlerts.error(context, 'Code SMS invalide (6 chiffres)');
      return;
    }
    final credential = ref
        .read(firebaseAuthServiceProvider)
        .phoneCredential(verificationId: verificationId, smsCode: code);
    await _linkCredential(credential);
  }

  Future<void> _linkCredential(PhoneAuthCredential credential) async {
    final authService = ref.read(firebaseAuthServiceProvider);
    setState(() => _verifyInProgress = true);
    try {
      // updatePhoneNumber (et NON signInWithCredential) : on LIE le numéro
      // au compte email créé, on ne connecte pas à un autre compte.
      await authService.linkPhoneNumber(credential);

      // Best-effort : mémoriser le numéro dans le profil Firestore.
      final uid = authService.currentUser?.uid;
      if (uid != null) {
        try {
          await ref
              .read(firestoreServiceProvider)
              .updateUser(uid, {'phone': _pendingPhone});
        } catch (_) {
          // Le lien est déjà fait : la synchro du profil n'est pas bloquante.
        }
      }

      if (!mounted) return;
      AppAlerts.success(
        context,
        'Numéro lié ! Vous pourrez réinitialiser votre mot de passe par SMS.',
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifyInProgress = false);
      AppAlerts.fromError(context, e);
    }
  }

  Widget _buildLinkStep(AuthState authState, ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Lier votre\nnuméro',
                style:
                    AppTextStyles.displayMedium.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Entrez le code envoyé au $_pendingPhone : ce numéro vous '
                'permettra de réinitialiser votre mot de passe par SMS.',
                key: const ValueKey('link-phone-description'),
                style: AppTextStyles.bodyLarge
                    .copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxxxl),

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
                        'Code envoyé au $_pendingPhone',
                        key: const ValueKey('link-sms-banner'),
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

              TextField(
                controller: _smsController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitCode(),
                style: AppTextStyles.h2.copyWith(letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '— — — — — —',
                  prefixIcon: Icon(Icons.pin_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              PrimaryButton(
                label: 'Vérifier et lier',
                isLoading: _verifyInProgress || authState.isLoading,
                onPressed: _verifyInProgress || authState.isLoading
                    ? null
                    : _submitCode,
              ),
              const SizedBox(height: AppSpacing.md),

              Center(
                child: TextButton(
                  onPressed: _verifyInProgress ? null : _requestCode,
                  child: Text(
                    'Renvoyer le code',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _verifyInProgress
                      ? null
                      : () => context.go('/'),
                  child: Text(
                    'Passer pour l’instant',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

    // Étape 2 : vérification SMS du numéro renseigné à l'inscription.
    if (_linkStep) return _buildLinkStep(authState, cs);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxxxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Brand ───────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    color: cs.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxxl),

                // ── Heading ─────────────────────────────────────
                Text(
                  'Créer un\ncompte',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rejoignez la communauté FixNow',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxxl),

                // ── Name ────────────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  validator: (v) => Validators.required(v, 'Le nom'),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Email ───────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Adresse email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Password ────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  validator: Validators.password,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Confirm password ────────────────────────────
                TextFormField(
                  controller: _confirmPasswordController,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    hintText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Phone (optionnel) : réinitialisation par SMS ──
                if (phoneAuthEnabled) ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null; // champ facultatif
                      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length < 8) {
                        return 'Numéro invalide (ex. +33 6 12 34 56 78)';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Téléphone (optionnel) — ex. +33 6 12 34 56 78',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Facultatif : vérifié par SMS, il vous permettra de '
                    'réinitialiser votre mot de passe par téléphone.',
                    key: const ValueKey('phone-hint'),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Account type selector ───────────────────────
                Text(
                  'Type de compte',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: AppRadius.lgAll,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: RadioGroup<bool>(
                    groupValue: _isPro,
                    onChanged: (v) => setState(() => _isPro = v ?? false),
                    child: Column(
                      children: [
                        _AccountTypeTile(
                          title: 'Je suis client',
                          subtitle: 'Je cherche un professionnel',
                          icon: Icons.person_outline,
                          selected: !_isPro,
                          onTap: () => setState(() => _isPro = false),
                          isFirst: true,
                        ),
                        Divider(
                          height: 1,
                          color: cs.outlineVariant,
                          indent: AppSpacing.xl,
                        ),
                        _AccountTypeTile(
                          title: 'Je suis professionnel',
                          subtitle:
                              "Je propose mes services (validation par l'équipe)",
                          icon: Icons.work_outline,
                          selected: _isPro,
                          onTap: () => setState(() => _isPro = true),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Divider ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: cs.outlineVariant),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        'ou',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: cs.outlineVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Google button (création de compte Gmail) ───
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _registerWithGoogle,
                    icon: SvgPicture.asset(
                      'assets/icons/google.svg',
                      width: 20,
                      height: 20,
                    ),
                    label: const Text('Continuer avec Google'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Submit ──────────────────────────────────────
                PrimaryButton(
                  label: "S'inscrire",
                  isLoading: authState.isLoading,
                  onPressed: _register,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Login link ──────────────────────────────────
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Déjà un compte ? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: 'Se connecter',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A selectable tile for the account type radio group.
class _AccountTypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _AccountTypeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppRadius.lg) : Radius.zero,
        bottom: isLast ? const Radius.circular(AppRadius.lg) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(AppRadius.lg) : Radius.zero,
          bottom: isLast ? const Radius.circular(AppRadius.lg) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<bool>(
                value: selected,
                activeColor: cs.primary,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
