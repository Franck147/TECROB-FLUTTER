import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/servicio_catalogo_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/create_service_dialog.dart';

class CatalogoScreen extends ConsumerStatefulWidget {
  const CatalogoScreen({super.key});

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, String>> _categorias = [
    {'id': 'mantenimiento', 'label': 'Mantenimiento'},
    {'id': 'reparacion', 'label': 'Reparación'},
    {'id': 'software', 'label': 'Software'},
    {'id': 'repuesto', 'label': 'Repuesto'},
    {'id': 'diagnostico', 'label': 'Diagnóstico'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarServicios();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarServicios() {
    final auth = ref.read(authProvider);
    if (auth.tecnico?.empresaId != null) {
      ref.read(catalogoProvider.notifier).cargarServicios(auth.tecnico!.empresaId!);
    }
  }

  void _abrirDialogoServicio([ServicioCatalogoModel? servicio]) {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => CreateServiceDialog(
        servicioExistente: servicio,
        onSave: (datos) async {
          if (servicio != null) {
            await ref.read(catalogoProvider.notifier).actualizarServicio(servicio.id, empresaId, datos);
          } else {
            await ref.read(catalogoProvider.notifier).agregarServicio(empresaId, datos);
          }
        },
      ),
    );
  }

  void _confirmarEliminar(ServicioCatalogoModel servicio) {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoTarjeta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.fondoBorde),
        ),
        title: const Text('Eliminar Servicio'),
        content: Text('¿Estás seguro de eliminar "${servicio.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(catalogoProvider.notifier).eliminarServicio(servicio.id, empresaId);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogoState = ref.watch(catalogoProvider);

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: const Text('Catálogo de Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nuevo Servicio',
            onPressed: () => _abrirDialogoServicio(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(catalogoProvider.notifier).setBusqueda(val);
              },
              decoration: InputDecoration(
                hintText: 'Buscar servicios o repuestos...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(catalogoProvider.notifier).setBusqueda('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Chips de Categorías
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: catalogoState.categoriaFiltro == null,
                  onSelected: (_) => ref.read(catalogoProvider.notifier).setCategoria(null),
                ),
                const SizedBox(width: 8),
                ..._categorias.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat['label']!),
                      selected: catalogoState.categoriaFiltro == cat['id'],
                      onSelected: (_) => ref.read(catalogoProvider.notifier).setCategoria(cat['id']),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Lista de Servicios
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _cargarServicios(),
              color: AppColors.rojoPrimario,
              backgroundColor: AppColors.fondoTarjeta,
              child: catalogoState.isLoading && catalogoState.todosLosServicios.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.rojoPrimario))
                  : catalogoState.serviciosFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron servicios',
                            style: TextStyle(color: AppColors.textoSecundario),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: catalogoState.serviciosFiltrados.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final serv = catalogoState.serviciosFiltrados[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.fondoTarjeta,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.fondoBorde),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.rojoContenedor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.handyman_rounded,
                                      color: AppColors.rojoClaro, size: 18),
                                ),
                                title: Text(
                                  serv.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (serv.descripcion != null && serv.descripcion!.isNotEmpty)
                                      Text(
                                        serv.descripcion!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textoMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text(
                                      serv.categoriaFormateada,
                                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      serv.precioFormateado,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.rojoClaro,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                                      color: AppColors.fondoSuperficie,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(color: AppColors.fondoBorde),
                                      ),
                                      onSelected: (val) {
                                        if (val == 'edit') _abrirDialogoServicio(serv);
                                        if (val == 'delete') _confirmarEliminar(serv);
                                      },
                                      itemBuilder: (ctx) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, size: 16, color: AppColors.textoPrincipal),
                                              SizedBox(width: 8),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                              SizedBox(width: 8),
                                              Text('Eliminar', style: TextStyle(color: AppColors.error)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
