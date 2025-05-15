import 'package:flutter/material.dart';
import '../colors/AppColors.dart';

class AppTypography {

  static const TextTheme textTheme = TextTheme(
    // Títulos grandes
    headlineLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: AppColors.primary, // Verde esmeralda
    ),
    // Títulos medianos
    headlineMedium: TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: AppColors.primary,
    ),
    // Subtítulos
    titleLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: AppColors.textDark,
    ),
    // Textos para botones
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Colors.white,
    ),
    // Texto del cuerpo principal
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      color: AppColors.textDark,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: AppColors.textDark,
    ),
  );
}