import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/core/utils/validators.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/services/storage_service.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Client profile editing: name, phone and avatar.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _avatarUrl;
  File? _newAvatarFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from the current profile once loaded.
    final user = ref.read(userProfileProvider).valueOrNull;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (kIsWeb) {
      // On web, ImagePicker gives bytes — keep the URL path only for IO.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Upload d\u2019avatar non supporté sur le web pour le moment')),
      );
      return;
    }
    setState(() => _newAvatarFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      String? avatarUrl = _avatarUrl;

      // Upload the new avatar if picked.
      if (_newAvatarFile != null) {
        final storage = ref.read(storageServiceProvider);
        avatarUrl = await storage.uploadAvatar(user.uid, _newAvatarFile!);
        await ref
            .read(firebaseAuthServiceProvider)
            .updatePhotoURL(avatarUrl);
      }

      await ref.read(firestoreServiceProvider).updateUser(user.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });

      await ref
          .read(firebaseAuthServiceProvider)
          .updateDisplayName(_nameController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour ✓')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar picker
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: _newAvatarFile != null
                          ? FileImage(_newAvatarFile!) as ImageProvider<Object>
                          : (_avatarUrl ?? user?.avatarUrl) != null
                              ? NetworkImage(_avatarUrl ?? user!.avatarUrl!)
                                  as ImageProvider<Object>
                              : null,
                      child: (_newAvatarFile == null &&
                              (_avatarUrl ?? user?.avatarUrl) == null)
                          ? const Icon(Icons.person,
                              color: AppColors.primary, size: 48)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: AppColors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              TextFormField(
                controller: _nameController,
                validator: (v) => Validators.required(v, 'Le nom'),
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Email is the login identifier — read-only.
              TextFormField(
                initialValue: user?.email ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email (non modifiable)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(
                label: 'Enregistrer',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
