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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _cargarOrdenes,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de Búsqueda ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(ordenesProvider.notifier).setBusqueda(val);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por N° orden, cliente, equipo...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
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
                  label: 'Todas (${ordenesState.todasLasOrdenes.length})',
                  isSelected: ordenesState.filtroEstado == null,
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Pendientes (${ordenesState.pendientesCount})',
                  isSelected: ordenesState.filtroEstado == 'pendiente',
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado('pendiente'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'En progreso (${ordenesState.enProgresoCount})',
                  isSelected: ordenesState.filtroEstado == 'en_progreso',
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado('en_progreso'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Listas (${ordenesState.listasCount})',
                  isSelected: ordenesState.filtroEstado == 'listo',
                  onSelected: () =>
                      ref.read(ordenesProvider.notifier).setFiltroEstado('listo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Lista de Órdenes ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _cargarOrdenes(),
              color: AppColors.rojoPrimario,
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
                                const Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: AppColors.textoMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isNotEmpty ||
                                          ordenesState.filtroEstado != null
                                      ? 'No se encontraron órdenes con ese filtro'
                                      : 'No hay órdenes registradas',
                                  style: const TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 14,
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
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
