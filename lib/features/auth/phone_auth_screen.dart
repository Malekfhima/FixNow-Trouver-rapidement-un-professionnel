import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/primary_button.dart';
import 'package:fixnow/features/auth/auth_controller.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/models/user_model.dart';

/// Ecran de connexion par telephone (OTP).
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();

  bool _verifyInProgress = false;
  bool _smsSent = false;
  String? _verificationId;
  int? _resendToken;

  Future<void> _requestCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _verifyInProgress = true;
      });

      try {
        await ref.read(firebaseAuthServiceProvider).verifyPhoneNumber(
              phoneNumber: _phoneController.text.trim(),
              onCompleted: (credential) {
                // auto-login si le SMS arrive avant le timeout
                _verifyInProgress = false;
                setState(() {
                  _smsSent = true;
                });
                _submitCodeFromUI();
              },
              onFailed: (error) {
                setState(() {
                  _verifyInProgress = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              },
              onCodeSent: (verificationId, resendToken) {
                setState(() {
                  _verifyInProgress = false;
                  _smsSent = true;
                  _verificationId = verificationId;
                  _resendToken = resendToken;
                });
              },
              onAutoRetrieval: (verificationId) {
                setState(() {
                  _verificationId = verificationId;
                });
              },
              resendToken: _resendToken,
            );
      } catch (e) {
        setState(() {
          _verifyInProgress = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _submitCodeFromUI() async {
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun code de vérification disponible')),
      );
      return;
    }

    if (_smsController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code SMS invalide')),
      );
      return;
    }

    final authService = ref.read(firebaseAuthServiceProvider);
    setState(() {
      _verifyInProgress = true;
    });

    try {
      final userCredential = await authService.signInWithPhoneCredential(
        verificationId: _verificationId!,
        smsCode: _smsController.text.trim(),
      );

      // First SMS login: create the Firestore profile (rules allow
      // create only for one's own doc).
      final fbUser = userCredential.user;
      if (fbUser != null) {
        await ref.read(firestoreServiceProvider).ensureUser(
              AppUser(
                uid: fbUser.uid,
                name: 'Utilisateur',
                email: fbUser.email ?? '',
                phone: fbUser.phoneNumber,
                createdAt: DateTime.now(),
              ),
            );
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _verifyInProgress = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connexion par téléphone'),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Connexion\npar téléphone',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nous vous enverrons un code SMS pour vous\nconnecter à votre compte.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxxl),
              TextFormField(
                controller: _phoneController,
                validator: (v) {
                  if (!_smsSent) {
                    return 'Le numéro est requis';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+33 6 12 34 56 78',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _smsSent ? 'Renvoyer le code' : 'Continuer',
                isLoading: _verifyInProgress || authState.isLoading,
                onPressed: _smsSent ? _requestCode : _requestCode,
              ),
              if (_smsSent) ...[
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Entrez le code reçu par SMS',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _smsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Code SMS',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Verifier',
                  isLoading: _verifyInProgress,
                  onPressed: _submitCodeFromUI,
                ),
              ],
              const SizedBox(height: AppSpacing.xxxxxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text(
                      'S\'inscrire',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Preferez-vous vous connecter avec ? ',
                    style: AppTextStyles.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: Text(
                      'Google / Email',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Classe de credential pour les opérations de telephone.
