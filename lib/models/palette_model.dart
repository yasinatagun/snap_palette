import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model representing a color palette saved by a user
class PaletteModel {
  final String id;
  final String userId;
  final String? name;
  final String? imageUrl;
  final List<Color> colors;
  final DateTime createdAt;

  const PaletteModel({
    required this.id,
    required this.userId,
    this.name,
    this.imageUrl,
    required this.colors,
    required this.createdAt,
  });

  /// Create a copy with updated fields
  PaletteModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? imageUrl,
    List<Color>? colors,
    DateTime? createdAt,
  }) {
    return PaletteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      colors: colors ?? this.colors,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert color to hex string
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Convert hex string to color
  static Color _hexToColor(String hex) {
    final hexCode = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// Create a PaletteModel from a JSON map
  factory PaletteModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> colorsList = json['colors'] as List<dynamic>;
    final List<Color> colors =
        colorsList.map((colorStr) => _hexToColor(colorStr as String)).toList();

    return PaletteModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      colors: colors,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert PaletteModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'colors': colors.map(_colorToHex).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create an empty PaletteModel
  factory PaletteModel.empty() {
    return PaletteModel(
      id: '',
      userId: '',
      colors: const [],
      createdAt: DateTime.now(),
    );
  }
}
