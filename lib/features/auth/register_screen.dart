import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/features/auth/auth_controller.dart';

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
  bool _isPro = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success =
          await ref.read(authControllerProvider.notifier).register(
                name: _nameController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text,
                asPro: _isPro,
              );

      if (success && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final cs = Theme.of(context).colorScheme;

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
                const SizedBox(height: AppSpacing.xxl),

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
