import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/image_picker_service.dart';

/// Provider for the ImagePickerService
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

/// Provider for the selected image
final selectedImageProvider = StateProvider<File?>((ref) => null);

/// Provider for multiple selected images
final selectedImagesProvider = StateProvider<List<File>>((ref) => []);

/// Provider for handling image picking operations
final imagePickerControllerProvider = Provider((ref) {
  return ImagePickerController(ref);
});

/// Controller class for handling image picking operations
class ImagePickerController {
  final Ref _ref;

  ImagePickerController(this._ref);

  /// Pick single image from gallery
  Future<void> pickImage() async {
    final service = _ref.read(imagePickerServiceProvider);
    final image = await service.pickImageFromGallery();
    if (image != null) {
      _ref.read(selectedImageProvider.notifier).state = image;
    }
  }

  /// Take photo using camera
  Future<void> takePhoto() async {
    final service = _ref.read(imagePickerServiceProvider);
    final photo = await service.takePhoto();
    if (photo != null) {
      _ref.read(selectedImageProvider.notifier).state = photo;
    }
  }

  /// Pick multiple images from gallery
  Future<void> pickMultipleImages() async {
    final service = _ref.read(imagePickerServiceProvider);
    final images = await service.pickMultipleImages();
    _ref.read(selectedImagesProvider.notifier).state = images;
  }

  /// Clear selected image
  void clearSelectedImage() {
    _ref.read(selectedImageProvider.notifier).state = null;
  }

  /// Clear selected images
  void clearSelectedImages() {
    _ref.read(selectedImagesProvider.notifier).state = [];
  }
}
