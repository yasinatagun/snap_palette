import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/image_picker_service.dart';

/// Provider for ImagePickerService
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

/// Provider for the selected image
final selectedImageProvider = NotifierProvider<SelectedImageNotifier, File?>(
  () {
    return SelectedImageNotifier();
  },
);

/// Notifier class to handle selected image state
class SelectedImageNotifier extends Notifier<File?> {
  @override
  File? build() {
    return null;
  }

  /// Update the selected image
  void updateImage(File? image) {
    state = image;
  }

  /// Clear the selected image
  void clearImage() {
    state = null;
  }
}
