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

  static String obtenerFechaHoy() {
    final now = DateTime.now();
    final dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final diaSemana = dias[now.weekday % 7];
    final mes = meses[now.month - 1];
    return '$diaSemana, ${now.day} de $mes de ${now.year}';
  }

  static String fechaAFormatoIso(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
