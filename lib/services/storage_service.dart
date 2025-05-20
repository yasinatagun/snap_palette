import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../core/logger.dart';

/// Service to handle Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image to Firebase Storage and return the download URL
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      // Generate a unique filename with timestamp
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';

      // Ensure folder path is properly formatted
      final folderPath =
          folder.trim().endsWith('/') ? folder.trim() : '$folder/';

      logger.logInfo('Uploading image to path: images/$folderPath$fileName');

      // In Firebase Storage, folders are automatically created when files are uploaded
      // Just use the full path directly
      final storageRef = _storage.ref().child('images/$folderPath$fileName');

      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType:
            'image/${path.extension(imageFile.path).replaceAll('.', '')}',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'folder': folder,
        },
      );

      // Start upload task
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.logInfo('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.logError('Error uploading image', e);
      return null;
    }
  }

  /// Delete an image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Get reference from URL
      final ref = _storage.refFromURL(imageUrl);

      // Delete file
      await ref.delete();

      logger.logInfo('Image deleted successfully: $imageUrl');
      return true;
    } catch (e) {
      logger.logError('Error deleting image', e);
      return false;
    }
  }
}
