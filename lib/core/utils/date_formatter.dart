import 'package:intl/intl.dart';

class DateFormatter {
  static String formatearFechaCorta(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return '—';
    try {
      final dateTime = DateTime.parse(fechaIso).toLocal();
      return DateFormat('dd/MM/yyyy', 'es_PE').format(dateTime);
    } catch (_) {
      try {
        final parts = fechaIso.split('-');
        if (parts.length >= 3) {
          final year = parts[0];
          final month = parts[1];
          final day = parts[2].substring(0, 2);
          return '$day/$month/$year';
        }
      } catch (_) {}
      return fechaIso;
    }
  }

  static String formatearFechaHora(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return '—';
    try {
      final dateTime = DateTime.parse(fechaIso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm', 'es_PE').format(dateTime);
    } catch (_) {
      return formatearFechaCorta(fechaIso);
    }
  }

  static String formatearFechaHoraCorta(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return '—';
    try {
      final dateTime = DateTime.parse(fechaIso).toLocal();
      return DateFormat('dd/MM/yy HH:mm', 'es_PE').format(dateTime);
    } catch (_) {
      return formatearFechaCorta(fechaIso);
    }
  }

  static const List<String> _dias = [
    'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
  ];

  static const List<String> _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  static String obtenerFechaHoy() {
    return formatearFechaLarga(DateTime.now());
  }

  /// Fecha en castellano sin depender de los datos de idioma de `intl`.
  static String formatearFechaLarga(DateTime fecha) {
    final diaSemana = _dias[fecha.weekday % 7];
    final mes = _meses[fecha.month - 1];
    return '$diaSemana, ${fecha.day} de $mes de ${fecha.year}';
  }

  static String fechaAFormatoIso(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
