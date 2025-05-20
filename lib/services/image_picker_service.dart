import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../core/logger.dart';

/// Service to handle image picking functionality across platforms
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  /// Returns File object if successful, null otherwise
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        logger.logInfo('Image picked successfully from gallery');
        return File(image.path);
      }
      logger.logWarning('No image selected from gallery');
      return null;
    } catch (e) {
      logger.logError('Error picking image from gallery', e);
      return null;
    }
  }

  /// Take photo using camera
  /// Returns File object if successful, null otherwise
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, preferredCameraDevice: CameraDevice.rear);
      if (photo != null) {
        logger.logInfo('Photo captured successfully');
        return File(photo.path);
      }
      logger.logWarning('No photo captured');
      return null;
    } catch (e) {
      logger.logError('Error taking photo', e);
      return null;
    }
  }

  /// Pick multiple images from gallery
  /// Returns List of File objects if successful, empty list otherwise
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
      logger.logInfo('${images.length} images picked successfully');
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      logger.logError('Error picking multiple images', e);
      return [];
    }
  }
}
