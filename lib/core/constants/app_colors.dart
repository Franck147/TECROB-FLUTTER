import 'package:flutter/material.dart';

/// Paleta corporativa de TecrobSys.
///
/// El azul es el color de marca y de acción principal. El verde marca
/// entradas y confirmaciones, el rojo salidas y cancelaciones, y el ámbar
/// los avisos. Cada rol tiene una variante para tema claro y otra para
/// tema oscuro; usa los helpers `...Of(context)` del final del archivo
/// cuando el color deba adaptarse al tema activo.
class AppColors {
  // ── Marca Corporativa ──
  static const Color primario = Color(0xFF1B6DF3);
  static const Color primarioOscuro = Color(0xFF1552C4);
  static const Color primarioClaro = Color(0xFF5B9BFF);
  static const Color primarioContenedor = Color(0xFF12233F);
  static const Color primarioContenedorClaro = Color(0xFFE8F0FE);

  /// Azul legible sobre superficies oscuras (contraste insuficiente del
  /// primario sobre negro).
  static const Color primarioSobreOscuro = Color(0xFF4D8DFF);

  // ── Material 3 Roles (Tema Oscuro) ──
  static const Color primary = primarioSobreOscuro;
  static const Color onPrimary = Color(0xFF05224F);
  static const Color primaryContainer = primarioContenedor;
  static const Color onPrimaryContainer = Color(0xFFBBD4FF);

  static const Color secondaryOscuro = Color(0xFFFBBF24);
  static const Color onSecondary = Color(0xFF2A1E05);
  static const Color secondaryContainer = Color(0xFF2E2410);
  static const Color onSecondaryContainer = Color(0xFFFCD34D);

  static const Color tertiaryOscuro = Color(0xFF3DD68C);
  static const Color onTertiary = Color(0xFF06251A);
  static const Color tertiaryContainer = Color(0xFF10281F);
  static const Color onTertiaryContainer = Color(0xFF9DF0C4);

  static const Color errorOscuro = Color(0xFFFF6B6B);
  static const Color onError = Color(0xFF3A0A0A);
  static const Color errorContainer = Color(0xFF3A1414);
  static const Color onErrorContainer = Color(0xFFFFB4AB);

  // ── Tonos Universales ──
  // Legibles tanto sobre blanco como sobre el fondo oscuro. Son los que debe
  // usar el código de las pantallas cuando no tiene un `BuildContext` a mano
  // para decidir según el tema.
  static const Color aviso = Color(0xFFD97706);
  static const Color exito = Color(0xFF16A34A);
  static const Color peligro = Color(0xFFE5484D);

  static const Color secondary = aviso;
  static const Color tertiary = exito;
  static const Color error = peligro;

  // ── Material 3 Roles (Tema Claro) ──
  static const Color primaryClaro = primario;
  static const Color onPrimaryClaro = Colors.white;
  static const Color primaryContainerClaro = primarioContenedorClaro;
  static const Color onPrimaryContainerClaro = Color(0xFF0B3C91);

  static const Color secondaryClaro = Color(0xFFF59E0B);
  static const Color onSecondaryClaro = Colors.white;
  static const Color secondaryContainerClaro = Color(0xFFFEF3C7);
  static const Color onSecondaryContainerClaro = Color(0xFF92400E);

  static const Color tertiaryClaro = Color(0xFF16A34A);
  static const Color onTertiaryClaro = Colors.white;
  static const Color tertiaryContainerClaro = Color(0xFFDCFCE7);
  static const Color onTertiaryContainerClaro = Color(0xFF14532D);

  static const Color errorClaro = Color(0xFFDC2626);
  static const Color onErrorClaro = Colors.white;
  static const Color errorContainerClaro = Color(0xFFFEE2E2);
  static const Color onErrorContainerClaro = Color(0xFF991B1B);

  // ── Paleta Modo Oscuro (Dark) ──
  static const Color darkFondoPrincipal = Color(0xFF0E1117);
  static const Color darkFondoTarjeta = Color(0xFF151A22);
  static const Color darkFondoSuperficie = Color(0xFF1B212B);
  static const Color darkFondoBorde = Color(0xFF262E3A);
  static const Color darkTextoPrincipal = Color(0xFFE6E9EF);
  static const Color darkTextoSecundario = Color(0xFF94A0B4);
  static const Color darkTextoMuted = Color(0xFF64708A);

  // ── Paleta Modo Claro (Light) ──
  static const Color lightFondoPrincipal = Color(0xFFF6F7F9);
  static const Color lightFondoTarjeta = Color(0xFFFFFFFF);
  static const Color lightFondoSuperficie = Color(0xFFF1F3F7);
  static const Color lightFondoBorde = Color(0xFFE4E7EC);
  static const Color lightTextoPrincipal = Color(0xFF101828);
  static const Color lightTextoSecundario = Color(0xFF667085);
  static const Color lightTextoMuted = Color(0xFF98A2B3);

  // ── Compatibilidad por Defecto (tema oscuro) ──
  static const Color fondoPrincipal = darkFondoPrincipal;
  static const Color onBackground = darkTextoPrincipal;
  static const Color fondoTarjeta = darkFondoTarjeta;
  static const Color onSurface = darkTextoPrincipal;
  static const Color fondoSuperficie = darkFondoSuperficie;
  static const Color onSurfaceVariant = darkTextoSecundario;
  static const Color fondoBorde = darkFondoBorde;
  static const Color outlineVariant = Color(0xFF1E2530);
  static const Color outlineVariantClaro = Color(0xFFEDEFF3);

  static const Color textoPrincipal = darkTextoPrincipal;
  static const Color textoSecundario = darkTextoSecundario;
  static const Color textoMuted = darkTextoMuted;

  // ── Estados de Órdenes (Modo Oscuro) ──
  static const Color estadoPendienteFondo = Color(0xFF2E2410);
  static const Color estadoPendienteTexto = Color(0xFFFBBF24);

  static const Color estadoDiagnosticoFondo = Color(0xFF241E3A);
  static const Color estadoDiagnosticoTexto = Color(0xFFA78BFA);

  static const Color estadoProgresoFondo = primarioContenedor;
  static const Color estadoProgresoTexto = primarioSobreOscuro;

  static const Color estadoListoFondo = Color(0xFF10281F);
  static const Color estadoListoTexto = Color(0xFF3DD68C);

  static const Color estadoEntregadoFondo = Color(0xFF1E2530);
  static const Color estadoEntregadoTexto = Color(0xFF94A0B4);

  static const Color estadoCanceladoFondo = Color(0xFF3A1414);
  static const Color estadoCanceladoTexto = Color(0xFFFF6B6B);

  static const Color estadoDesconocidoFondo = Color(0xFF1E2530);
  static const Color estadoDesconocidoTexto = Color(0xFF64708A);

  // ── Estados de Órdenes (Modo Claro) ──
  static const Color estadoPendienteFondoClaro = Color(0xFFFEF3C7);
  static const Color estadoPendienteTextoClaro = Color(0xFFB45309);

  static const Color estadoDiagnosticoFondoClaro = Color(0xFFEDE9FE);
  static const Color estadoDiagnosticoTextoClaro = Color(0xFF6D28D9);

  static const Color estadoProgresoFondoClaro = primarioContenedorClaro;
  static const Color estadoProgresoTextoClaro = Color(0xFF0B3C91);

  static const Color estadoListoFondoClaro = Color(0xFFDCFCE7);
  static const Color estadoListoTextoClaro = Color(0xFF15803D);

  static const Color estadoEntregadoFondoClaro = Color(0xFFF1F3F7);
  static const Color estadoEntregadoTextoClaro = Color(0xFF475467);

  static const Color estadoCanceladoFondoClaro = Color(0xFFFEE2E2);
  static const Color estadoCanceladoTextoClaro = Color(0xFF991B1B);

  // ── Especiales ──
  static const Color verdeWhatsapp = Color(0xFF25D366);
  static const Color verdeWhatsappFondo = Color(0xFF10281F);
  static const Color verdeWhatsappFondoClaro = Color(0xFFE7F9EE);

  // ── Helpers Dinámicos por Contexto ──
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color fondoPrincipalOf(BuildContext context) {
    return isDark(context) ? darkFondoPrincipal : lightFondoPrincipal;
  }

  static Color fondoTarjetaOf(BuildContext context) {
    return isDark(context) ? darkFondoTarjeta : lightFondoTarjeta;
  }

  static Color fondoSuperficieOf(BuildContext context) {
    return isDark(context) ? darkFondoSuperficie : lightFondoSuperficie;
  }

  static Color fondoBordeOf(BuildContext context) {
    return isDark(context) ? darkFondoBorde : lightFondoBorde;
  }

  static Color textoPrincipalOf(BuildContext context) {
    return isDark(context) ? darkTextoPrincipal : lightTextoPrincipal;
  }

  static Color textoSecundarioOf(BuildContext context) {
    return isDark(context) ? darkTextoSecundario : lightTextoSecundario;
  }

  static Color textoMutedOf(BuildContext context) {
    return isDark(context) ? darkTextoMuted : lightTextoMuted;
  }

  /// Azul de marca legible sobre el fondo del tema activo.
  static Color primarioOf(BuildContext context) {
    return isDark(context) ? primarioSobreOscuro : primario;
  }

  static Color primarioContenedorOf(BuildContext context) {
    return isDark(context) ? primarioContenedor : primarioContenedorClaro;
  }

  static Color errorOf(BuildContext context) {
    return isDark(context) ? errorOscuro : errorClaro;
  }

  static Color exitoOf(BuildContext context) {
    return isDark(context) ? tertiaryOscuro : tertiaryClaro;
  }

  static Color avisoOf(BuildContext context) {
    return isDark(context) ? secondaryOscuro : secondaryClaro;
  }

  static Color verdeWhatsappFondoOf(BuildContext context) {
    return isDark(context) ? verdeWhatsappFondo : verdeWhatsappFondoClaro;
  }
}
