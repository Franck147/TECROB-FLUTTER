import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/sticker_label_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_helper.dart';
import '../../providers/app_providers.dart';
import '../../widgets/consulta_dni_express_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToOrdenes;

  const DashboardScreen({
    super.key,
    required this.onNavigateToOrdenes,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() {
    final auth = ref.read(authProvider);
    if (auth.tecnico?.empresaId != null) {
      ref.read(dashboardProvider.notifier).cargarDatos(auth.tecnico!.empresaId!);
    }
  }

  void _abrirConsultaDni() {
    showDialog(
      context: context,
      builder: (_) => const ConsultaDniExpressDialog(),
    );
  }

  void _probarSticker() async {
    final item = StickerItem(
      titulo: '🏷️ STICKER DE PRUEBA',
      subtitulo: 'Laptop Dell Inspiron 15 (S/N: TEST-001)',
      ordenCodigo: '#OT-TEST',
      clienteNombre: 'CLIENTE PRUEBA',
      clienteTelefono: '999-888-777',
      fecha: DateFormatter.formatearFechaHoraCorta(DateTime.now().toIso8601String()),
      esPrincipal: true,
    );

    try {
      await StickerLabelService.imprimirStickers(
        items: [item],
        tituloTrabajo: 'Test_Sticker_TecrobSys',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en impresión: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);

    final nombreTecnico = authState.tecnico?.nombre ?? 'Técnico';
    final rolTecnico = authState.tecnico?.esAdmin == true ? 'Administrador' : 'Técnico';
    final fechaHoy = DateFormatter.obtenerFechaHoy();

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.rojoPrimario, AppColors.rojoOscuro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rojoPrimario.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel Ejecutivo • $nombreTecnico',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$rolTecnico • $fechaHoy',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textoSecundario),
            tooltip: 'Actualizar métricas',
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargarDatos(),
        color: AppColors.rojoPrimario,
        backgroundColor: AppColors.fondoTarjeta,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════════════════════════════
              //  1. CENTRO FINANCIERO Y KPIS ECONÓMICOS
              // ══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      titulo: 'Ingresos Registrados',
                      valor: CurrencyFormatter.format(dashboardState.totalIngresos),
                      icono: Icons.attach_money_rounded,
                      color: AppColors.tertiary,
                      detalle: '${dashboardState.totalOrdenes} órdenes totales',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFinancialCard(
                      titulo: 'Por Cobrar en Taller',
                      valor: CurrencyFormatter.format(dashboardState.cuentasPorCobrar),
                      icono: Icons.account_balance_wallet_rounded,
                      color: AppColors.secondary,
                      detalle: '${dashboardState.activasCount} órdenes activas',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      titulo: 'Equipos Reparados',
                      valor: '${dashboardState.equiposReparados}',
                      icono: Icons.task_alt_rounded,
                      color: AppColors.estadoListoTexto,
                      detalle: 'Listos / Entregados',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFinancialCard(
                      titulo: 'Ticket Promedio',
                      valor: CurrencyFormatter.format(dashboardState.ticketPromedio),
                      icono: Icons.receipt_long_rounded,
                      color: AppColors.rojoClaro,
                      detalle: 'Promedio por orden',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ══════════════════════════════════════════════════════════════
              //  2. ACCIONES RÁPIDAS DEL TALLER (TOOLBOX)
              // ══════════════════════════════════════════════════════════════
              _buildSectionTitle('HERRAMIENTAS RÁPIDAS', Icons.flash_on_rounded),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      titulo: 'Consulta DNI',
                      subtitulo: 'Buscar en RENIEC',
                      icono: Icons.badge_outlined,
                      color: AppColors.tertiary,
                      onTap: _abrirConsultaDni,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionCard(
                      titulo: 'Test Sticker',
                      subtitulo: 'Impresora Bluetooth',
                      icono: Icons.bluetooth_audio_rounded,
                      color: AppColors.rojoPrimario,
                      onTap: _probarSticker,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickActionCard(
                      titulo: 'Ver Órdenes',
                      subtitulo: 'Gestión completa',
                      icono: Icons.receipt_long_rounded,
                      color: AppColors.secondary,
                      onTap: widget.onNavigateToOrdenes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ══════════════════════════════════════════════════════════════
              //  3. ALERTA: EQUIPOS LISTOS PARA ENTREGA (WHATSAPP)
              // ══════════════════════════════════════════════════════════════
              if (dashboardState.ordenesListasParaEntrega.isNotEmpty) ...[
                _buildSectionTitle(
                  'EQUIPOS LISTOS POR RECOGER (${dashboardState.ordenesListasParaEntrega.length})',
                  Icons.notifications_active_rounded,
                  color: AppColors.verdeWhatsapp,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fondoTarjeta,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.verdeWhatsapp.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: dashboardState.ordenesListasParaEntrega.map((orden) {
                      final cliente = orden.cliente;
                      final tel = cliente?.telefono ?? '';
                      final equipo = orden.equipo?.nombreCompleto ?? 'Equipo';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.verdeWhatsappFondo,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.verdeWhatsapp,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${orden.codigoVisual} • ${orden.clienteNombreCompleto}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textoPrincipal,
                                    ),
                                  ),
                                  Text(
                                    '$equipo • Saldo: ${CurrencyFormatter.format(orden.saldoPendiente)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textoSecundario,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (tel.isNotEmpty) {
                                  final msg = WhatsappService.generarMensajeOrdenLista(
                                    nombreCliente: orden.clienteNombreCompleto,
                                    equipo: equipo,
                                    numeroOrden: orden.codigoVisual,
                                  );
                                  WhatsappService.abrirChat(telefono: tel, mensaje: msg);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('El cliente no tiene teléfono registrado')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verdeWhatsapp,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.chat_rounded, size: 14),
                              label: const Text('Avisar WA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 22),
              ],

              // ══════════════════════════════════════════════════════════════
              //  4. DISTRIBUCIÓN DEL EMBUDO DE TRABAJO DEL TALLER
              // ══════════════════════════════════════════════════════════════
              _buildSectionTitle('ESTADO DEL TALLER', Icons.donut_large_rounded),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fondoBorde),
                ),
                child: Column(
                  children: [
                    _buildStatusProgressRow(
                      estado: 'pendiente',
                      etiqueta: 'Por Diagnosticar / Pendientes',
                      cantidad: dashboardState.distribucionEstados['pendiente'] ?? 0,
                      total: dashboardState.totalOrdenes,
                    ),
                    const SizedBox(height: 10),
                    _buildStatusProgressRow(
                      estado: 'diagnostico',
                      etiqueta: 'En Diagnóstico',
                      cantidad: dashboardState.distribucionEstados['diagnostico'] ?? 0,
                      total: dashboardState.totalOrdenes,
                    ),
                    const SizedBox(height: 10),
                    _buildStatusProgressRow(
                      estado: 'en_progreso',
                      etiqueta: 'En Reparación / Progreso',
                      cantidad: dashboardState.distribucionEstados['en_progreso'] ?? 0,
                      total: dashboardState.totalOrdenes,
                    ),
                    const SizedBox(height: 10),
                    _buildStatusProgressRow(
                      estado: 'listo',
                      etiqueta: 'Listos para Retiro',
                      cantidad: dashboardState.distribucionEstados['listo'] ?? 0,
                      total: dashboardState.totalOrdenes,
                    ),
                    const SizedBox(height: 10),
                    _buildStatusProgressRow(
                      estado: 'entregado',
                      etiqueta: 'Entregados al Cliente',
                      cantidad: dashboardState.distribucionEstados['entregado'] ?? 0,
                      total: dashboardState.totalOrdenes,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ══════════════════════════════════════════════════════════════
              //  5. TIPOS DE EQUIPO ATENDIDOS
              // ══════════════════════════════════════════════════════════════
              _buildSectionTitle('EQUIPOS ATENDIDOS EN TALLER', Icons.devices_rounded),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fondoTarjeta,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fondoBorde),
                ),
                child: dashboardState.distribucionTiposEquipo.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay equipos registrados aún',
                          style: TextStyle(color: AppColors.textoSecundario, fontSize: 13),
                        ),
                      )
                    : Column(
                        children: dashboardState.distribucionTiposEquipo.entries.map((entry) {
                          final tipo = entry.key;
                          final cant = entry.value;
                          final total = dashboardState.totalOrdenes;
                          final pct = total > 0 ? (cant / total) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(
                                  StatusHelper.obtenerIconoEquipo(tipo),
                                  size: 18,
                                  color: AppColors.rojoClaro,
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    StatusHelper.obtenerTipoEquipoTexto(tipo),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 8,
                                      backgroundColor: AppColors.fondoSuperficie,
                                      color: AppColors.rojoPrimario,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$cant (${(pct * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color color = AppColors.textoPrincipal}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    required String detalle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fondoBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textoSecundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detalle,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textoMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fondoTarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fondoBorde),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrincipal,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitulo,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textoMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgressRow({
    required String estado,
    required String etiqueta,
    required int cantidad,
    required int total,
  }) {
    final color = StatusHelper.obtenerColorTexto(estado);
    final pct = total > 0 ? (cantidad / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  etiqueta,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              '$cantidad (${(pct * 100).toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.fondoSuperficie,
            color: color,
          ),
        ),
      ],
    );
  }
}
