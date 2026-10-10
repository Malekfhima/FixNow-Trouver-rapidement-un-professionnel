import 'package:flutter/material.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/services/demo_data_cleanup_service.dart';

/// Debug-only tool to remove professional profiles created by the old seeder.
class DemoDataCleanupScreen extends StatefulWidget {
  const DemoDataCleanupScreen({super.key});

  @override
  State<DemoDataCleanupScreen> createState() => _DemoDataCleanupScreenState();
}

class _DemoDataCleanupScreenState extends State<DemoDataCleanupScreen> {
  final DemoDataCleanupService _service = DemoDataCleanupService();
  bool _busy = false;
  bool? _demoDataPresent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkDemoData();
  }

  Future<void> _checkDemoData() async {
    try {
      final present = await _service.hasDemoData();
      if (!mounted) return;
      setState(() {
        _demoDataPresent = present;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _demoDataPresent = null;
        _error = ErrorMapper.message(error);
      });
    }
  }

  Future<void> _removeDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les profils de démo ?'),
        content: const Text(
          'Seuls les profils professionnels demo-pro-* seront supprimés. '
          'Les profils réels et les catégories seront conservés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.removeDemoProfessionals();
      if (!mounted) return;
      setState(() {
        _demoDataPresent = false;
        _error = null;
      });
      AppAlerts.success(context, 'Profils de démonstration supprimés.');
    } catch (error) {
      if (!mounted) return;
      AppAlerts.error(context, ErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (_demoDataPresent) {
      true => 'Des profils de démonstration sont présents.',
      false => 'Aucun profil de démonstration trouvé.',
      null => 'Vérification des profils de démonstration…',
    };

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Nettoyage des données de démo')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cet outil supprime uniquement les profils professionnels '
              'demo-pro-* créés par l’ancien outil de démonstration. '
              'Les profils réels et les catégories ne sont pas modifiés.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(_error ?? status, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _busy || _demoDataPresent != true ? null : _removeDemoData,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: const Text('Supprimer les profils de démo'),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _checkDemoData,
              child: const Text('Vérifier à nouveau'),
            ),
          ],
        ),
      ),
    );
  }
}
