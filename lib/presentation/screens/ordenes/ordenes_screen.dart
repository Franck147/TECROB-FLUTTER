import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../widgets/orden_card.dart';
import 'detalle_orden_screen.dart';

class OrdenesScreen extends ConsumerStatefulWidget {
  const OrdenesScreen({super.key});

  @override
  ConsumerState<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends ConsumerState<OrdenesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarOrdenes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarOrdenes() {
    final auth = ref.read(authProvider);
    if (auth.tecnico != null && auth.tecnico!.empresaId != null) {
      ref.read(ordenesProvider.notifier).cargarOrdenes(auth.tecnico!.empresaId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordenesState = ref.watch(ordenesProvider);

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipalOf(context),
        title: const Text('Gestión de Órdenes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar órdenes',
            onPressed: _cargarOrdenes,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Métricas Operativas Superiores (Tocar para Filtrar) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    titulo: 'Todas',
                    valor: '${ordenesState.todasLasOrdenes.length}',
                    color: AppColors.textoPrincipalOf(context),
                    isSelected: ordenesState.filtroEstado == null,
                    onTap: () => ref.read(ordenesProvider.notifier).setFiltroEstado(null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    titulo: 'Pendientes',
                    valor: '${ordenesState.pendientesCount}',
                    color: AppColors.rojoPrimario,
                    isSelected: ordenesState.filtroEstado == 'pendiente',
                    onTap: () => ref.read(ordenesProvider.notifier).setFiltroEstado('pendiente'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    titulo: 'En Progreso',
                    valor: '${ordenesState.enProgresoCount}',
                    color: AppColors.tertiary,
                    isSelected: ordenesState.filtroEstado == 'en_progreso',
                    onTap: () => ref.read(ordenesProvider.notifier).setFiltroEstado('en_progreso'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    titulo: 'Listas',
                    valor: '${ordenesState.listasCount}',
                    color: AppColors.isDark(context)
                        ? AppColors.estadoListoTexto
                        : AppColors.estadoListoTextoClaro,
                    isSelected: ordenesState.filtroEstado == 'listo',
                    onTap: () => ref.read(ordenesProvider.notifier).setFiltroEstado('listo'),
                  ),
                ),
              ],
            ),
          ),

          // ── Barra de Búsqueda ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(ordenesProvider.notifier).setBusqueda(val);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por N° orden, cliente, equipo...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(ordenesProvider.notifier).setBusqueda('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Lista de Órdenes ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _cargarOrdenes(),
              color: AppColors.rojoPrimario,
              backgroundColor: AppColors.fondoTarjetaOf(context),
              child: ordenesState.isLoading && ordenesState.todasLasOrdenes.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.rojoPrimario),
                    )
                  : ordenesState.ordenesFiltradas.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.fondoSuperficieOf(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.fondoBordeOf(context)),
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: AppColors.textoMutedOf(context),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _searchController.text.isNotEmpty ||
                                          ordenesState.filtroEstado != null
                                      ? 'No se encontraron órdenes con los filtros aplicados'
                                      : 'No hay órdenes registradas',
                                  style: TextStyle(
                                    color: AppColors.textoPrincipalOf(context),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Intenta cambiar los términos de búsqueda o el filtro.',
                                  style: TextStyle(
                                    color: AppColors.textoSecundarioOf(context),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: ordenesState.ordenesFiltradas.length,
                          itemBuilder: (context, index) {
                            final orden = ordenesState.ordenesFiltradas[index];
                            return OrdenCard(
                              orden: orden,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetalleOrdenScreen(ordenId: orden.id),
                                  ),
                                ).then((_) => _cargarOrdenes());
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String titulo,
    required String valor,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.15 : 0.1)
              : AppColors.fondoTarjetaOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.fondoBordeOf(context),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? color : AppColors.textoPrincipalOf(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textoSecundarioOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
