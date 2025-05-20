import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/index.dart';

/// Widget to display a color palette with hex values
class ColorPaletteDisplay extends ConsumerWidget {
  const ColorPaletteDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorPaletteProvider);
    final paletteNotifier = ref.read(colorPaletteProvider.notifier);
    final theme = Theme.of(context);

    if (colors.isEmpty) {
      return Container(); // Return empty container if no colors
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Extracted Palette',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color stripe preview
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),

                // Color squares
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    return _buildColorItem(
                      context,
                      colors[index],
                      paletteNotifier,
                      theme,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorItem(
    BuildContext context,
    Color color,
    ColorPaletteNotifier notifier,
    ThemeData theme,
  ) {
    final hexValue = notifier.getHexValue(color);
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final textColor =
        brightness == Brightness.light ? Colors.black : Colors.white;

    return InkWell(
      onTap: () {
        // Copy color hex value to clipboard
        Clipboard.setData(ClipboardData(text: hexValue));

        // Show a more stylish snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.copy, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Copied $hexValue to clipboard'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Color box with animated ripple effect
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shade hint icon
                    Icon(
                      Icons.colorize,
                      color: textColor.withOpacity(0.5),
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Hex value
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hexValue,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Tap to copy hint
              Text(
                'Tap to copy',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
