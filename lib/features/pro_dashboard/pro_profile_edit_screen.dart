import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';

/// Available service categories (kept in sync with the seed / admin data).
const proCategories = [
  'Plomberie',
  'Électricité',
  'Menuiserie',
  'Peinture',
  'Maçonnerie',
  'Soudure',
  'Couverture',
  'Ménage',
  'Serrurerie',
  'Mécanique',
];

const weekDays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

/// Edit screen for the signed-in professional's own profile.
class ProProfileEditScreen extends ConsumerStatefulWidget {
  const ProProfileEditScreen({super.key});

  @override
  ConsumerState<ProProfileEditScreen> createState() =>
      _ProProfileEditScreenState();
}

class _ProProfileEditScreenState extends ConsumerState<ProProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _rateController = TextEditingController();

  final Set<String> _selectedCategories = {};
  final Set<String> _availableDays = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _cityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'Non connecté';
      });
      return;
    }

    try {
      final pro =
          await ref.read(firestoreServiceProvider).getProfessional(uid);
      if (!mounted) return;
      setState(() {
        _bioController.text = pro?.bio ?? '';
        _cityController.text = pro?.city ?? '';
        _rateController.text =
            pro != null && pro.hourlyRate > 0 ? pro.hourlyRate.toStringAsFixed(0) : '';
        _selectedCategories.addAll(pro?.categories ?? []);
        final availability = pro?.availability;
        if (availability != null && availability['days'] is List) {
          _availableDays.addAll(
            (availability['days'] as List).whereType<String>(),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un métier')),
      );
      return;
    }

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(firestoreServiceProvider).updateProfessional(uid, {
        'categories': _selectedCategories.toList(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'hourlyRate': double.tryParse(_rateController.text) ?? 0,
        'availability': {'days': _availableDays.toList()},
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text('Erreur : $_loadError'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Categories ──────────────────────────────
                        Text('Métiers', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: proCategories.map((category) {
                            final selected =
                                _selectedCategories.contains(category);
                            return FilterChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (v) => setState(() {
                                v ? _selectedCategories.add(category)
                                  : _selectedCategories.remove(category);
                              }),
                              selectedColor: AppColors.primaryContainer,
                              checkmarkColor: AppColors.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── City ────────────────────────────────────
                        Text('Zone d\'intervention', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _cityController,
                          validator: (v) =>
                              Validators.required(v, 'La ville'),
                          decoration: const InputDecoration(
                            hintText: 'Ville ou zone (ex : Paris 11e)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Hourly rate ─────────────────────────────
                        Text('Tarif horaire (€)', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            final value =
                                double.tryParse(v?.replaceAll(',', '.') ?? '');
                            if (value == null || value <= 0) {
                              return 'Tarif invalide';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Ex : 45',
                            prefixIcon: Icon(Icons.euro),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Bio ─────────────────────────────────────
                        Text('Présentation', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 5,
                          validator: (v) => Validators.minLength(v, 20, 'La présentation'),
                          decoration: const InputDecoration(
                            hintText:
                                'Décrivez votre expérience, vos spécialités…',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Availability ────────────────────────────
                        Text('Disponibilités', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: weekDays.map((day) {
                            final selected = _availableDays.contains(day);
                            return FilterChip(
                              label: Text(day),
                              selected: selected,
                              onSelected: (v) => setState(() {
                                v ? _availableDays.add(day)
                                  : _availableDays.remove(day);
                              }),
                              selectedColor: AppColors.primaryContainer,
                              checkmarkColor: AppColors.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: 'Enregistrer',
                          isLoading: _isSaving,
                          onPressed: _save,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
    );
  }
}
