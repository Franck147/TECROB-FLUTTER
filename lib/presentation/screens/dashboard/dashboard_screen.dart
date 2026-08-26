import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/app_providers.dart';
import '../../widgets/orden_card.dart';
import '../ordenes/detalle_orden_screen.dart';

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
    if (auth.tecnico != null && auth.tecnico!.empresaId != null) {
      ref.read(dashboardProvider.notifier).cargarDatos(auth.tecnico!.empresaId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);

    final nombreTecnico = authState.tecnico?.nombre ?? 'Técnico';
    final rolTecnico = authState.tecnico?.esAdministrador == true ? 'Administrador' : 'Técnico Especialista';
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
                    color: AppColors.rojoPrimario.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.handyman_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $nombreTecnico',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
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
            tooltip: 'Actualizar datos',
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 6),
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
              // ── Métricas Resumen Rediseñadas ──
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      titulo: 'Órdenes Activas',
                      subtitulo: 'En taller',
                      valor: '${dashboardState.activasCount}',
                      icono: Icons.pending_actions_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      titulo: 'Pendientes',
                      subtitulo: 'Por diagnosticar',
                      valor: '${dashboardState.pendientesCount}',
                      icono: Icons.hourglass_top_rounded,
                      color: AppColors.rojoPrimario,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Encabezado Órdenes Recientes ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.rojoPrimario,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ÓRDENES RECIENTES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: widget.onNavigateToOrdenes,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rojoPrimario,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text(
                      'Ver todas',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Lista de Órdenes Recientes ──
              if (dashboardState.isLoading && dashboardState.ordenesRecientes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.rojoPrimario),
                  ),
                )
              else if (dashboardState.ordenesRecientes.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.fondoTarjeta,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fondoBorde),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.textoMuted),
                      SizedBox(height: 14),
                      Text(
                        'No hay órdenes registradas aún',
                        style: TextStyle(
                          color: AppColors.textoPrincipal,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Presiona el botón (+) para registrar tu primera orden',
                        style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dashboardState.ordenesRecientes.length,
                  itemBuilder: (context, index) {
                    final orden = dashboardState.ordenesRecientes[index];
                    return OrdenCard(
                      orden: orden,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetalleOrdenScreen(ordenId: orden.id),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String subtitulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fondoBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textoPrincipal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}
