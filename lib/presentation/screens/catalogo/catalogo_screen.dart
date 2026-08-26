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

  void _confirmarEliminar(ServicioCatalogoModel serv) {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoTarjetaOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.fondoBordeOf(context)),
        ),
        title: const Text('Eliminar Servicio'),
        content: Text('¿Estás seguro de que deseas eliminar "${serv.nombre}" del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundarioOf(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(catalogoProvider.notifier).eliminarServicio(serv.id, empresaId);
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
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipalOf(context),
        title: const Text('Catálogo de Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar catálogo',
            onPressed: _cargarServicios,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoServicio(),
        backgroundColor: AppColors.rojoPrimario,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(catalogoProvider.notifier).setBusqueda(val),
              decoration: InputDecoration(
                hintText: 'Buscar servicio o repuesto...',
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

          // Filtros de Categoría
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
              backgroundColor: AppColors.fondoTarjetaOf(context),
              child: catalogoState.isLoading && catalogoState.todosLosServicios.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.rojoPrimario))
                  : catalogoState.serviciosFiltrados.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron servicios',
                            style: TextStyle(color: AppColors.textoSecundarioOf(context)),
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
                                color: AppColors.fondoTarjetaOf(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.fondoBordeOf(context)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.rojoContenedorOf(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.handyman_rounded,
                                    color: isDark ? AppColors.rojoClaro : AppColors.rojoPrimario,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  serv.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textoPrincipalOf(context),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (serv.descripcion != null && serv.descripcion!.isNotEmpty)
                                      Text(
                                        serv.descripcion!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textoMutedOf(context),
                                        ),
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
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.rojoClaro : AppColors.rojoOscuro,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        size: 18,
                                        color: AppColors.textoSecundarioOf(context),
                                      ),
                                      color: AppColors.fondoTarjetaOf(context),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: AppColors.fondoBordeOf(context)),
                                      ),
                                      onSelected: (val) {
                                        if (val == 'edit') _abrirDialogoServicio(serv);
                                        if (val == 'delete') _confirmarEliminar(serv);
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, size: 16, color: AppColors.textoPrincipalOf(context)),
                                              const SizedBox(width: 8),
                                              const Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
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
