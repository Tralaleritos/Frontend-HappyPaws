import 'package:flutter/material.dart';


class AppColors {
  // Colores principales
  static const Color primary = Color(0xFF2AB088);     // Verde esmeralda
  static const Color secondary = Color(0xFFFF7A50);   // Naranja
  static const Color tertiary = Color(0xFFFFD0E5);    // Rosa suave

  // Colores de texto
  static const Color textDark = Color(0xFF333333);    // Texto oscuro
  static const Color textLight = Colors.white;        // Texto claro

  // Colores de fondo
  static const Color background = Colors.white;
  static const Color surface = Colors.white;

  // Esquema de colores completo
  static final ColorScheme colorScheme = ColorScheme.light(
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
    background: background,
    surface: surface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: textDark,
    onSurface: textDark,
  );
}