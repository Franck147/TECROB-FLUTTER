import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_helper.dart';
import '../../providers/app_providers.dart';
import '../../widgets/change_status_dialog.dart';
import '../../widgets/imprimir_stickers_dialog.dart';
import '../../widgets/register_payment_dialog.dart';
import '../../widgets/status_badge.dart';

class DetalleOrdenScreen extends ConsumerStatefulWidget {
  final int ordenId;

  const DetalleOrdenScreen({super.key, required this.ordenId});

  @override
  ConsumerState<DetalleOrdenScreen> createState() => _DetalleOrdenScreenState();
}

class _DetalleOrdenScreenState extends ConsumerState<DetalleOrdenScreen> {
  bool _isGeneratingPdf = false;

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppColors.error : AppColors.tertiary,
      ),
    );
  }

  void _abrirDialogoCambioEstado(String estadoActual) {
    showDialog(
      context: context,
      builder: (ctx) => ChangeStatusDialog(
        estadoActual: estadoActual,
        onSelectStatus: (nuevoEstado) async {
          final ok = await ref
              .read(detalleOrdenProvider(widget.ordenId).notifier)
              .actualizarEstado(nuevoEstado);
          if (ok) _mostrarMensaje('Estado cambiado a ${StatusHelper.obtenerTexto(nuevoEstado)}');
        },
      ),
    );
  }

  void _abrirDialogoPago(double saldoPendiente) {
    showDialog(
      context: context,
      builder: (ctx) => RegisterPaymentDialog(
        saldoPendiente: saldoPendiente,
        onSave: (monto, metodo, nota) async {
          final ok = await ref
              .read(detalleOrdenProvider(widget.ordenId).notifier)
              .registrarPago(monto: monto, metodo: metodo, nota: nota);
          if (ok) _mostrarMensaje('Pago de S/ $monto registrado correctamente');
        },
      ),
    );
  }

  void _abrirDialogoStickers(dynamic orden) {
    showDialog(
      context: context,
      builder: (ctx) => ImprimirStickersDialog(orden: orden),
    );
  }

  Future<void> _compartirPdf() async {
    final state = ref.read(detalleOrdenProvider(widget.ordenId));
    final orden = state.orden;
    if (orden == null) return;

    setState(() => _isGeneratingPdf = true);
    try {
      await PdfInvoiceService.imprimirOCompartir(orden);
    } catch (e) {
      _mostrarMensaje('Error al generar PDF: $e', esError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _marcarListoYAvisar() async {
    final state = ref.read(detalleOrdenProvider(widget.ordenId));
    final orden = state.orden;
    if (orden == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoTarjetaOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.fondoBordeOf(context)),
        ),
        title: const Text('Marcar Orden como Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se cambiará el estado a LISTO y se abrirá WhatsApp con el mensaje:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.fondoSuperficieOf(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                WhatsappService.generarMensajeOrdenLista(
                  nombreCliente: orden.cliente?.nombre ?? 'Cliente',
                  equipo: orden.equipo?.nombreCompleto ?? 'Equipo',
                  numeroOrden: orden.numeroOrdenDisplay,
                ),
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundarioOf(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verdeWhatsapp),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar y Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ref
        .read(detalleOrdenProvider(widget.ordenId).notifier)
        .actualizarEstado('listo');

    if (ok) {
      final tel = orden.cliente?.telefono;
      if (tel != null && tel.isNotEmpty) {
        final msg = WhatsappService.generarMensajeOrdenLista(
          nombreCliente: orden.cliente?.nombre ?? 'Cliente',
          equipo: orden.equipo?.nombreCompleto ?? 'Equipo',
          numeroOrden: orden.numeroOrdenDisplay,
        );
        await WhatsappService.abrirChat(telefono: tel, mensaje: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(detalleOrdenProvider(widget.ordenId));
    final orden = state.orden;

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipalOf(context),
        title: Text(orden != null ? 'Orden ${orden.numeroOrdenDisplay}' : 'Detalle de Orden'),
        actions: [
          if (orden != null) ...[
            IconButton(
              icon: const Icon(Icons.bluetooth_audio_rounded, color: AppColors.rojoPrimario),
              tooltip: 'Imprimir Stickers Térmicos',
              onPressed: () => _abrirDialogoStickers(orden),
            ),
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exportar Comprobante PDF',
              onPressed: _isGeneratingPdf ? null : _compartirPdf,
            ),
          ],
        ],
      ),
      body: state.isLoading && orden == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.rojoPrimario))
          : orden == null
              ? Center(
                  child: Text(
                    state.errorMessage ?? 'No se pudo cargar la orden.',
                    style: TextStyle(color: AppColors.textoSecundarioOf(context)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Cabecera: N° Orden + Fecha + Estado ──
                          _buildHeaderCard(orden),
                          const SizedBox(height: 12),

                          // ── Acciones Rápidas (Stickers + PDF + WA) ──
                          _buildQuickActionsRow(orden),
                          const SizedBox(height: 12),

                          // ── Cliente Card ──
                          _buildClienteCard(orden),
                          const SizedBox(height: 12),

                          // ── Equipo Card ──
                          _buildEquipoCard(orden),
                          const SizedBox(height: 12),

                          // ── Servicios Card ──
                          _buildServiciosCard(orden),
                          const SizedBox(height: 12),

                          // ── Resumen Financiero ──
                          _buildTotalesCard(orden),
                          const SizedBox(height: 18),

                          // ── Botones de Acción Operativa ──
                          _buildActionButtons(orden),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildQuickActionsRow(dynamic orden) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _abrirDialogoStickers(orden),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: AppColors.rojoPrimario.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bluetooth_audio_rounded, size: 18, color: AppColors.rojoPrimario),
            label: const Text(
              'Stickers Térmicos',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isGeneratingPdf ? null : _compartirPdf,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(color: AppColors.fondoBordeOf(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.rojoPrimario),
            label: const Text(
              'Comprobante PDF',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(dynamic orden) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orden.numeroOrdenDisplay,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.rojoClaro : AppColors.rojoOscuro,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Creada el ${DateFormatter.formatearFechaHora(orden.createdAt)}',
                style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context)),
              ),
              if (orden.fechaPrometida != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Prometida: ${DateFormatter.formatearFechaCorta(orden.fechaPrometida)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ),
            ],
          ),
          StatusBadge(
            estado: orden.estado,
            onTap: () => _abrirDialogoCambioEstado(orden.estado),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(dynamic orden) {
    final isDark = AppColors.isDark(context);
    final cliente = orden.cliente;
    final tel = cliente?.telefono ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATOS DEL CLIENTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textoSecundarioOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.rojoContenedorOf(context),
                child: Text(
                  cliente?.iniciales ?? '?',
                  style: TextStyle(
                    color: isDark ? AppColors.rojoClaro : AppColors.rojoPrimario,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente?.nombreCompleto ?? 'Sin asignar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoPrincipalOf(context),
                      ),
                    ),
                    if (cliente?.dni != null && cliente!.dni!.isNotEmpty)
                      Text(
                        'DNI: ${cliente.dni}',
                        style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context)),
                      ),
                    if (tel.isNotEmpty)
                      Text(
                        'Tel: $tel',
                        style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context)),
                      ),
                  ],
                ),
              ),
              if (tel.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: AppColors.rojoPrimario, size: 20),
                  onPressed: () => WhatsappService.realizarLlamada(tel),
                  tooltip: 'Llamar',
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.verdeWhatsapp, size: 20),
                  onPressed: () => WhatsappService.abrirChat(telefono: tel),
                  tooltip: 'WhatsApp',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipoCard(dynamic orden) {
    final isDark = AppColors.isDark(context);
    final equipo = orden.equipo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATOS DEL EQUIPO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textoSecundarioOf(context),
            ),
          ),
          const SizedBox(height: 12),
          if (equipo == null)
            Text(
              'Sin equipo registrado',
              style: TextStyle(color: AppColors.textoMutedOf(context), fontStyle: FontStyle.italic),
            )
          else ...[
            Row(
              children: [
                Icon(
                  StatusHelper.obtenerIconoEquipo(equipo.tipo),
                  color: AppColors.rojoPrimario,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${equipo.tipoFormateado}: ${equipo.nombreCompleto}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipalOf(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (equipo.numeroSerie != null && equipo.numeroSerie!.isNotEmpty)
              _buildDataRow('N° Serie', equipo.numeroSerie!),
            if (orden.contrasenaEquipo != null && orden.contrasenaEquipo!.isNotEmpty)
              _buildDataRow('Contraseña Equipo', orden.contrasenaEquipo!),
            if (equipo.accesorios != null && equipo.accesorios!.isNotEmpty)
              _buildDataRow('Accesorios Registrados', equipo.accesorios!),
            if (equipo.desperfecto != null && equipo.desperfecto!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Problema / Falla reportada:',
                style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context)),
              ),
              const SizedBox(height: 2),
              Text(
                equipo.desperfecto!,
                style: TextStyle(fontSize: 13, color: AppColors.textoPrincipalOf(context)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildServiciosCard(dynamic orden) {
    final isDark = AppColors.isDark(context);
    final items = orden.itemsServicio;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SERVICIOS Y REPUESTOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textoSecundarioOf(context),
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No hay servicios asociados',
              style: TextStyle(color: AppColors.textoMutedOf(context), fontStyle: FontStyle.italic),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.cantidad}x  ${item.servicio?.nombre ?? "Servicio"}',
                        style: TextStyle(fontSize: 13, color: AppColors.textoPrincipalOf(context)),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.subtotal),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalesCard(dynamic orden) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFinancialRow('Subtotal', CurrencyFormatter.format(orden.subtotal)),
          _buildFinancialRow('Descuento', '- ${CurrencyFormatter.format(orden.descuento)}'),
          _buildFinancialRow('Adelantos', '- ${CurrencyFormatter.format(orden.adelanto)}'),
          Divider(height: 16, color: AppColors.fondoBordeOf(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL A COBRAR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoPrincipalOf(context),
                ),
              ),
              Text(
                CurrencyFormatter.format(orden.saldoPendiente),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: orden.saldoPendiente > 0 ? AppColors.secondary : AppColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic orden) {
    return Column(
      children: [
        // Botón principal: Avisar Listo
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('MARCAR LISTA Y AVISAR POR WHATSAPP'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdeWhatsappFondoOf(context),
            foregroundColor: AppColors.verdeWhatsapp,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.verdeWhatsapp.withValues(alpha: 0.4)),
            ),
          ),
          onPressed: _marcarListoYAvisar,
        ),
        const SizedBox(height: 10),

        // Fila de botones secundarios: Registrar Pago + Cambiar Estado
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text('Registrar Pago'),
                onPressed: () => _abrirDialogoPago(orden.saldoPendiente),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Cambiar Estado'),
                onPressed: () => _abrirDialogoCambioEstado(orden.estado),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textoPrincipalOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.textoSecundarioOf(context))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textoPrincipalOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
