import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/orden_model.dart';
import '../utils/date_formatter.dart';

class StickerItem {
  final String titulo;
  final String subtitulo;
  final String ordenCodigo;
  final String clienteNombre;
  final String? clienteTelefono;
  final String fecha;
  final bool esPrincipal;

  StickerItem({
    required this.titulo,
    required this.subtitulo,
    required this.ordenCodigo,
    required this.clienteNombre,
    this.clienteTelefono,
    required this.fecha,
    this.esPrincipal = false,
  });
}

class StickerLabelService {
  /// Desglosa una orden en ítems individuales para stickers (Equipo + Accesorios)
  static List<StickerItem> generarListaStickers(OrdenModel orden) {
    final List<StickerItem> stickers = [];
    final ordenCodigo = orden.codigoVisual;
    final clienteNombre = orden.clienteNombreCompleto;
    final clienteTelefono = orden.cliente?.telefono;
    final fecha = DateFormatter.formatearFechaHoraCorta(orden.createdAt);

    // 1. Sticker para el Equipo Principal
    final equipo = orden.equipo;
    final nombreEquipo = equipo != null ? equipo.nombreCompleto : 'Equipo Técnico';
    final serieEquipo = (equipo?.numeroSerie != null && equipo!.numeroSerie!.trim().isNotEmpty)
        ? 'S/N: ${equipo.numeroSerie}'
        : 'Tipo: ${equipo?.tipoFormateado ?? 'General'}';

    stickers.add(
      StickerItem(
        titulo: '🏷️ EQUIPO PRINCIPAL',
        subtitulo: '$nombreEquipo ($serieEquipo)',
        ordenCodigo: ordenCodigo,
        clienteNombre: clienteNombre,
        clienteTelefono: clienteTelefono,
        fecha: fecha,
        esPrincipal: true,
      ),
    );

    // 2. Stickers para cada accesorio registrado
    if (equipo?.accesorios != null && equipo!.accesorios!.trim().isNotEmpty) {
      final listaAccesorios = equipo.accesorios!
          .split(RegExp(r'[,;\n\+]'))
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      final total = listaAccesorios.length;
      for (int i = 0; i < total; i++) {
        final acc = listaAccesorios[i];
        stickers.add(
          StickerItem(
            titulo: '🔌 ACCESORIO [${i + 1}/$total]',
            subtitulo: acc,
            ordenCodigo: ordenCodigo,
            clienteNombre: clienteNombre,
            clienteTelefono: clienteTelefono,
            fecha: fecha,
            esPrincipal: false,
          ),
        );
      }
    }

    return stickers;
  }

  /// Genera un documento PDF formateado para rollo de stickers térmicos (50mm x 30mm estándar o 58mm)
  static Future<Uint8List> generarPdfStickers({
    required List<StickerItem> items,
    double anchoMm = 50.0,
    double altoMm = 30.0,
  }) async {
    final pdf = pw.Document();

    // Convertir mm a puntos tipográficos (1 mm = 2.83465 pt)
    final formatoPagina = PdfPageFormat(
      anchoMm * PdfPageFormat.mm,
      altoMm * PdfPageFormat.mm,
      marginLeft: 2 * PdfPageFormat.mm,
      marginRight: 2 * PdfPageFormat.mm,
      marginTop: 2 * PdfPageFormat.mm,
      marginBottom: 2 * PdfPageFormat.mm,
    );

    for (final item in items) {
      pdf.addPage(
        pw.Page(
          pageFormat: formatoPagina,
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              padding: const pw.EdgeInsets.all(3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Lado Izquierdo: Información y texto
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Encabezado
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TECROBSYS',
                              style: const pw.TextStyle(
                                fontSize: 6.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              item.fecha,
                              style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                        // Tipo de Ítem / Accesorio
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                          decoration: pw.BoxDecoration(
                            color: item.esPrincipal ? PdfColors.black : PdfColors.grey300,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                          child: pw.Text(
                            item.titulo,
                            style: pw.TextStyle(
                              fontSize: 5.5,
                              fontWeight: pw.FontWeight.bold,
                              color: item.esPrincipal ? PdfColors.white : PdfColors.black,
                            ),
                          ),
                        ),
                        // Código de Orden destacado
                        pw.Text(
                          item.ordenCodigo,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        // Descripción del ítem
                        pw.Text(
                          item.subtitulo,
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: const pw.TextStyle(
                            fontSize: 5.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        // Datos del Cliente
                        pw.Text(
                          'Cli: ${item.clienteNombre}',
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: const pw.TextStyle(fontSize: 5),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 3),
                  // Lado Derecho: Código QR
                  pw.Expanded(
                    flex: 1,
                    child: pw.Center(
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: item.ordenCodigo,
                        width: 20 * PdfPageFormat.mm,
                        height: 20 * PdfPageFormat.mm,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Abre el asistente de impresión / envío a impresora Bluetooth o térmica
  static Future<void> imprimirStickers({
    required List<StickerItem> items,
    String tituloTrabajo = 'Stickers de Orden',
  }) async {
    final pdfBytes = await generarPdfStickers(items: items);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: tituloTrabajo,
    );
  }
}
