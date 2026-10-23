import 'package:flutter/material.dart';

/// Palette taken from the reference design: blue, orange, purple, teal on a
/// very light blue background.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF2A9DF0);
  static const sky = Color(0xFF4DB4F2);
  static const sun = Color(0xFFFFA928);
  static const violet = Color(0xFF7B82D8);
  static const mint = Color(0xFF3CCBB8);

  static const ink = Color(0xFF1F2A44); // main text
  static const muted = Color(0xFF6B7A90); // secondary text

  static const background = Color(0xFFF3F9FF);
  static const bgTop = Color(0xFFDDF0FF);
  static const bgBottom = Color(0xFFF8FCFF);

  /// Card colors, handed out by course id so the list looks varied.
  static const List<Color> accents = [sky, violet, mint, sun];

  static Color accentFor(int id) => accents[id % accents.length];
}
