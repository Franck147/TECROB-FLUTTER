import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/orden_model.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoiceBytes(OrdenModel orden) async {
    final pdf = pw.Document();

    final numOrden = orden.numeroOrdenDisplay;
    final fechaCreacion = DateFormatter.formatearFechaCorta(orden.createdAt);
    final fechaPrometida = orden.fechaPrometida != null
        ? DateFormatter.formatearFechaCorta(orden.fechaPrometida)
        : '—';

    final cliente = orden.cliente;
    final equipo = orden.equipo;
    final tecnico = orden.tecnico;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 38,
                        height: 38,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.black,
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'T',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            AppConstants.empresaRazonSocial,
                            style: const pw.TextStyle(
                              fontSize: 11.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${AppConstants.empresaSubtitulo} • ${AppConstants.empresaTelefono}',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            AppConstants.empresaEmail,
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ORDEN DE SERVICIO',
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        numOrden,
                        style: const pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        fechaCreacion,
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.5, color: PdfColors.black),
              pw.SizedBox(height: 10),

              // ── Cliente Section ──
              _buildSectionTitle('DATOS DEL CLIENTE'),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildField('Nombre completo', cliente?.nombreCompleto ?? '—', flex: 4),
                  _buildField('DNI', cliente?.dni ?? '—', flex: 2),
                  _buildField('Teléfono', cliente?.telefono ?? '—', flex: 2),
                  _buildField('Técnico asignado', tecnico?.nombreCompleto ?? '—', flex: 3),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // ── Equipo Section ──
              _buildSectionTitle('DATOS DEL EQUIPO'),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildField('Tipo', equipo?.tipoFormateado ?? '—', flex: 2),
                  _buildField('Marca / Modelo', equipo?.nombreCompleto ?? '—', flex: 3),
                  _buildField('N° Serie', equipo?.numeroSerie ?? '—', flex: 3),
                  _buildField('Accesorios', equipo?.accesorios ?? '—', flex: 4),
                ],
              ),
              pw.SizedBox(height: 6),
              _buildField('Problema / Desperfecto reportado', equipo?.desperfecto ?? '—'),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // ── Servicios Section ──
              _buildSectionTitle('DETALLE DEL SERVICIO'),
              pw.SizedBox(height: 6),
              pw.Table(
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FixedColumnWidth(40),
                  2: const pw.FixedColumnWidth(70),
                  3: const pw.FixedColumnWidth(70),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                    ),
                    children: [
                      _buildTableHeader('DESCRIPCIÓN'),
                      _buildTableHeader('CANT.', align: pw.TextAlign.center),
                      _buildTableHeader('P. UNITARIO', align: pw.TextAlign.right),
                      _buildTableHeader('SUBTOTAL', align: pw.TextAlign.right),
                    ],
                  ),
                  if (orden.itemsServicio.isNotEmpty)
                    ...orden.itemsServicio.map(
                      (item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 5),
                            child: pw.Text(
                              item.servicio?.nombre ?? 'Servicio técnico',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 5),
                            child: pw.Text(
                              '${item.cantidad}',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 5),
                            child: pw.Text(
                              CurrencyFormatter.format(item.precioUnitario),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 5),
                            child: pw.Text(
                              CurrencyFormatter.format(item.subtotal),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Text(
                            'Sin servicios registrados',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500),
                          ),
                        ),
                        pw.Container(),
                        pw.Container(),
                        pw.Container(),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── Totales ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _buildTotalRow('Subtotal', CurrencyFormatter.format(orden.subtotal)),
                        _buildTotalRow('Descuento', '- ${CurrencyFormatter.format(orden.descuento)}'),
                        _buildTotalRow('Adelanto', '- ${CurrencyFormatter.format(orden.adelanto)}'),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL A COBRAR',
                              style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              CurrencyFormatter.format(orden.saldoPendiente),
                              style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // ── Entrega y Firmas ──
              _buildSectionTitle('ENTREGA DEL EQUIPO'),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  _buildField('Fecha de ingreso', fechaCreacion, flex: 1),
                  _buildField('Fecha prometida', fechaPrometida, flex: 1),
                  _buildField('Técnico responsable', tecnico?.nombreCompleto ?? '—', flex: 2),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Firma del cliente:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 20),
                        pw.Divider(thickness: 0.8, color: PdfColors.grey500),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Firma del técnico:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.SizedBox(height: 20),
                        pw.Divider(thickness: 0.8, color: PdfColors.grey500),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // ── Términos y Condiciones ──
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                child: pw.Text(
                  'TÉRMINOS Y CONDICIONES — Los equipos no retirados en 60 días desde la fecha prometida serán considerados en abandono. TecrobSys no se responsabiliza por la pérdida de información almacenada en el equipo. Garantía de 30 días sobre los trabajos realizados desde la fecha de entrega. Conserve este comprobante para el retiro de su equipo.',
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600, lineSpacing: 1.4),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: const pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey600,
        letterSpacing: 1.2,
      ),
    );
  }

  static pw.Widget _buildField(String label, String value, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600, letterSpacing: 0.5),
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static Future<void> imprimirOCompartir(OrdenModel orden) async {
    final pdfBytes = await generateInvoiceBytes(orden);
    final fileName = 'orden_${orden.numeroOrden ?? orden.id}.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }
}
