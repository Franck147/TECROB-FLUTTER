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

  static Color obtenerColorTexto(String? estado) {
    if (estado == null) return AppColors.estadoDesconocidoTexto;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return AppColors.estadoPendienteTexto;
      case 'diagnostico':
        return AppColors.estadoDiagnosticoTexto;
      case 'en_progreso':
        return AppColors.estadoProgresoTexto;
      case 'listo':
        return AppColors.estadoListoTexto;
      case 'entregado':
        return AppColors.estadoEntregadoTexto;
      case 'cancelado':
      case 'sin_reparacion':
        return AppColors.estadoCanceladoTexto;
      default:
        return AppColors.estadoDesconocidoTexto;
    }
  }

  static Color obtenerColorFondo(String? estado) {
    if (estado == null) return AppColors.estadoDesconocidoFondo;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return AppColors.estadoPendienteFondo;
      case 'diagnostico':
        return AppColors.estadoDiagnosticoFondo;
      case 'en_progreso':
        return AppColors.estadoProgresoFondo;
      case 'listo':
        return AppColors.estadoListoFondo;
      case 'entregado':
        return AppColors.estadoEntregadoFondo;
      case 'cancelado':
      case 'sin_reparacion':
        return AppColors.estadoCanceladoFondo;
      default:
        return AppColors.estadoDesconocidoFondo;
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
