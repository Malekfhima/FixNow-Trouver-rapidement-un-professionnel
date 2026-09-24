import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/constants/app_constants.dart';
import 'package:fixnow/services/storage_service.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
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
  final List<String> _galleryUrls = [];
  final List<XFile> _newGalleryFiles = [];
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
        _rateController.text = pro != null && pro.hourlyRate > 0
            ? pro.hourlyRate.toStringAsFixed(0)
            : '';
        _selectedCategories.addAll(pro?.categories ?? []);
        _galleryUrls.addAll(pro?.gallery ?? []);
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
        _loadError = ErrorMapper.message(e);
      });
    }
  }

  Future<void> _pickGalleryPhotos() async {
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 70,
    );
    if (picked.isEmpty) return;
    setState(() {
      _newGalleryFiles.addAll(picked);
      final total = _galleryUrls.length + _newGalleryFiles.length;
      if (total > AppConstants.maxGalleryPhotos) {
        _newGalleryFiles.removeRange(
            _newGalleryFiles.length - (total - AppConstants.maxGalleryPhotos),
            _newGalleryFiles.length);
      }
    });
  }

  Widget _galleryThumb({required Widget child, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Stack(
        children: [
          ClipRRect(borderRadius: AppRadius.mdAll, child: child),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    color: Theme.of(context).colorScheme.onPrimary, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategories.isEmpty) {
      AppAlerts.warning(context, 'Sélectionnez au moins un métier');
      return;
    }

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final storage = ref.read(storageServiceProvider);
      final uploaded = <String>[];
      for (var i = 0; i < _newGalleryFiles.length; i++) {
        final url = await storage.uploadGalleryImage(
          uid,
          _galleryUrls.length + i,
          _newGalleryFiles[i],
        );
        uploaded.add(url);
      }
      final fullGallery = [..._galleryUrls, ...uploaded];
      if (fullGallery.length > AppConstants.maxGalleryPhotos) {
        fullGallery.removeRange(
            AppConstants.maxGalleryPhotos, fullGallery.length);
      }

      await ref.read(firestoreServiceProvider).updateProfessional(uid, {
        'categories': _selectedCategories.toList(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'hourlyRate': double.tryParse(_rateController.text) ?? 0,
        'availability': {'days': _availableDays.toList()},
        'gallery': fullGallery,
      });
      if (!mounted) return;
      AppAlerts.success(context, 'Profil enregistré');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppAlerts.fromError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mon profil pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const FormSkeleton()
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
                        const Text('Métiers', style: AppTextStyles.h4),
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
                                v
                                    ? _selectedCategories.add(category)
                                    : _selectedCategories.remove(category);
                              }),
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              checkmarkColor: AppColors.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── City ────────────────────────────────────
                        const Text('Zone d\'intervention',
                            style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _cityController,
                          validator: (v) => Validators.required(v, 'La ville'),
                          decoration: const InputDecoration(
                            hintText: 'Ville ou zone (ex : Paris 11e)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Hourly rate ─────────────────────────────
                        const Text('Tarif horaire (€)',
                            style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            final value = double.tryParse(
                                v?.replaceAll(',', '.') ?? '');
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
                        const Text('Présentation', style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 5,
                          validator: (v) =>
                              Validators.minLength(v, 20, 'La présentation'),
                          decoration: const InputDecoration(
                            hintText:
                                'Décrivez votre expérience, vos spécialités…',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Availability ────────────────────────────
                        const Text('Disponibilités', style: AppTextStyles.h4),
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
                                v
                                    ? _availableDays.add(day)
                                    : _availableDays.remove(day);
                              }),
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              checkmarkColor: AppColors.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Gallery ───────────────────────────────
                        Row(
                          children: [
                            const Text('Galerie de réalisations',
                                style: AppTextStyles.h4),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _galleryUrls.length +
                                          _newGalleryFiles.length >=
                                      AppConstants.maxGalleryPhotos
                                  ? null
                                  : _pickGalleryPhotos,
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 18),
                              label: Text(
                                  '${_galleryUrls.length + _newGalleryFiles.length}/${AppConstants.maxGalleryPhotos}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 96,
                          child: (_galleryUrls.isEmpty &&
                                  _newGalleryFiles.isEmpty)
                              ? const Text(
                                  'Montrez vos réalisations : cela rassure les clients.',
                                  style: AppTextStyles.caption,
                                )
                              : ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (var i = 0;
                                        i < _galleryUrls.length;
                                        i++)
                                      _galleryThumb(
                                        child: Image.network(
                                          _galleryUrls[i],
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                        onRemove: () => setState(
                                            () => _galleryUrls.removeAt(i)),
                                      ),
                                    for (var i = 0;
                                        i < _newGalleryFiles.length;
                                        i++)
                                      _galleryThumb(
                                        child: _XFileThumb(
                                          file: _newGalleryFiles[i],
                                          width: 96,
                                          height: 96,
                                        ),
                                        onRemove: () => setState(() =>
                                            _newGalleryFiles.removeAt(i)),
                                      ),
                                  ],
                                ),
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

/// Cross-platform image thumbnail from an [XFile].
class _XFileThumb extends StatelessWidget {
  final XFile file;
  final double width;
  final double height;

  const _XFileThumb({
    required this.file,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        }
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
