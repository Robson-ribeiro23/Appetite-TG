// lib/core/theme/apptheme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importe necessário para as fontes
import 'package:appetite/core/constants/appcolors.dart'; // Importe necessário para as cores

ThemeData buildAppTheme(Color primaryColor, double fontSizeFactor, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Definição das cores base
  final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
  final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final textColor = isDark ? Colors.white : Colors.black87;
  final subTextColor = isDark ? Colors.white70 : Colors.black54;

  // Base de texto (estilos padrão)
  final baseTextTheme = TextTheme(
    displayLarge: TextStyle(color: textColor, fontSize: 57),
    headlineSmall: TextStyle(color: textColor, fontSize: 24),
    titleLarge: TextStyle(color: textColor, fontSize: 22),
    titleMedium: TextStyle(color: textColor, fontSize: 16),
    bodyLarge: TextStyle(color: textColor, fontSize: 16),
    bodyMedium: TextStyle(color: subTextColor, fontSize: 14),
    bodySmall: TextStyle(color: subTextColor, fontSize: 12),
  );

  // Aplica a fonte Nunito (Google Fonts)
  final fontTheme = GoogleFonts.nunitoTextTheme(baseTextTheme);

  return ThemeData(
    primaryColor: primaryColor,
    brightness: brightness,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor,
    
    // Esquema de cores moderno (Material 3)
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: surfaceColor,
      primary: primaryColor,
      secondary: AppColors.accentColor,
      error: AppColors.errorColor,
    ),

    // Configuração da AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      // Aqui garantimos que o título use a fonte Nunito e seja negrito
      titleTextStyle: fontTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: textColor, // Garante legibilidade no modo claro/escuro
      ),
    ),

    // Configuração dos Inputs (TextFields)
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: primaryColor),
      hintStyle: TextStyle(color: subTextColor),
      filled: true,
      fillColor: surfaceColor, // Fundo sutil para inputs
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: subTextColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIconColor: subTextColor,
      suffixIconColor: subTextColor,
    ),

    // Aplica o fator de escala de fonte apenas no corpo do texto
    // (A AppBar e a BottomNav estão protegidas pelos MediaQueries nas suas respectivas views)
    textTheme: fontTheme.apply(fontSizeFactor: fontSizeFactor),
    
    useMaterial3: true,
  );
}