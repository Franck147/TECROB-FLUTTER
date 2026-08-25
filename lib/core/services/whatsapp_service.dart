import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static String formatearNumeroPeru(String telefono) {
    final limpio = telefono.replaceAll(RegExp(r'\D'), '');
    if (limpio.startsWith('51') && limpio.length >= 11) {
      return limpio;
    }
    return '51$limpio';
  }

  static Future<bool> abrirChat({
    required String telefono,
    String mensaje = '',
  }) async {
    final numero = formatearNumeroPeru(telefono);
    final encodedMessage = Uri.encodeComponent(mensaje);
    final urlString = mensaje.isNotEmpty
        ? 'https://wa.me/$numero?text=$encodedMessage'
        : 'https://wa.me/$numero';

    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> realizarLlamada(String telefono) async {
    final numero = formatearNumeroPeru(telefono);
    final uri = Uri.parse('tel:+$numero');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (_) {}
    return false;
  }

  static String generarMensajeOrdenLista({
    required String nombreCliente,
    required String equipo,
    required String numeroOrden,
  }) {
    return 'Hola $nombreCliente, le informamos de MULTISERVICIOS TECROB SYS que su equipo $equipo (Orden #$numeroOrden) ya se encuentra LISTO para su recojo. Puede pasar a retirarlo cuando guste.';
  }
}
