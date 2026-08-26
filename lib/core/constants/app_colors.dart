import 'package:flutter/material.dart';

class AppColors {
  // ── Marca Corporativa ──
  static const Color rojoPrimario = Color(0xFFE85D5D);
  static const Color rojoOscuro = Color(0xFFC43C3C);
  static const Color rojoClaro = Color(0xFFFF8A8A);
  static const Color rojoContenedor = Color(0xFF2A1414);
  static const Color rojoContenedorClaro = Color(0xFFFDECEC);

  // ── Material 3 Roles ──
  static const Color primary = rojoPrimario;
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = rojoContenedor;
  static const Color onPrimaryContainer = Color(0xFFFFB3B3);

  static const Color secondary = Color(0xFFEF9F27);
  static const Color onSecondary = Color(0xFF1A1000);
  static const Color secondaryContainer = Color(0xFF2A1E10);
  static const Color onSecondaryContainer = Color(0xFFFFCC80);

  static const Color tertiary = Color(0xFF3ECF8E);
  static const Color onTertiary = Color(0xFF001A0E);
  static const Color tertiaryContainer = Color(0xFF1A2A1A);
  static const Color onTertiaryContainer = Color(0xFFA0F0C8);

  static const Color error = Color(0xFFFF5449);
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFF3A0A08);
  static const Color onErrorContainer = Color(0xFFFFB4AB);

  // ── Paleta Modo Oscuro (Dark) ──
  static const Color darkFondoPrincipal = Color(0xFF0D0D0F);
  static const Color darkFondoTarjeta = Color(0xFF141416);
  static const Color darkFondoSuperficie = Color(0xFF1A1A1E);
  static const Color darkFondoBorde = Color(0xFF252529);
  static const Color darkTextoPrincipal = Color(0xFFE8E6E1);
  static const Color darkTextoSecundario = Color(0xFF888888);
  static const Color darkTextoMuted = Color(0xFF555555);

  // ── Paleta Modo Claro (Light) ──
  static const Color lightFondoPrincipal = Color(0xFFF5F6FA);
  static const Color lightFondoTarjeta = Color(0xFFFFFFFF);
  static const Color lightFondoSuperficie = Color(0xFFEDF0F6);
  static const Color lightFondoBorde = Color(0xFFE1E5EE);
  static const Color lightTextoPrincipal = Color(0xFF15161A);
  static const Color lightTextoSecundario = Color(0xFF656B79);
  static const Color lightTextoMuted = Color(0xFF9096A4);

  // ── Compatibilidad por Defecto ──
  static const Color fondoPrincipal = darkFondoPrincipal;
  static const Color onBackground = darkTextoPrincipal;
  static const Color fondoTarjeta = darkFondoTarjeta;
  static const Color onSurface = darkTextoPrincipal;
  static const Color fondoSuperficie = darkFondoSuperficie;
  static const Color onSurfaceVariant = darkTextoSecundario;
  static const Color fondoBorde = darkFondoBorde;
  static const Color outlineVariant = Color(0xFF1E1E22);

  static const Color textoPrincipal = darkTextoPrincipal;
  static const Color textoSecundario = darkTextoSecundario;
  static const Color textoMuted = darkTextoMuted;

  // ── Estados de Órdenes (Modo Oscuro) ──
  static const Color estadoPendienteFondo = Color(0xFF2A1414);
  static const Color estadoPendienteTexto = Color(0xFFE85D5D);

  static const Color estadoDiagnosticoFondo = Color(0xFF2A1E10);
  static const Color estadoDiagnosticoTexto = Color(0xFFEF9F27);

  static const Color estadoProgresoFondo = Color(0xFF1A2A1A);
  static const Color estadoProgresoTexto = Color(0xFF3ECF8E);

  static const Color estadoListoFondo = Color(0xFF1A1A2A);
  static const Color estadoListoTexto = Color(0xFF6B8CFF);

  static const Color estadoEntregadoFondo = Color(0xFF1E1E22);
  static const Color estadoEntregadoTexto = Color(0xFF888888);

  static const Color estadoCanceladoFondo = Color(0xFF2A1010);
  static const Color estadoCanceladoTexto = Color(0xFFCC6666);

  static const Color estadoDesconocidoFondo = Color(0xFF1E1E22);
  static const Color estadoDesconocidoTexto = Color(0xFF666666);

  // ── Estados de Órdenes (Modo Claro) ──
  static const Color estadoPendienteFondoClaro = Color(0xFFFDE8E8);
  static const Color estadoPendienteTextoClaro = Color(0xFFD32F2F);

  static const Color estadoDiagnosticoFondoClaro = Color(0xFFFEF3C7);
  static const Color estadoDiagnosticoTextoClaro = Color(0xFFB45309);

  static const Color estadoProgresoFondoClaro = Color(0xFFDCFCE7);
  static const Color estadoProgresoTextoClaro = Color(0xFF15803D);

  static const Color estadoListoFondoClaro = Color(0xFFDBEAFE);
  static const Color estadoListoTextoClaro = Color(0xFF1D4ED8);

  static const Color estadoEntregadoFondoClaro = Color(0xFFF3F4F6);
  static const Color estadoEntregadoTextoClaro = Color(0xFF4B5563);

  static const Color estadoCanceladoFondoClaro = Color(0xFFFEE2E2);
  static const Color estadoCanceladoTextoClaro = Color(0xFF991B1B);

  // ── Especiales ──
  static const Color verdeWhatsapp = Color(0xFF25D366);
  static const Color verdeWhatsappFondo = Color(0xFF1A2A1E);
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

  static Color rojoContenedorOf(BuildContext context) {
    return isDark(context) ? rojoContenedor : rojoContenedorClaro;
  }

  static Color verdeWhatsappFondoOf(BuildContext context) {
    return isDark(context) ? verdeWhatsappFondo : verdeWhatsappFondoClaro;
  }
}
