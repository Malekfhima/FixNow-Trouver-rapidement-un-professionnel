import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/widgets/outline_button.dart';
import 'package:fixnow/services/seed_service.dart';

/// DEV-ONLY screen to seed / wipe demo data.
///
/// Only reachable in debug builds (kDebugMode). Seeding requires the signed-in
/// user to have the `admin` role (enforced by Firestore rules).
class DebugSeedScreen extends ConsumerStatefulWidget {
  const DebugSeedScreen({super.key});

  @override
  ConsumerState<DebugSeedScreen> createState() => _DebugSeedScreenState();
}

class _DebugSeedScreenState extends ConsumerState<DebugSeedScreen> {
  final SeedService _seedService = SeedService();
  bool _busy = false;
  String? _message;
  bool? _demoPresent;

  @override
  void initState() {
    super.initState();
    _checkDemoData();
  }

  Future<void> _checkDemoData() async {
    try {
      final present = await _seedService.hasDemoData();
      if (mounted) setState(() => _demoPresent = present);
    } catch (_) {
      if (mounted) setState(() => _demoPresent = null);
    }
  }

  Future<void> _run(Future<dynamic> Function() action, String successMsg) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() => _message = successMsg);
        await _checkDemoData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message =
            'Échec : $e\n\nVérifie que ton compte a le rôle "admin" dans '
            'Firestore (users/{ton-uid}.role = "admin") : le seed est refusé '
            'par les règles de sécurité sinon.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Seed de démonstration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Écran de développement. Les données créées sont '
                      'entièrement fictives et préfixées [DÉMO] pour être '
                      'reconnaissables.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Contenu du seed :',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('• 8 catégories de services'),
            const Text('• 6 professionnels fictifs (approuvés, notés, tarifs)'),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Icon(
                  _demoPresent == null
                      ? Icons.help_outline
                      : _demoPresent!
                          ? Icons.check_circle
                          : Icons.cancel,
                  color: _demoPresent == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : _demoPresent!
                          ? AppColors.success
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _demoPresent == null
                      ? 'État inconnu'
                      : _demoPresent!
                          ? 'Données de démo présentes'
                          : 'Aucune donnée de démo',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Injecter les données de démo',
              isLoading: _busy,
              onPressed: () => _run(
                () => _seedService.seedDemoData(),
                'Seed terminé : catégories et pros [DÉMO] créés.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlineButton(
              label: 'Supprimer les données de démo',
              isExpanded: true,
              onPressed: _busy
                  ? null
                  : () => _run(
                        () => _seedService.wipeDemoData(),
                        'Données de démo supprimées.',
                      ),
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Text(_message!, style: AppTextStyles.bodySmall),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
