import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logger.dart';
import '../../../../providers/index.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/color_palette_display.dart';
import '../widgets/image_picker_container.dart';
import '../widgets/save_palette_dialog.dart';

/// Home screen of the application
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(userProvider.notifier).signOut();
      if (context.mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      logger.logError('Logout error', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _processImage(BuildContext context, WidgetRef ref) async {
    try {
      final selectedImage = ref.read(selectedImageProvider);
      if (selectedImage == null) return;

      // Set loading state
      ref.read(paletteLoadingProvider.notifier).setLoading(true);

      // Extract colors from the image
      await ref
          .read(colorPaletteProvider.notifier)
          .extractColors(selectedImage);

      // Clear loading state
      ref.read(paletteLoadingProvider.notifier).setLoading(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Color palette extracted successfully!'),
          ),
        );
      }
    } catch (e) {
      // Clear loading state
      ref.read(paletteLoadingProvider.notifier).setLoading(false);

      logger.logError('Error processing image', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: ${e.toString()}')),
        );
      }
    }
  }

  /// Show dialog to save the current palette
  Future<void> _showSavePaletteDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedImage = ref.read(selectedImageProvider);
    final colorPalette = ref.read(colorPaletteProvider);

    if (colorPalette.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No colors to save. Please extract colors first.'),
        ),
      );
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => SavePaletteDialog(selectedImage: selectedImage),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final selectedImage = ref.watch(selectedImageProvider);
    final isLoading = ref.watch(paletteLoadingProvider);
    final colorPalette = ref.watch(colorPaletteProvider);
    final isSaving = ref.watch(savingPaletteProvider);

    // If user is not logged in, redirect to login screen
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap Palette'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, ref),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Welcome, ${user.displayName ?? user.email}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select an image to extract its color palette',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Fancy image picker container
            const ImagePickerContainer(),

            // Show selected image status
            if (selectedImage != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Image Selected!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : () => _processImage(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    isLoading
                        ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Processing...'),
                          ],
                        )
                        : const Text('Extract Colors'),
              ),
            ],

            // Display color palette
            if (colorPalette.isNotEmpty) ...[
              const SizedBox(height: 30),
              const ColorPaletteDisplay(),
              const SizedBox(height: 20),

              // Save palette button
              ElevatedButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : () => _showSavePaletteDialog(context, ref),
                icon:
                    isSaving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save),
                label: Text(isSaving ? 'Saving...' : 'Save Palette'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
