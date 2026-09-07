import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that wraps Firebase Storage operations.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file and returns its download URL.
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putFile(file, metadata);
    return await ref.getDownloadURL();
  }

  /// Uploads a user avatar and returns the download URL.
  Future<String> uploadAvatar(String uid, File file) async {
    return uploadFile(
      path: 'avatars/$uid',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Uploads a gallery image for a professional.
  Future<String> uploadGalleryImage(String uid, int index, File file) async {
    return uploadFile(
      path: 'gallery/$uid/$index',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Uploads a photo attached to a service request.
  Future<String> uploadRequestPhoto(String requestId, int index, File file) async {
    return uploadFile(
      path: 'requests/$requestId/$index',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Uploads a chat image.
  Future<String> uploadChatImage(String chatId, String messageId, File file) async {
    return uploadFile(
      path: 'chats/$chatId/$messageId',
      file: file,
      contentType: 'image/jpeg',
    );
  }

  /// Deletes a file by its path.
  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}

/// Riverpod provider for StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
