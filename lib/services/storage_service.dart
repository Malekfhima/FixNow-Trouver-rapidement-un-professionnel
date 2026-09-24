import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Service that wraps Firebase Storage operations.
/// Uses [XFile] (from image_picker) and [putData] to work on both
/// mobile and web — no dart:io dependency.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file and returns its download URL.
  /// Uses [putData] (bytes) so it works on web.
  Future<String> uploadFile({
    required String path,
    required XFile file,
    String? contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  /// Uploads a user avatar and returns the download URL.
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

  /// Deletes a file by its path.
  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}

/// Riverpod provider for StorageService.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
