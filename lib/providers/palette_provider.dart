import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logger.dart';
import '../models/palette_model.dart';
import '../services/palette_service.dart';
import 'firestore_provider.dart';
import 'storage_provider.dart';
import 'user_provider.dart';

/// Provider for PaletteService
final paletteServiceProvider = Provider<PaletteService>((ref) {
  return PaletteService();
});

/// Provider for the extracted color palette
final colorPaletteProvider =
    NotifierProvider<ColorPaletteNotifier, List<Color>>(() {
      return ColorPaletteNotifier();
    });

/// Provider for palette extraction loading state
final paletteLoadingProvider = NotifierProvider<LoadingNotifier, bool>(() {
  return LoadingNotifier();
});

/// Provider for saving palette loading state
final savingPaletteProvider = NotifierProvider<LoadingNotifier, bool>(() {
  return LoadingNotifier();
});

/// Provider for user's saved palettes
final userPalettesProvider =
    NotifierProvider<UserPalettesNotifier, List<PaletteModel>>(() {
      return UserPalettesNotifier();
    });

/// Notifier class for loading state
class LoadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setLoading(bool loading) {
    state = loading;
  }
}

/// Notifier class to handle user palettes
class UserPalettesNotifier extends Notifier<List<PaletteModel>> {
  @override
  List<PaletteModel> build() {
    return [];
  }

  /// Fetch user palettes from Firestore
  Future<void> fetchUserPalettes() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final palettes = await firestoreService.getUserPalettes();
      state = palettes;
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Delete a palette
  Future<void> deletePalette(String paletteId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deletePalette(paletteId);

      // Remove from local state
      state = state.where((palette) => palette.id != paletteId).toList();
    } catch (e) {
      // Keep current state on error
    }
  }
}

/// Notifier class to handle color palette state
class ColorPaletteNotifier extends Notifier<List<Color>> {
  late PaletteService _paletteService;

  @override
  List<Color> build() {
    _paletteService = ref.watch(paletteServiceProvider);
    return [];
  }

  /// Extract colors from an image file
  Future<void> extractColors(File? imageFile, {int maxColorCount = 5}) async {
    if (imageFile == null) {
      state = [];
      return;
    }

    state = await _paletteService.extractColorsFromImage(
      imageFile,
      maxColorCount: maxColorCount,
    );
  }

  /// Clear the color palette
  void clearPalette() {
    state = [];
  }

  /// Get hex value for a color
  String getHexValue(Color color) {
    return _paletteService.colorToHex(color);
  }

  /// Save current palette to Firestore
  Future<PaletteModel?> savePalette({String? name, File? imageFile}) async {
    if (state.isEmpty) return null;

    try {
      ref.read(savingPaletteProvider.notifier).setLoading(true);

      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        final storageService = ref.read(storageServiceProvider);

        // Create a folder structure based on the user's email
        final currentUser = ref.read(userProvider);
        String userFolder = 'user-palettes';

        if (currentUser?.email != null) {
          // Clean the email to use as a folder name
          userFolder = 'users/${currentUser!.email.replaceAll('.', '_')}';
        }

        // Pass the user-specific folder path for better organization
        imageUrl = await storageService.uploadImage(imageFile, userFolder);
      }

      // Use the provided name or generate a default one
      final paletteName =
          name?.isNotEmpty == true
              ? name
              : 'Palette ${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // Create palette model
      final palette = PaletteModel(
        id: '', // ID will be set by the FirestoreService based on the name
        userId: '',
        name: paletteName,
        imageUrl: imageUrl,
        colors: List.from(state),
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      final savedPalette = await firestoreService.savePalette(palette);

      // Add to user palettes
      final userPalettes = ref.read(userPalettesProvider);
      ref.read(userPalettesProvider.notifier).state = [
        savedPalette,
        ...userPalettes,
      ];

      return savedPalette;
    } catch (e) {
      logger.logError('Error saving palette', e);
      return null;
    } finally {
      ref.read(savingPaletteProvider.notifier).setLoading(false);
    }
  }
}
