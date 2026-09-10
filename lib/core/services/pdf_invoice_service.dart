import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/orden_model.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

/// Comprobante de recepción del equipo.
///
/// La hoja A4 lleva dos mitades A5 apaisadas separadas por una línea de corte:
/// arriba la copia que se lleva el cliente, abajo el cargo que se queda el
/// taller y que el cliente firma al recoger su equipo. Las dos mitades salen
/// de [_construirMitad], así que nunca muestran datos distintos.
class PdfInvoiceService {
  // ── Medidas y tamaños de letra ──
  static const double _margen = 18;
  static const double _fuenteEtiqueta = 7;
  static const double _fuenteValor = 8.6;
  static const double _fuenteTitulo = 8.6;

  /// Servicios que caben en la tabla de media hoja. El resto se resume.
  static const int _maxServiciosVisibles = 6;

  // Topes de texto. Están medidos sobre una maqueta a escala real: con estos
  // valores el cargo del taller, que es la mitad más cargada porque suma el
  // bloque de firma, todavía entra sin pisar nada.
  static const int _maxFalla = 150;
  static const int _maxObservaciones = 110;
  static const int _maxAccesorios = 110;
  static const int _maxValorCampo = 46;

  // ── Generación ──

  /// Hoja A4 con las dos mitades y la línea de corte.
  static Future<Uint8List> generateInvoiceBytes(OrdenModel orden) async {
    final documento = pw.Document();

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Column(
          children: [
            pw.Expanded(child: _construirMitad(orden, esCargoTaller: false)),
            _lineaDeCorte(),
            pw.Expanded(child: _construirMitad(orden, esCargoTaller: true)),
          ],
        ),
      ),
    );

    return documento.save();
  }

  /// Sólo la copia del cliente, en una A5 apaisada suelta.
  ///
  /// Es la que conviene mandar por WhatsApp: pesa menos y no incluye el cargo
  /// interno del taller.
  static Future<Uint8List> generarCopiaClienteBytes(OrdenModel orden) async {
    final documento = pw.Document();

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => _construirMitad(orden, esCargoTaller: false),
      ),
    );

    return documento.save();
  }

  // ── Compartir ──

  /// Abre la hoja de compartir con la A4 completa, lista para imprimir.
  static Future<void> imprimirOCompartir(OrdenModel orden) async {
    final bytes = await generateInvoiceBytes(orden);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'orden_${orden.numeroOrden ?? orden.id}.pdf',
    );
  }

  /// Abre la hoja de compartir con la copia del cliente en A5.
  ///
  /// WhatsApp no acepta archivos por enlace `wa.me`, así que el envío pasa por
  /// la hoja de compartir del sistema y ahí se elige el contacto.
  static Future<void> compartirCopiaCliente(OrdenModel orden) async {
    final bytes = await generarCopiaClienteBytes(orden);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'orden_${orden.numeroOrden ?? orden.id}_cliente.pdf',
    );
  }

  // ── Media hoja ──

  static pw.Widget _construirMitad(OrdenModel orden, {required bool esCargoTaller}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(_margen, _margen, _margen, 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _encabezado(orden, esCargoTaller: esCargoTaller),
          pw.SizedBox(height: 7),
          pw.Divider(thickness: 1.2, color: PdfColors.black, height: 2),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 52, child: _columnaIzquierda(orden)),
                pw.SizedBox(width: 12),
                pw.Expanded(flex: 48, child: _columnaDerecha(orden)),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          if (esCargoTaller) _bloqueConformidad() else _bloqueTerminos(),
        ],
      ),
    );
  }

  static pw.Widget _encabezado(OrdenModel orden, {required bool esCargoTaller}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 30,
              height: 30,
              decoration: const pw.BoxDecoration(color: PdfColors.black),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'T',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  AppConstants.empresaRazonSocial,
                  style: const pw.TextStyle(fontSize: 9.6, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${AppConstants.empresaSubtitulo}  ·  ${AppConstants.empresaTelefono}',
                  style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey700),
                ),
                pw.Text(
                  AppConstants.empresaEmail,
                  style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: pw.BoxDecoration(
                color: esCargoTaller ? PdfColors.grey200 : PdfColors.black,
              ),
              child: pw.Text(
                esCargoTaller ? 'CARGO - TALLER' : 'COPIA - CLIENTE',
                style: pw.TextStyle(
                  fontSize: 7,
                  letterSpacing: 1,
                  fontWeight: pw.FontWeight.bold,
                  color: esCargoTaller ? PdfColors.black : PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              orden.numeroOrdenDisplay,
              style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Recibido: ${DateFormatter.formatearFechaCorta(orden.createdAt)}',
              style: const pw.TextStyle(fontSize: 7.4, color: PdfColors.grey700),
            ),
            pw.Text(
              'Entrega: ${_textoFechaPrometida(orden)}',
              style: const pw.TextStyle(fontSize: 7.4, color: PdfColors.grey700),
            ),
            pw.Text(
              '${orden.estadoDisplay}  ·  Prioridad ${_textoPrioridad(orden.prioridad)}',
              style: const pw.TextStyle(fontSize: 7.4, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _columnaIzquierda(OrdenModel orden) {
    final cliente = orden.cliente;
    final equipo = orden.equipo;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('CLIENTE'),
        _campo('Nombre', cliente?.nombreCompleto),
        _campo('DNI', cliente?.dni),
        _campo('Celular', cliente?.telefono),
        if (_tieneTexto(cliente?.email)) _campo('Correo', cliente?.email),
        if (_tieneTexto(cliente?.direccion)) _campo('Dirección', cliente?.direccion),
        pw.SizedBox(height: 6),
        _tituloSeccion('EQUIPO'),
        _campo('Tipo', equipo?.tipoFormateado),
        _campo('Marca / Modelo', equipo?.nombreCompleto),
        _campo('N° de serie', equipo?.numeroSerie),
        _campo('PIN / Clave', orden.contrasenaEquipo),
        _campo('Técnico', orden.tecnico?.nombreCompleto),
        pw.SizedBox(height: 6),
        _recuadro('FALLA REPORTADA', _recortar(equipo?.desperfecto, _maxFalla)),
        if (_tieneTexto(equipo?.descripcionGeneral)) ...[
          pw.SizedBox(height: 4),
          _recuadro(
            'OBSERVACIONES DE RECEPCIÓN',
            _recortar(equipo?.descripcionGeneral, _maxObservaciones),
          ),
        ],
        pw.SizedBox(height: 4),
        _recuadro('ACCESORIOS ENTREGADOS', _recortar(equipo?.accesorios, _maxAccesorios)),
      ],
    );
  }

  static pw.Widget _columnaDerecha(OrdenModel orden) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('DETALLE DEL SERVICIO'),
        pw.SizedBox(height: 3),
        _tablaServicios(orden),
        pw.SizedBox(height: 7),
        _filaTotal('Subtotal', CurrencyFormatter.format(orden.subtotal)),
        _filaTotal('Descuento', '- ${CurrencyFormatter.format(orden.descuento)}'),
        _filaTotal('Pagado', '- ${CurrencyFormatter.format(orden.totalPagado)}'),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SALDO PENDIENTE',
                style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                CurrencyFormatter.format(orden.saldoPendiente),
                style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tablaServicios(OrdenModel orden) {
    final items = orden.itemsServicio;
    final visibles = items.take(_maxServiciosVisibles).toList();
    final restantes = items.length - visibles.length;

    if (items.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
        child: pw.Text(
          'Sin servicios cotizados. El presupuesto se entrega tras el diagnóstico.',
          style: const pw.TextStyle(fontSize: 8.2, color: PdfColors.grey700),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FixedColumnWidth(20),
            2: const pw.FixedColumnWidth(48),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.8)),
              ),
              children: [
                _celdaCabecera('DESCRIPCIÓN'),
                _celdaCabecera('CANT', alineacion: pw.TextAlign.center),
                _celdaCabecera('IMPORTE', alineacion: pw.TextAlign.right),
              ],
            ),
            ...visibles.map(
              (item) => pw.TableRow(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4)),
                ),
                children: [
                  _celdaCuerpo(_recortar(item.servicio?.nombre ?? 'Servicio técnico', 38)),
                  _celdaCuerpo('${item.cantidad}', alineacion: pw.TextAlign.center),
                  _celdaCuerpo(
                    CurrencyFormatter.format(item.subtotal),
                    alineacion: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (restantes > 0)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'y $restantes servicio(s) más, detallados en el sistema',
                style: const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey600),
              ),
            ),
          ),
      ],
    );
  }

  /// Pie de la copia del cliente.
  static pw.Widget _bloqueTerminos() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
      child: pw.Text(
        'CONSERVE ESTE COMPROBANTE PARA EL RETIRO DE SU EQUIPO. Los equipos no retirados en '
        '60 días desde la fecha prometida serán considerados en abandono. No nos responsabilizamos '
        'por la pérdida de información almacenada en el equipo. Garantía de 30 días sobre los '
        'trabajos realizados, contados desde la fecha de entrega.',
        style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  /// Pie del cargo del taller: conformidad y firma del cliente al recoger.
  static pw.Widget _bloqueConformidad() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(7, 5, 7, 5),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 10,
                height: 10,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.7),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Text(
                  'Recibí conforme mi equipo y todos los accesorios detallados arriba.',
                  style: const pw.TextStyle(fontSize: 7.6, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(flex: 4, child: _lineaFirma('Firma del cliente')),
              pw.SizedBox(width: 10),
              pw.Expanded(flex: 3, child: _lineaFirma('DNI')),
              pw.SizedBox(width: 10),
              pw.Expanded(flex: 3, child: _lineaFirma('Fecha de recojo')),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _lineaFirma(String etiqueta) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 0.7,
          width: double.infinity,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 2.5),
        pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey700)),
      ],
    );
  }

  /// Guía de tijera entre las dos mitades de la A4.
  static pw.Widget _lineaDeCorte() {
    return pw.Container(
      height: 12,
      width: double.infinity,
      alignment: pw.Alignment.center,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(child: _guiones()),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6),
            child: pw.Text(
              'CORTAR AQUÍ',
              style: const pw.TextStyle(
                fontSize: 5.6,
                color: PdfColors.grey600,
                letterSpacing: 1.4,
              ),
            ),
          ),
          pw.Expanded(child: _guiones()),
        ],
      ),
    );
  }

  static pw.Widget _guiones() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: List<pw.Widget>.generate(
        44,
        (_) => pw.Container(width: 4, height: 0.6, color: PdfColors.grey500),
      ),
    );
  }

  // ── Piezas menores ──

  static pw.Widget _tituloSeccion(String texto) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 3),
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.6)),
      ),
      child: pw.Text(
        texto,
        style: const pw.TextStyle(
          fontSize: _fuenteTitulo,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Fila compacta de etiqueta y valor, con la etiqueta en ancho fijo para que
  /// los valores queden alineados en columna.
  static pw.Widget _campo(String etiqueta, String? valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.9),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 62,
            child: pw.Text(
              etiqueta,
              style: const pw.TextStyle(fontSize: _fuenteEtiqueta, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _recortar(valor, _maxValorCampo),
              style: const pw.TextStyle(fontSize: _fuenteValor, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _recuadro(String titulo, String contenido) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(5, 3, 5, 4),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: const pw.TextStyle(
              fontSize: 6.6,
              color: PdfColors.grey700,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 1.5),
          pw.Text(contenido, style: const pw.TextStyle(fontSize: 8.2)),
        ],
      ),
    );
  }

  static pw.Widget _celdaCabecera(String texto, {pw.TextAlign alineacion = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        texto,
        textAlign: alineacion,
        style: const pw.TextStyle(
          fontSize: 6.8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _celdaCuerpo(String texto, {pw.TextAlign alineacion = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3.4),
      child: pw.Text(
        texto,
        textAlign: alineacion,
        style: const pw.TextStyle(fontSize: 8.2),
      ),
    );
  }

  static pw.Widget _filaTotal(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            etiqueta,
            style: const pw.TextStyle(fontSize: 7.8, color: PdfColors.grey700),
          ),
          pw.Text(
            valor,
            style: const pw.TextStyle(fontSize: 8.6, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Utilidades de texto ──

  static bool _tieneTexto(String? valor) => valor != null && valor.trim().isNotEmpty;

  /// Recorta a [maximo] caracteres para que ningún campo largo desborde la
  /// media hoja. Devuelve una raya cuando no hay dato.
  static String _recortar(String? texto, int maximo) {
    final limpio = (texto ?? '').trim();
    if (limpio.isEmpty) return '—';
    if (limpio.length <= maximo) return limpio;
    return '${limpio.substring(0, maximo - 3).trimRight()}...';
  }

  static String _textoFechaPrometida(OrdenModel orden) {
    if (!_tieneTexto(orden.fechaPrometida)) return 'Por definir';
    return DateFormatter.formatearFechaCorta(orden.fechaPrometida);
  }

  static String _textoPrioridad(String prioridad) {
    if (prioridad == 'alta') return 'Urgente';
    if (prioridad == 'baja') return 'Baja';
    return 'Normal';
  }
}
