import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/models/address_model.dart';
import 'package:fixnow/services/firestore_service.dart';

/// Saved client addresses ("Maison", "Bureau"…), stored in
/// `users/{uid}.addresses`. Consult, add, delete.
class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  bool _saving = false;

  static const _maxAddresses = 10;

  Future<void> _openAddSheet() async {
    final user = ref.read(userProfileProvider).valueOrNull;
    final current = user?.addresses ?? const <Address>[];
    if (current.length >= _maxAddresses) {
      AppAlerts.info(
        context,
        'Vous avez atteint la limite de $_maxAddresses adresses enregistrées.',
      );
      return;
    }
    final Address? result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddressFormSheet(),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final updated = [...current, result];
      await ref
          .read(firestoreServiceProvider)
          .updateAddresses(user!.uid, updated);
    } catch (e) {
      if (mounted) AppAlerts.fromError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Address address) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: const Text('Supprimer l\'adresse ?'),
        content: Text(
          '« ${address.label.isEmpty ? 'Sans nom' : address.label} » sera '
          'supprimée définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final updated = user.addresses.where((a) => a != address).toList();
      await ref
          .read(firestoreServiceProvider)
          .updateAddresses(user.uid, updated);
    } catch (e) {
      if (mounted) AppAlerts.fromError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Mes adresses')),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Impossible de charger vos adresses.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (user) {
          final addresses = user?.addresses ?? const <Address>[];
          if (addresses.isEmpty) {
            return _EmptyState(onAdd: _openAddSheet);
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              ...addresses.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined,
                          color: AppColors.primary),
                      title: Text(
                        a.label.isEmpty ? 'Adresse' : a.label,
                        style: AppTextStyles.bodyMedium,
                      ),
                      subtitle: Text(
                        a.notes != null && a.notes!.trim().isNotEmpty
                            ? '${a.fullAddress}\n${a.notes}'
                            : a.fullAddress,
                        style: AppTextStyles.bodySmall,
                      ),
                      isThreeLine:
                          a.notes != null && a.notes!.trim().isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        tooltip: 'Supprimer',
                        onPressed: _saving ? null : () => _delete(a),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.lgAll,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: PrimaryButton(
                  label: 'Ajouter une adresse',
                  isLoading: _saving,
                  onPressed: _openAddSheet,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            const Text('Aucune adresse enregistrée',
                style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enregistrez vos adresses habituelles (maison, bureau…) '
              'pour les retrouver d\'un seul geste lors d\'une réservation.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Ajouter une adresse', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

/// Modal form: label + full address (+ optional notes).
class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet();

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      Address(
        label: _labelController.text.trim().isEmpty
            ? 'Adresse'
            : _labelController.text.trim(),
        fullAddress: _addressController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouvelle adresse', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _labelController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Label (Maison, Bureau…)',
                prefixIcon: Icon(Icons.bookmark_border_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'L\'adresse'),
              decoration: const InputDecoration(
                labelText: 'Adresse complète',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              minLines: 1,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Enregistrer',
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
