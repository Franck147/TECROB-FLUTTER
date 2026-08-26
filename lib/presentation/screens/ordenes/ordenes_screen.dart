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
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: const Text('Órdenes de Servicio'),
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
          // ── Barra de Búsqueda ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

          // ── Chips de Filtro por Estado con Contadores ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Todas',
                  count: ordenesState.todasLasOrdenes.length,
                  isSelected: ordenesState.filtroEstado == null,
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Pendientes',
                  count: ordenesState.pendientesCount,
                  isSelected: ordenesState.filtroEstado == 'pendiente',
                  activeColor: AppColors.rojoPrimario,
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado('pendiente'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'En progreso',
                  count: ordenesState.enProgresoCount,
                  isSelected: ordenesState.filtroEstado == 'en_progreso',
                  activeColor: AppColors.tertiary,
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado('en_progreso'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Listas',
                  count: ordenesState.listasCount,
                  isSelected: ordenesState.filtroEstado == 'listo',
                  activeColor: AppColors.estadoListoTexto,
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado('listo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Lista de Órdenes ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _cargarOrdenes(),
              color: AppColors.rojoPrimario,
              backgroundColor: AppColors.fondoTarjeta,
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
                                    color: AppColors.fondoSuperficie,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.fondoBorde),
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: AppColors.textoMuted,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _searchController.text.isNotEmpty ||
                                          ordenesState.filtroEstado != null
                                      ? 'No se encontraron órdenes con los filtros aplicados'
                                      : 'No hay órdenes registradas',
                                  style: const TextStyle(
                                    color: AppColors.textoPrincipal,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Intenta cambiar los términos de búsqueda o el filtro.',
                                  style: TextStyle(
                                    color: AppColors.textoSecundario,
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

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onSelected,
    Color activeColor = AppColors.rojoPrimario,
  }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.3)
                  : AppColors.fondoBorde,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : AppColors.textoSecundario,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
