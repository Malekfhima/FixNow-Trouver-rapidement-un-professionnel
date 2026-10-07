import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Erreur métier du service d'images.
/// Le message est déjà en français : [ErrorMapper] le renvoie tel quel.
class StorageException implements Exception {
  final String code;
  final String message;

  const StorageException(this.code, this.message);

  @override
  String toString() => message;
}

/// Service d'upload d'images via Cloudinary (offre gratuite, upload
/// *unsigned* avec preset) — remplace Firebase Storage qui exige Blaze.
///
/// Configuration par `--dart-define` (jamais en dur dans le dépôt) :
///   --dart-define=CLOUDINARY_CLOUD_NAME=<cloud>
///   --dart-define=CLOUDINARY_UPLOAD_PRESET=<preset unsigned>
///
/// Même API publique que l'ancien service Firebase : aucun appelant
/// (avatar, galerie pro, photos de demande, images de chat) ne change.
class StorageService {
  /// Cloud name Cloudinary, lu via --dart-define.
  static const String _cloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME');

  /// Preset d'upload unsigned (non secret, restreint aux images).
  static const String _uploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  /// Limite miroir de l'ancienne règle Storage : 5 Mo.
  /// Vérifiée côté client pour renvoyer un message clair avant l'envoi.
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  final http.Client _client;
  final String _cloudNameOverride;
  final String _uploadPresetOverride;

  /// Les paramètres [cloudName] / [uploadPreset] existent pour les TESTS
  /// (défaut : --dart-define, jamais de valeur en dur dans le code).
  StorageService({
    http.Client? client,
    String? cloudName,
    String? uploadPreset,
  })  : _client = client ?? http.Client(),
        _cloudNameOverride = cloudName ?? '',
        _uploadPresetOverride = uploadPreset ?? '';

  /// Cloud name effectif (override de test ou --dart-define).
  String get _effectiveCloudName =>
      _cloudNameOverride.isNotEmpty ? _cloudNameOverride : _cloudName;

  /// Preset effectif (override de test ou --dart-define).
  String get _effectiveUploadPreset =>
      _uploadPresetOverride.isNotEmpty ? _uploadPresetOverride : _uploadPreset;

  Uri get _uploadUri => Uri.parse(
      'https://api.cloudinary.com/v1_1/$_effectiveCloudName/image/upload');

  /// Uploads an image file and returns its hosted URL (Cloudinary).
  /// Uses [XFile] bytes so it works on mobile and web — no dart:io.
  Future<String> uploadFile({
    required String path,
    required XFile file,
    String? contentType,
  }) async {
    if (_effectiveCloudName.isEmpty || _effectiveUploadPreset.isEmpty) {
      throw const StorageException(
        'not-configured',
        "Service d'images non configuré. "
            'Relancez l\'application avec CLOUDINARY_CLOUD_NAME et '
            'CLOUDINARY_UPLOAD_PRESET définis.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > maxFileSizeBytes) {
      throw const StorageException(
        'image-too-large',
        'Image trop lourde : 5 Mo maximum. '
            'Réduisez sa taille et réessayez.',
      );
    }

    // Garde « image uniquement » (les règles Storage l'imposaient avant).
    final mime = (contentType ?? file.mimeType ?? 'image/jpeg').toLowerCase();
    if (!mime.startsWith('image/')) {
      throw const StorageException(
        'unsupported-type',
        'Seules les images sont acceptées.',
      );
    }

    // public_id dérivé du chemin logique (avatars/uid, requests/…, chats/…)
    // pour garder une trace de l'organisation d'origine.
    final publicId = path.replaceAll(RegExp(r'[^a-zA-Z0-9/_-]'), '_');

    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = _effectiveUploadPreset
      ..fields['public_id'] = publicId
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: _fileNameFor(file, mime),
      ));

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final body = await streamed.stream
          .bytesToString()
          .timeout(const Duration(seconds: 15));

      if (streamed.statusCode != 200) {
        throw _remoteError(streamed.statusCode, body);
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw const StorageException(
          'upload-failed',
          "Envoi de l'image impossible. Réessayez.",
        );
      }
      return url;
    } on StorageException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on http.ClientException catch (e) {
      debugPrint('Cloudinary upload failed: $e');
      throw const StorageException(
        'network',
        'Pas de connexion internet. Vérifiez votre réseau et réessayez.',
      );
    } catch (e) {
      debugPrint('Cloudinary upload failed: $e');
      throw const StorageException(
        'upload-failed',
        "Envoi de l'image impossible. Réessayez.",
      );
    }
  }

  /// Uploads a user avatar and returns its URL.
  Future<String> uploadAvatar(String uid, XFile file) {
    return uploadFile(
      path: 'avatars/$uid',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Uploads a gallery image for a professional.
  Future<String> uploadGalleryImage(String uid, int index, XFile file) {
    return uploadFile(
      path: 'gallery/$uid/$index',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Uploads a photo attached to a service request.
  Future<String> uploadRequestPhoto(String requestId, int index, XFile file) {
    return uploadFile(
      path: 'requests/$requestId/$index',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Uploads a chat image.
  Future<String> uploadChatImage(String chatId, String messageId, XFile file) {
    return uploadFile(
      path: 'chats/$chatId/$messageId',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Chooses a plausible file name (Cloudinary s'en sert pour détecter
  /// le format quand aucun MediaType n'est fourni).
  static String _fileNameFor(XFile file, String mime) {
    final name = file.name;
    if (name.isNotEmpty && name.contains('.')) return name;
    final ext = switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      _ => 'jpg',
    };
    return '${name.isEmpty ? 'image' : name}.$ext';
  }

  /// Maps a Cloudinary HTTP error to a French [StorageException].
  StorageException _remoteError(int statusCode, String body) {
    debugPrint('Cloudinary error $statusCode: $body');
    var detail = '';
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        detail = (err['message'] as String?) ?? '';
      }
    } catch (_) {}

    if (statusCode == 401 || statusCode == 404 || detail.contains('preset')) {
      return const StorageException(
        'not-configured',
        "Service d'images mal configuré (preset d'upload invalide).",
      );
    }
    if (detail.contains('File size too large')) {
      return const StorageException(
        'image-too-large',
        'Image trop lourde : 5 Mo maximum. Réduisez sa taille et réessayez.',
      );
    }
    return const StorageException(
      'upload-failed',
      "Envoi de l'image impossible. Réessayez.",
    );
  }
}

/// Riverpod provider for StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
