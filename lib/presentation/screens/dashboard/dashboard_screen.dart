import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_helper.dart';
import '../../../data/models/orden_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/listas_por_recoger_card.dart';
import '../ordenes/detalle_orden_screen.dart';

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
    if (auth.tecnico != null) {
      ref.read(dashboardProvider.notifier).cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final themeMode = ref.watch(themeModeProvider);

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
                  colors: [AppColors.primario, AppColors.primarioOscuro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primario.withValues(alpha: 0.35),
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
              color: themeMode == ThemeMode.dark ? AppColors.secondary : AppColors.primario,
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
        color: AppColors.primario,
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
                  //  1. NECESITA ATENCIÓN
                  // ══════════════════════════════════════════════════════════════
                  _buildSectionTitle(
                    context,
                    'NECESITA ATENCIÓN',
                    Icons.priority_high_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildFilaAtencion(context, dashboardState),
                  const SizedBox(height: 22),

                  // ══════════════════════════════════════════════════════════════
                  //  2. COLA DEL TALLER
                  // ══════════════════════════════════════════════════════════════
                  _buildSectionTitle(
                    context,
                    'COLA DEL TALLER · ${dashboardState.activasCount} ÓRDENES ACTIVAS',
                    Icons.donut_large_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildBarraEstados(context, dashboardState),
                  const SizedBox(height: 22),

                  // ══════════════════════════════════════════════════════════════
                  //  3. ALERTA: EQUIPOS LISTOS PARA ENTREGA (WHATSAPP)
                  // ══════════════════════════════════════════════════════════════
                  if (dashboardState.ordenesListasParaEntrega.isNotEmpty) ...[
                    _buildSectionTitle(
                      context,
                      'LISTAS POR RECOGER (${dashboardState.ordenesListasParaEntrega.length})',
                      Icons.notifications_active_rounded,
                      color: AppColors.verdeWhatsapp,
                    ),
                    const SizedBox(height: 8),
                    ListasPorRecogerCard(
                      ordenes: dashboardState.ordenesListasParaEntrega,
                      onAvisar: _avisarPorWhatsapp,
                      onAbrirOrden: _abrirOrden,
                    ),
                    const SizedBox(height: 22),
                  ],

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
                                      color: AppColors.primario,
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
                                          color: AppColors.primario,
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

  // ══════════════════════════════════════════════════════════════════════
  //  NECESITA ATENCIÓN
  // ══════════════════════════════════════════════════════════════════════

  /// Las tres cosas que pueden requerir acción hoy. Cada tarjeta abre la
  /// lista de órdenes ya filtrada, para no tener que buscarlas a mano.
  Widget _buildFilaAtencion(BuildContext context, DashboardState estado) {
    final vencidas = estado.vencidasCount;
    final retraso = estado.diasMaximoRetraso;

    final tarjetas = [
      _buildTarjetaAtencion(
        context: context,
        titulo: 'Pasadas de fecha',
        valor: '$vencidas',
        detalle: vencidas == 0
            ? 'Todo dentro del plazo'
            : 'La más antigua lleva $retraso ${retraso == 1 ? 'día' : 'días'}',
        icono: Icons.warning_amber_rounded,
        color: AppColors.errorOf(context),
        resaltar: vencidas > 0,
        onTap: vencidas == 0 ? null : _verOrdenesVencidas,
      ),
      _buildTarjetaAtencion(
        context: context,
        titulo: 'Listas por recoger',
        valor: '${estado.listasCount}',
        detalle: estado.listasCount == 0
            ? 'Nada esperando al cliente'
            : 'Avisar por WhatsApp',
        icono: Icons.check_circle_outline_rounded,
        color: AppColors.exitoOf(context),
        onTap: estado.listasCount == 0 ? null : () => _verOrdenesPorEstado('listo'),
      ),
      _buildTarjetaAtencion(
        context: context,
        titulo: 'Sin diagnosticar',
        valor: '${estado.pendientesCount}',
        detalle: estado.pendientesCount == 0
            ? 'Ninguna esperando revisión'
            : 'Ingresadas y aún sin revisar',
        icono: Icons.pending_actions_rounded,
        color: AppColors.avisoOf(context),
        onTap: estado.pendientesCount == 0 ? null : () => _verOrdenesPorEstado('pendiente'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas angostas las tres tarjetas se apilan.
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (var i = 0; i < tarjetas.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                tarjetas[i],
              ],
            ],
          );
        }

        // IntrinsicHeight acota la altura de la fila. Sin él, `stretch` pide a
        // las tarjetas que llenen un alto sin límite, porque esto vive dentro
        // de un scroll vertical, y la fila nunca llega a medirse.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tarjetas.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: tarjetas[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaAtencion({
    required BuildContext context,
    required String titulo,
    required String valor,
    required String detalle,
    required IconData icono,
    required Color color,
    required VoidCallback? onTap,
    bool resaltar = false,
  }) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.fondoTarjetaOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: resaltar
                  ? color.withValues(alpha: isDark ? 0.5 : 0.4)
                  : AppColors.fondoBordeOf(context),
              width: resaltar ? 1.3 : 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icono, color: color, size: 16),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoSecundarioOf(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                valor,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                detalle,
                style: TextStyle(fontSize: 11.5, color: AppColors.textoMutedOf(context)),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text(
                      'Ver estas órdenes',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primarioOf(context),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.primarioOf(context),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  COLA DEL TALLER
  // ══════════════════════════════════════════════════════════════════════

  /// Los cuatro estados activos en una sola barra proporcional, con su
  /// leyenda debajo. Sustituye a las cinco barras de progreso separadas.
  Widget _buildBarraEstados(BuildContext context, DashboardState estado) {
    final tramos = <_TramoEstado>[
      _TramoEstado('Pendiente', estado.distribucionEstados['pendiente'] ?? 0,
          AppColors.avisoOf(context)),
      _TramoEstado('Diagnóstico', estado.distribucionEstados['diagnostico'] ?? 0,
          AppColors.isDark(context)
              ? AppColors.estadoDiagnosticoTexto
              : AppColors.estadoDiagnosticoTextoClaro),
      _TramoEstado('En progreso', estado.distribucionEstados['en_progreso'] ?? 0,
          AppColors.primarioOf(context)),
      _TramoEstado('Listo', estado.distribucionEstados['listo'] ?? 0,
          AppColors.exitoOf(context)),
    ];

    final total = tramos.fold<int>(0, (suma, t) => suma + t.cantidad);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBordeOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 22,
              child: total == 0
                  ? Container(
                      color: AppColors.fondoSuperficieOf(context),
                      alignment: Alignment.center,
                      child: Text(
                        'No hay órdenes activas en el taller',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textoMutedOf(context),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        for (final tramo in tramos)
                          if (tramo.cantidad > 0)
                            Expanded(
                              flex: tramo.cantidad,
                              child: Container(
                                color: tramo.color,
                                alignment: Alignment.center,
                                child: Text(
                                  '${tramo.cantidad}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              for (final tramo in tramos)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: tramo.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${tramo.etiqueta} ${tramo.cantidad}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textoSecundarioOf(context),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  NAVEGACIÓN A LA LISTA DE ÓRDENES
  // ══════════════════════════════════════════════════════════════════════

  /// Abre el chat de WhatsApp con el aviso de que el equipo ya está listo.
  void _avisarPorWhatsapp(OrdenModel orden) {
    final telefono = orden.cliente?.telefono ?? '';
    if (telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El cliente no tiene teléfono registrado')),
      );
      return;
    }

    WhatsappService.abrirChat(
      telefono: telefono,
      mensaje: WhatsappService.generarMensajeOrdenLista(
        nombreCliente: orden.clienteNombreCompleto,
        equipo: orden.equipo?.nombreCompleto ?? 'Equipo',
        numeroOrden: orden.codigoVisual,
      ),
    );
  }

  /// Al volver del detalle se recargan las métricas, porque la orden pudo
  /// entregarse o cobrarse desde ahí.
  void _abrirOrden(OrdenModel orden) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DetalleOrdenScreen(ordenId: orden.id),
          ),
        )
        .then((_) => _cargarDatos());
  }

  void _verOrdenesPorEstado(String estado) {
    ref.read(ordenesProvider.notifier).setFiltroEstado(estado);
    widget.onNavigateToOrdenes?.call();
  }

  void _verOrdenesVencidas() {
    ref.read(ordenesProvider.notifier).setSoloVencidas();
    widget.onNavigateToOrdenes?.call();
  }
}

/// Un tramo de la barra apilada de estados.
class _TramoEstado {
  final String etiqueta;
  final int cantidad;
  final Color color;

  const _TramoEstado(this.etiqueta, this.cantidad, this.color);
}
