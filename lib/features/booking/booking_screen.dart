import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixnow/core/constants/app_constants.dart';
import 'package:fixnow/features/booking/booking_controller.dart';
import 'package:intl/intl.dart';

/// Booking / service request screen.
class BookingScreen extends ConsumerStatefulWidget {
  final String? requestId;
  const BookingScreen({super.key, this.requestId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  final String _categoryId = 'general';
  final List<XFile> _photos = [];

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 70,
    );
    if (picked.isEmpty) return;
    setState(() {
      _photos.addAll(picked);
      if (_photos.length > AppConstants.maxPhotosPerRequest) {
        _photos.removeRange(
            AppConstants.maxPhotosPerRequest, _photos.length);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _isSubmitting => ref.read(bookingControllerProvider).isLoading;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_formKey.currentState?.validate() ?? false) {
      final proId =
          GoRouterState.of(context).uri.queryParameters['proId'];

      if (proId == null || proId.isEmpty) {
        AppAlerts.error(context, 'Aucun professionnel sélectionné');
        return;
      }

      await ref.read(bookingControllerProvider.notifier).submitRequest(
        proId: proId,
        categoryId: _categoryId,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        scheduledDate: _selectedDate,
        price: double.tryParse(_priceController.text.replaceAll(',', '.')),
        photos: _photos,
      );

      if (mounted) {
        final bookingState = ref.read(bookingControllerProvider);
        if (bookingState.isSuccess) {
          AppAlerts.success(context, 'Demande envoyée avec succès');
          context.go('/orders');
        } else if (bookingState.error != null) {
          AppAlerts.error(context, bookingState.error!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Réserver un service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Décrivez votre besoin', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                validator: (v) => Validators.minLength(v, 10, 'La description'),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Décrivez le problème ou le service souhaité...',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Photos (0..max)
              Row(
                children: [
                  const Text('Photos', style: AppTextStyles.h4),
                  const Spacer(),
                  TextButton.icon(
                    onPressed:
                        _photos.length >= AppConstants.maxPhotosPerRequest
                            ? null
                            : _pickPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18),
                    label: Text(
                        '${_photos.length}/${AppConstants.maxPhotosPerRequest}'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 84,
                child: _photos.isEmpty
                    ? const Text(
                        'Ajoutez des photos pour un devis plus précis (optionnel)',
                        style: AppTextStyles.caption,
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.mdAll,
                              child: _PickedThumb(
                                file: _photos[index],
                                width: 84,
                                height: 84,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photos.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Adresse d\'intervention', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                validator: (v) => Validators.required(v, 'L\'adresse'),
                decoration: const InputDecoration(
                  hintText: 'Adresse complète',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Date souhaitée', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Choisir une date'
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    style: _selectedDate == null
                        ? TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Budget estimé (optionnel)', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final value = double.tryParse(v.replaceAll(',', '.'));
                  if (value == null || value <= 0) {
                    return 'Entrez un budget valide (nombre positif)';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Ex: 150 €',
                  prefixIcon: Icon(Icons.euro),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxxl),
              PrimaryButton(
                label: 'Envoyer la demande',
                isLoading: bookingState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cross-platform image thumbnail: reads bytes from an [XFile] and
/// displays them with [Image.memory]. Shows a loading indicator while
/// reading.
class _PickedThumb extends StatelessWidget {
  final XFile file;
  final double width;
  final double height;

  const _PickedThumb({
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
