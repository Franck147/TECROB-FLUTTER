import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: AppColors.textoPrincipal,
      displayColor: AppColors.textoPrincipal,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.fondoPrincipal,
      primaryColor: AppColors.rojoPrimario,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.fondoTarjeta,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.fondoSuperficie,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.fondoBorde,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondoPrincipal,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textoPrincipal),
        titleTextStyle: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.fondoTarjeta,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.fondoBorde, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fondoSuperficie,
        hintStyle: const TextStyle(color: AppColors.textoMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textoSecundario, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.fondoBorde, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.fondoBorde, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rojoPrimario, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rojoPrimario,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textoPrincipal,
          side: const BorderSide(color: AppColors.fondoBorde, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.fondoSuperficie,
        selectedColor: AppColors.rojoContenedor,
        labelStyle: const TextStyle(color: AppColors.textoSecundario, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: AppColors.rojoClaro, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.fondoBorde, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.fondoTarjeta,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.fondoBorde, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.fondoTarjeta,
        selectedItemColor: AppColors.rojoPrimario,
        unselectedItemColor: AppColors.textoSecundario,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.fondoBorde,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
