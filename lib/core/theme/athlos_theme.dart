import 'package:flutter/material.dart';

import 'athlos_color_scheme.dart';
import 'athlos_text_theme.dart';

/// Main ThemeData factory for Athlos.
class AthlosTheme {
  AthlosTheme._();

  static ThemeData get light => _buildTheme(AthlosColorScheme.light);
  static ThemeData get dark => _buildTheme(AthlosColorScheme.dark);

  static ThemeData _buildTheme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: AthlosTextTheme.textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
      );
}
