import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../core/logger.dart';

/// Service to extract color palettes from images
class PaletteService {
  /// Extract dominant colors from an image file
  /// Returns a list of up to [maxColorCount] dominant colors
  Future<List<Color>> extractColorsFromImage(
    File imageFile, {
    int maxColorCount = 5,
  }) async {
    try {
      // Create an ImageProvider from the file
      final imageProvider = FileImage(imageFile);

      // Generate palette from the image with a higher maximumColorCount to get more options
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount:
            50, // Request many colors to ensure we have enough options
        size: const Size(200, 200), // Use a smaller size for faster processing
      );

      // If there are no colors in the palette, return an empty list
      if (paletteGenerator.paletteColors.isEmpty) {
        return [];
      }

      // Extract dominant colors while ensuring diversity
      final List<Color> dominantColors = [];

      // First add the most dominant color
      dominantColors.add(paletteGenerator.paletteColors.first.color);

      // List of threshold values we'll try in order to get desired number of colors
      final List<double> thresholds = [40.0, 30.0, 20.0, 15.0, 10.0, 5.0, 0.0];

      // Try each threshold until we get maxColorCount colors or exhaust all thresholds
      for (final threshold in thresholds) {
        // Reset colors except the first dominant one
        dominantColors.clear();
        dominantColors.add(paletteGenerator.paletteColors.first.color);

        // Try to add colors using current threshold
        for (final swatch in paletteGenerator.paletteColors) {
          if (dominantColors.contains(swatch.color)) continue;

          // Check if this color is sufficiently different from all colors we've already selected
          bool isSufficientlyDifferent = true;
          for (final existingColor in dominantColors) {
            if (_calculateColorDistance(existingColor, swatch.color) <
                threshold) {
              isSufficientlyDifferent = false;
              break;
            }
          }

          // Add the color if it's different enough
          if (isSufficientlyDifferent) {
            dominantColors.add(swatch.color);
            if (dominantColors.length >= maxColorCount) break;
          }
        }

        // If we got enough colors, stop trying thresholds
        if (dominantColors.length >= maxColorCount ||
            dominantColors.length >= paletteGenerator.paletteColors.length) {
          break;
        }
      }

      // Ensure we always add the most representative colors if we don't have enough
      if (dominantColors.length < maxColorCount &&
          dominantColors.length < paletteGenerator.paletteColors.length) {
        // Add remaining colors from the palette without duplicate check
        for (final swatch in paletteGenerator.paletteColors) {
          if (!dominantColors.contains(swatch.color)) {
            dominantColors.add(swatch.color);
            if (dominantColors.length >= maxColorCount) break;
          }
        }
      }

      logger.logInfo(
        'Extracted ${dominantColors.length} diverse colors from image',
      );
      return dominantColors;
    } catch (e) {
      logger.logError('Error extracting colors from image', e);
      return [];
    }
  }

  /// Calculate Euclidean distance between two colors in RGB space
  /// Higher values mean more different colors
  double _calculateColorDistance(Color color1, Color color2) {
    final rmean = (color1.red + color2.red) / 2;
    final r = color1.red - color2.red;
    final g = color1.green - color2.green;
    final b = color1.blue - color2.blue;

    // Weighted Euclidean distance formula giving higher weight to red channel
    // Based on human perception research
    return sqrt(
      (2 + rmean / 256) * r * r + 4 * g * g + (2 + (255 - rmean) / 256) * b * b,
    );
  }

  /// Convert a color to hex string format (e.g., #FFFFFF)
  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
