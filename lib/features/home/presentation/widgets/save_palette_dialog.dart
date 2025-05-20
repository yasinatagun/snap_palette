import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logger.dart';
import '../../../../providers/index.dart';

/// Dialog for saving a color palette
class SavePaletteDialog extends ConsumerStatefulWidget {
  final File? selectedImage;

  const SavePaletteDialog({super.key, this.selectedImage});

  @override
  ConsumerState<SavePaletteDialog> createState() => _SavePaletteDialogState();
}

class _SavePaletteDialogState extends ConsumerState<SavePaletteDialog> {
  final _nameController = TextEditingController();
  bool _includeImage = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePalette() async {
    try {
      final name = _nameController.text.trim();
      // Only include image if option is selected
      final imageFile = _includeImage ? widget.selectedImage : null;

      // Call provider to save palette
      final savedPalette = await ref
          .read(colorPaletteProvider.notifier)
          .savePalette(
            name: name.isNotEmpty ? name : null,
            imageFile: imageFile,
          );

      if (context.mounted) {
        Navigator.of(context).pop();

        if (savedPalette != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Palette saved successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save palette')),
          );
        }
      }
    } catch (e) {
      logger.logError('Error saving palette', e);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save palette: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(savingPaletteProvider);
    final hasImage = widget.selectedImage != null;

    return AlertDialog(
      title: const Text('Save Palette'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Palette Name (Optional)',
              hintText: 'My Awesome Palette',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          if (hasImage) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Include image'),
              subtitle: const Text('Save the source image with your palette'),
              value: _includeImage,
              onChanged: (value) {
                setState(() {
                  _includeImage = value;
                });
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _savePalette,
          child:
              isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('SAVE'),
        ),
      ],
    );
  }
}
