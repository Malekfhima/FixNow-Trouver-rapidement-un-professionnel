/// Reusable form validators.
class Validators {
  Validators._();

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final regex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!regex.hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''))) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    return null;
  }

  static String? confirmPassword(String? value, String confirmPassword) {
    final error = Validators.password(value);
    if (error != null) return error;
    if (value != confirmPassword) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.length < min) {
      return '${fieldName ?? 'Ce champ'} doit contenir au moins $min caractères';
    }
    return null;
  }
}
