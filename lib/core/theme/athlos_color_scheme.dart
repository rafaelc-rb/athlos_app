import 'package:flutter/material.dart';

/// Greek mythology-inspired color palette.
/// Golds, marble tones, and dark shades.
class AthlosColorScheme {
  AthlosColorScheme._();

  static const _primaryGold = Color(0xFFD4A843);
  static const _darkBase = Color(0xFF1A1A2E);
  static const _marble = Color(0xFFF5F0E8);
  static const _accent = Color(0xFF8B6914);

  static final light = ColorScheme.fromSeed(
    seedColor: _primaryGold,
    brightness: Brightness.light,
    primary: _primaryGold,
    onPrimary: Colors.white,
    secondary: _accent,
    surface: _marble,
  );

  static final dark = ColorScheme.fromSeed(
    seedColor: _primaryGold,
    brightness: Brightness.dark,
    primary: _primaryGold,
    onPrimary: Colors.black,
    secondary: _accent,
    surface: _darkBase,
  );
}
