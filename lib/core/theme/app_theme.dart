import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  /// Radio de esquina compartido por tarjetas, campos y botones.
  static const double radioTarjeta = 14;
  static const double radioCampo = 10;

  // ── MODO OSCURO (DARK THEME) ──
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: AppColors.darkTextoPrincipal,
      displayColor: AppColors.darkTextoPrincipal,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkFondoPrincipal,
      primaryColor: AppColors.primarioSobreOscuro,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondaryOscuro,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiaryOscuro,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.errorOscuro,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.darkFondoTarjeta,
        onSurface: AppColors.darkTextoPrincipal,
        surfaceContainerHighest: AppColors.darkFondoSuperficie,
        onSurfaceVariant: AppColors.darkTextoSecundario,
        outline: AppColors.darkFondoBorde,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkFondoPrincipal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextoPrincipal),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextoPrincipal,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkFondoTarjeta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta),
          side: const BorderSide(color: AppColors.darkFondoBorde, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      inputDecorationTheme: _inputTheme(
        relleno: AppColors.darkFondoSuperficie,
        borde: AppColors.darkFondoBorde,
        foco: AppColors.primarioSobreOscuro,
        error: AppColors.errorOscuro,
        hint: AppColors.darkTextoMuted,
        label: AppColors.darkTextoSecundario,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarioSobreOscuro,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.darkFondoSuperficie,
          disabledForegroundColor: AppColors.darkTextoMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioCampo)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextoPrincipal,
          side: const BorderSide(color: AppColors.darkFondoBorde, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioCampo)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primarioSobreOscuro,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkFondoSuperficie,
        selectedColor: AppColors.primarioContenedor,
        checkmarkColor: AppColors.primarioSobreOscuro,
        labelStyle: const TextStyle(color: AppColors.darkTextoSecundario, fontSize: 13),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primarioSobreOscuro,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        side: const BorderSide(color: AppColors.darkFondoBorde, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkFondoTarjeta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.darkFondoBorde, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkFondoTarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkFondoTarjeta,
        selectedItemColor: AppColors.primarioSobreOscuro,
        unselectedItemColor: AppColors.darkTextoSecundario,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primarioSobreOscuro,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkFondoBorde,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ── MODO CLARO (LIGHT THEME) ──
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: AppColors.lightTextoPrincipal,
      displayColor: AppColors.lightTextoPrincipal,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightFondoPrincipal,
      primaryColor: AppColors.primario,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primaryClaro,
        onPrimary: AppColors.onPrimaryClaro,
        primaryContainer: AppColors.primaryContainerClaro,
        onPrimaryContainer: AppColors.onPrimaryContainerClaro,
        secondary: AppColors.secondaryClaro,
        onSecondary: AppColors.onSecondaryClaro,
        secondaryContainer: AppColors.secondaryContainerClaro,
        onSecondaryContainer: AppColors.onSecondaryContainerClaro,
        tertiary: AppColors.tertiaryClaro,
        onTertiary: AppColors.onTertiaryClaro,
        tertiaryContainer: AppColors.tertiaryContainerClaro,
        onTertiaryContainer: AppColors.onTertiaryContainerClaro,
        error: AppColors.errorClaro,
        onError: AppColors.onErrorClaro,
        errorContainer: AppColors.errorContainerClaro,
        onErrorContainer: AppColors.onErrorContainerClaro,
        surface: AppColors.lightFondoTarjeta,
        onSurface: AppColors.lightTextoPrincipal,
        surfaceContainerHighest: AppColors.lightFondoSuperficie,
        onSurfaceVariant: AppColors.lightTextoSecundario,
        outline: AppColors.lightFondoBorde,
        outlineVariant: AppColors.outlineVariantClaro,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightFondoTarjeta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextoPrincipal),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextoPrincipal,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightFondoTarjeta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta),
          side: const BorderSide(color: AppColors.lightFondoBorde, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      inputDecorationTheme: _inputTheme(
        relleno: AppColors.lightFondoSuperficie,
        borde: AppColors.lightFondoBorde,
        foco: AppColors.primario,
        error: AppColors.errorClaro,
        hint: AppColors.lightTextoMuted,
        label: AppColors.lightTextoSecundario,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lightFondoSuperficie,
          disabledForegroundColor: AppColors.lightTextoMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioCampo)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextoPrincipal,
          side: const BorderSide(color: AppColors.lightFondoBorde, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioCampo)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primario,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightFondoSuperficie,
        selectedColor: AppColors.primarioContenedorClaro,
        checkmarkColor: AppColors.primario,
        labelStyle: const TextStyle(color: AppColors.lightTextoSecundario, fontSize: 13),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.onPrimaryContainerClaro,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        side: const BorderSide(color: AppColors.lightFondoBorde, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightFondoTarjeta,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.lightFondoBorde, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightFondoTarjeta,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightFondoTarjeta,
        selectedItemColor: AppColors.primario,
        unselectedItemColor: AppColors.lightTextoSecundario,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primario,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightFondoBorde,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Decoración de campos compartida por ambos temas.
  static InputDecorationTheme _inputTheme({
    required Color relleno,
    required Color borde,
    required Color foco,
    required Color error,
    required Color hint,
    required Color label,
  }) {
    OutlineInputBorder linea(Color color, double ancho) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radioCampo),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: relleno,
      hintStyle: TextStyle(color: hint, fontSize: 14),
      labelStyle: TextStyle(color: label, fontSize: 14),
      floatingLabelStyle: TextStyle(color: foco, fontSize: 14, fontWeight: FontWeight.w600),
      border: linea(borde, 1),
      enabledBorder: linea(borde, 1),
      focusedBorder: linea(foco, 1.6),
      errorBorder: linea(error, 1),
      focusedErrorBorder: linea(error, 1.6),
      errorStyle: TextStyle(color: error, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
