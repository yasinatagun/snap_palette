import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../core/logger.dart';
import '../../../../models/palette_model.dart';
import '../../../../providers/index.dart';

/// Screen to display user's saved palettes
class PalettesScreen extends ConsumerStatefulWidget {
  const PalettesScreen({super.key});

  @override
  ConsumerState<PalettesScreen> createState() => _PalettesScreenState();
}

class _PalettesScreenState extends ConsumerState<PalettesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadPalettes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPalettes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await ref.read(userPalettesProvider.notifier).fetchUserPalettes();
      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {
      logger.logError('Error loading palettes', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load palettes: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePalette(String paletteId) async {
    try {
      await ref.read(userPalettesProvider.notifier).deletePalette(paletteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Palette deleted successfully'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      logger.logError('Error deleting palette', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete palette: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palettes = ref.watch(userPalettesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('My Palettes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPalettes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your palettes...',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
              : palettes.isEmpty
              ? _buildEmptyState(theme)
              : _buildPalettesList(palettes, theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.color_lens_outlined,
            size: 100,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No palettes saved yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Extract colors from images and save them here to build your collection',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Create New Palette'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalettesList(List<PaletteModel> palettes, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadPalettes,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childCount: palettes.length,
              itemBuilder: (context, index) {
                final palette = palettes[index];

                // Create a staggered animation
                final animation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (1 / palettes.length) * index,
                    1.0,
                    curve: Curves.easeOut,
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: _buildPaletteCard(palette, theme),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteCard(PaletteModel palette, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: () {
          _showDeleteDialog(palette);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (palette.imageUrl != null) ...[
              Stack(
                children: [
                  Image.network(
                    palette.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => SizedBox(
                          height: 140,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Palette name on image
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Text(
                      palette.name ?? 'Unnamed Palette',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  palette.name ?? 'Unnamed Palette',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],

            // Color strip
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0),
                gradient: LinearGradient(colors: palette.colors),
              ),
            ),

            // Color circles
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    palette.colors.map((color) {
                      final brightness = ThemeData.estimateBrightnessForColor(
                        color,
                      );
                      final textColor =
                          brightness == Brightness.light
                              ? Colors.black
                              : Colors.white;

                      return Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.colorize,
                            size: 16,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(PaletteModel palette) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Palette'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to delete this palette?'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            palette.colors.isNotEmpty
                                ? palette.colors.first
                                : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      palette.name ?? 'Unnamed Palette',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deletePalette(palette.id);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );
  }
}
