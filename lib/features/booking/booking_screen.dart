import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/utils/validators.dart';
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

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

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
    if (_formKey.currentState?.validate() ?? false) {
      final proId =
          GoRouterState.of(context).uri.queryParameters['proId'];

      if (proId == null || proId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Aucun professionnel sélectionné')),
        );
        return;
      }

      await ref.read(bookingControllerProvider.notifier).submitRequest(
        proId: proId,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        scheduledDate: _selectedDate,
        price: double.tryParse(_priceController.text),
      );

      if (mounted) {
        final bookingState = ref.read(bookingControllerProvider);
        if (bookingState.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande envoyée avec succès')),
          );
          context.go('/orders');
        } else if (bookingState.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(bookingState.error!)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Réserver un service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
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
              Text('Décrivez votre besoin', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                validator: (v) => Validators.required(v, 'La description'),
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Décrivez le problème ou le service souhaité...',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Adresse d\'intervention', style: AppTextStyles.h4),
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
              Text('Date souhaitée', style: AppTextStyles.h4),
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
                        ? TextStyle(color: Colors.grey[600]) 
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Budget estimé (optionnel)', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
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
