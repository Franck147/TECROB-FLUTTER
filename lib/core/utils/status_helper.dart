import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusHelper {
  static const List<String> todosLosEstados = [
    'pendiente',
    'diagnostico',
    'en_progreso',
    'listo',
    'entregado',
    'cancelado',
  ];

  static const List<String> etiquetasEstados = [
    'Pendiente',
    'Diagnóstico',
    'En progreso',
    'Listo',
    'Entregado',
    'Cancelado',
  ];

  static String obtenerTexto(String? estado) {
    if (estado == null) return 'Desconocido';
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'diagnostico':
        return 'Diagnóstico';
      case 'en_progreso':
        return 'En progreso';
      case 'listo':
        return 'Listo';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      case 'sin_reparacion':
        return 'Sin reparación';
      default:
        return estado;
    }
  }

  static Color obtenerColorTexto(String? estado, {bool isDark = true}) {
    if (estado == null) return isDark ? AppColors.estadoDesconocidoTexto : AppColors.lightTextoMuted;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return isDark ? AppColors.estadoPendienteTexto : AppColors.estadoPendienteTextoClaro;
      case 'diagnostico':
        return isDark ? AppColors.estadoDiagnosticoTexto : AppColors.estadoDiagnosticoTextoClaro;
      case 'en_progreso':
        return isDark ? AppColors.estadoProgresoTexto : AppColors.estadoProgresoTextoClaro;
      case 'listo':
        return isDark ? AppColors.estadoListoTexto : AppColors.estadoListoTextoClaro;
      case 'entregado':
        return isDark ? AppColors.estadoEntregadoTexto : AppColors.estadoEntregadoTextoClaro;
      case 'cancelado':
      case 'sin_reparacion':
        return isDark ? AppColors.estadoCanceladoTexto : AppColors.estadoCanceladoTextoClaro;
      default:
        return isDark ? AppColors.estadoDesconocidoTexto : AppColors.lightTextoMuted;
    }
  }

  static Color obtenerColorFondo(String? estado, {bool isDark = true}) {
    if (estado == null) return isDark ? AppColors.estadoDesconocidoFondo : AppColors.lightFondoSuperficie;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return isDark ? AppColors.estadoPendienteFondo : AppColors.estadoPendienteFondoClaro;
      case 'diagnostico':
        return isDark ? AppColors.estadoDiagnosticoFondo : AppColors.estadoDiagnosticoFondoClaro;
      case 'en_progreso':
        return isDark ? AppColors.estadoProgresoFondo : AppColors.estadoProgresoFondoClaro;
      case 'listo':
        return isDark ? AppColors.estadoListoFondo : AppColors.estadoListoFondoClaro;
      case 'entregado':
        return isDark ? AppColors.estadoEntregadoFondo : AppColors.estadoEntregadoFondoClaro;
      case 'cancelado':
      case 'sin_reparacion':
        return isDark ? AppColors.estadoCanceladoFondo : AppColors.estadoCanceladoFondoClaro;
      default:
        return isDark ? AppColors.estadoDesconocidoFondo : AppColors.lightFondoSuperficie;
    }
  }

  static IconData obtenerIconoEstado(String? estado) {
    if (estado == null) return Icons.help_outline_rounded;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.hourglass_top_rounded;
      case 'diagnostico':
        return Icons.search_rounded;
      case 'en_progreso':
        return Icons.build_circle_rounded;
      case 'listo':
        return Icons.check_circle_rounded;
      case 'entregado':
        return Icons.task_alt_rounded;
      case 'cancelado':
      case 'sin_reparacion':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static String obtenerTipoEquipoTexto(String? tipo) {
    if (tipo == null) return 'Equipo';
    switch (tipo.toLowerCase()) {
      case 'laptop':
        return 'Laptop';
      case 'computadora':
      case 'pc':
        return 'Computadora';
      case 'impresora':
        return 'Impresora';
      case 'tablet':
        return 'Tablet';
      case 'celular':
        return 'Celular';
      case 'otro':
      default:
        return 'Otro';
    }
  }

  static IconData obtenerIconoEquipo(String? tipo) {
    if (tipo == null) return Icons.devices_other_rounded;
    switch (tipo.toLowerCase()) {
      case 'laptop':
        return Icons.laptop_chromebook_rounded;
      case 'computadora':
      case 'pc':
        return Icons.desktop_windows_rounded;
      case 'impresora':
        return Icons.print_rounded;
      case 'tablet':
        return Icons.tablet_mac_rounded;
      case 'celular':
        return Icons.smartphone_rounded;
      default:
        return Icons.devices_rounded;
    }
  }
}
