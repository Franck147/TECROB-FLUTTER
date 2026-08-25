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
    final fechaHoy = DateFormatter.obtenerFechaHoy();

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, $nombreTecnico!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              fechaHoy,
              style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargarDatos(),
        color: AppColors.rojoPrimario,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Métricas Resumen ──
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      titulo: 'Órdenes Activas',
                      valor: '${dashboardState.activasCount}',
                      icono: Icons.pending_actions,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      titulo: 'Pendientes',
                      valor: '${dashboardState.pendientesCount}',
                      icono: Icons.error_outline,
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
                  const Text(
                    'ÓRDENES RECIENTES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onNavigateToOrdenes,
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.textoMuted),
                      SizedBox(height: 12),
                      Text(
                        'No hay órdenes registradas aún',
                        style: TextStyle(color: AppColors.textoSecundario, fontSize: 14),
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
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBorde, width: 1),
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
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icono, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
