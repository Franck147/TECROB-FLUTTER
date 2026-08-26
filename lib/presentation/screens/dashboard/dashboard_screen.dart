import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_helper.dart';
import '../../providers/app_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToOrdenes;

  const DashboardScreen({
    super.key,
    this.onNavigateToOrdenes,
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = AppColors.isDark(context);

    final nombreTecnico = authState.tecnico?.nombre ?? 'Técnico';
    final rolTecnico = authState.tecnico?.esAdmin == true ? 'Administrador' : 'Técnico';
    final fechaHoy = DateFormatter.obtenerFechaHoy();

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipalOf(context),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipalOf(context),
                    ),
                  ),
                  Text(
                    '$rolTecnico • $fechaHoy',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textoSecundarioOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón Rápido de Cambio de Tema (Modo Claro / Modo Oscuro)
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: themeMode == ThemeMode.dark ? AppColors.secondary : AppColors.rojoPrimario,
            ),
            tooltip: themeMode == ThemeMode.dark ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textoSecundarioOf(context)),
            tooltip: 'Actualizar métricas',
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargarDatos(),
        color: AppColors.rojoPrimario,
        backgroundColor: AppColors.fondoTarjetaOf(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
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
                          context: context,
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
                          context: context,
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
                          context: context,
                          titulo: 'Equipos Reparados',
                          valor: '${dashboardState.equiposReparados}',
                          icono: Icons.task_alt_rounded,
                          color: isDark ? AppColors.estadoListoTexto : AppColors.estadoListoTextoClaro,
                          detalle: 'Listos / Entregados',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFinancialCard(
                          context: context,
                          titulo: 'Ticket Promedio',
                          valor: CurrencyFormatter.format(dashboardState.ticketPromedio),
                          icono: Icons.receipt_long_rounded,
                          color: AppColors.rojoPrimario,
                          detalle: 'Promedio por orden',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ══════════════════════════════════════════════════════════════
                  //  2. ALERTA: EQUIPOS LISTOS PARA ENTREGA (WHATSAPP)
                  // ══════════════════════════════════════════════════════════════
                  if (dashboardState.ordenesListasParaEntrega.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      'EQUIPOS LISTOS POR RECOGER (${dashboardState.ordenesListasParaEntrega.length})',
                      Icons.notifications_active_rounded,
                      color: AppColors.verdeWhatsapp,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.fondoTarjetaOf(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.verdeWhatsapp.withValues(alpha: isDark ? 0.35 : 0.4),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : AppColors.verdeWhatsapp.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: dashboardState.ordenesListasParaEntrega.map((orden) {
                          final cliente = orden.cliente;
                          final tel = cliente?.telefono ?? '';
                          final equipo = orden.equipo?.nombreCompleto ?? 'Equipo';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.verdeWhatsappFondoOf(context),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.verdeWhatsapp,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${orden.codigoVisual} • ${orden.clienteNombreCompleto}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: AppColors.textoPrincipalOf(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$equipo • Saldo: ${CurrencyFormatter.format(orden.saldoPendiente)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textoSecundarioOf(context),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 1,
                                  ),
                                  icon: const Icon(Icons.chat_rounded, size: 14),
                                  label: const Text(
                                    'Avisar WA',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
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
                  //  3. DISTRIBUCIÓN DEL EMBUDO DE TRABAJO DEL TALLER
                  // ══════════════════════════════════════════════════════════════
                  _buildSectionTitle(context, 'ESTADO DEL TALLER', Icons.donut_large_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjetaOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.fondoBordeOf(context)),
                    ),
                    child: Column(
                      children: [
                        _buildStatusProgressRow(
                          context: context,
                          estado: 'pendiente',
                          etiqueta: 'Por Diagnosticar / Pendientes',
                          cantidad: dashboardState.distribucionEstados['pendiente'] ?? 0,
                          total: dashboardState.totalOrdenes,
                        ),
                        const SizedBox(height: 10),
                        _buildStatusProgressRow(
                          context: context,
                          estado: 'diagnostico',
                          etiqueta: 'En Diagnóstico',
                          cantidad: dashboardState.distribucionEstados['diagnostico'] ?? 0,
                          total: dashboardState.totalOrdenes,
                        ),
                        const SizedBox(height: 10),
                        _buildStatusProgressRow(
                          context: context,
                          estado: 'en_progreso',
                          etiqueta: 'En Reparación / Progreso',
                          cantidad: dashboardState.distribucionEstados['en_progreso'] ?? 0,
                          total: dashboardState.totalOrdenes,
                        ),
                        const SizedBox(height: 10),
                        _buildStatusProgressRow(
                          context: context,
                          estado: 'listo',
                          etiqueta: 'Listos para Retiro',
                          cantidad: dashboardState.distribucionEstados['listo'] ?? 0,
                          total: dashboardState.totalOrdenes,
                        ),
                        const SizedBox(height: 10),
                        _buildStatusProgressRow(
                          context: context,
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
                  //  4. TIPOS DE EQUIPO ATENDIDOS
                  // ══════════════════════════════════════════════════════════════
                  _buildSectionTitle(context, 'EQUIPOS ATENDIDOS EN TALLER', Icons.devices_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjetaOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.fondoBordeOf(context)),
                    ),
                    child: dashboardState.distribucionTiposEquipo.isEmpty
                        ? Center(
                            child: Text(
                              'No hay equipos registrados aún',
                              style: TextStyle(color: AppColors.textoSecundarioOf(context), fontSize: 13),
                            ),
                          )
                        : Column(
                            children: dashboardState.distribucionTiposEquipo.entries.map((entry) {
                              final tipo = entry.key;
                              final cant = entry.value;
                              final total = dashboardState.totalOrdenes;
                              final pct = total > 0 ? (cant / total) : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      StatusHelper.obtenerIconoEquipo(tipo),
                                      size: 18,
                                      color: AppColors.rojoPrimario,
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        StatusHelper.obtenerTipoEquipoTexto(tipo),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textoPrincipalOf(context),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 8,
                                          backgroundColor: AppColors.fondoSuperficieOf(context),
                                          color: AppColors.rojoPrimario,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$cant (${(pct * 100).toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textoSecundarioOf(context),
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, {Color? color}) {
    final titleColor = color ?? AppColors.textoPrincipalOf(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: titleColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: titleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard({
    required BuildContext context,
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    required String detalle,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textoSecundarioOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.12 : 0.1),
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
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textoMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgressRow({
    required BuildContext context,
    required String estado,
    required String etiqueta,
    required int cantidad,
    required int total,
  }) {
    final isDark = AppColors.isDark(context);
    final color = StatusHelper.obtenerColorTexto(estado, isDark: isDark);
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
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPrincipalOf(context),
                  ),
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
            backgroundColor: AppColors.fondoSuperficieOf(context),
            color: color,
          ),
        ),
      ],
    );
  }
}
