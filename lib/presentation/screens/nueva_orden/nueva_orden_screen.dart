import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/models/servicio_catalogo_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/create_service_dialog.dart';
import '../../widgets/custom_text_field.dart';

class NuevaOrdenScreen extends ConsumerStatefulWidget {
  final VoidCallback onOrderCreated;

  const NuevaOrdenScreen({super.key, required this.onOrderCreated});

  @override
  ConsumerState<NuevaOrdenScreen> createState() => _NuevaOrdenScreenState();
}

class _NuevaOrdenScreenState extends ConsumerState<NuevaOrdenScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controladores Cliente ──
  final _dniController = TextEditingController();
  final _nombreClienteController = TextEditingController();
  final _apellidoClienteController = TextEditingController();
  final _telefonoClienteController = TextEditingController();
  final _emailClienteController = TextEditingController();

  ClienteModel? _clienteSeleccionado;
  bool _buscandoDni = false;
  bool _mostrarFormNuevoCliente = false;

  // ── Controladores Equipo ──
  String _tipoEquipo = 'laptop';
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _serieController = TextEditingController();
  final _desperfectoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _contrasenaController = TextEditingController();

  final List<String> _accesoriosDisponibles = [
    'Funda', 'Mouse', 'Cargador', 'Mochila', 'Cable datos', 'Estabilizador'
  ];
  final Set<String> _accesoriosSeleccionados = {};

  // ── Controladores Orden & Servicios ──
  String _prioridad = 'normal';
  DateTime? _fechaPrometida;
  final List<ServicioCatalogoModel> _serviciosSeleccionados = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.tecnico?.empresaId != null) {
        ref.read(catalogoProvider.notifier).cargarServicios(auth.tecnico!.empresaId!);
      }
    });
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombreClienteController.dispose();
    _apellidoClienteController.dispose();
    _telefonoClienteController.dispose();
    _emailClienteController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _serieController.dispose();
    _desperfectoController.dispose();
    _descripcionController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  double get _subtotalCalculado {
    double sum = 0.0;
    for (var s in _serviciosSeleccionados) {
      sum += s.precioBase;
    }
    return sum;
  }

  Future<void> _buscarDni(String dni) async {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null || dni.length != 8) return;

    setState(() {
      _buscandoDni = true;
      _clienteSeleccionado = null;
      _mostrarFormNuevoCliente = false;
    });

    // 1. Buscar en BD local de Supabase
    final clienteRepo = ref.read(clienteRepositoryProvider);
    final clienteExistente = await clienteRepo.buscarClientePorDni(empresaId, dni);

    if (clienteExistente != null) {
      setState(() {
        _clienteSeleccionado = clienteExistente;
        _buscandoDni = false;
      });
      return;
    }

    // 2. Si no existe, consultar a la API de RENIEC (ApisPeru)
    final dniService = ref.read(dniServiceProvider);
    final datosDni = await dniService.consultarDni(dni);

    setState(() {
      _buscandoDni = false;
      _mostrarFormNuevoCliente = true;
      if (datosDni != null) {
        _nombreClienteController.text = datosDni.nombres ?? '';
        _apellidoClienteController.text = datosDni.apellidosCompletos;
      } else {
        _nombreClienteController.clear();
        _apellidoClienteController.clear();
      }
    });
  }

  Future<void> _registrarClienteRapido() async {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null) return;

    if (_nombreClienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre del cliente')),
      );
      return;
    }

    try {
      final nuevo = await ref.read(clienteRepositoryProvider).crearCliente({
        'empresa_id': empresaId,
        'nombre': _nombreClienteController.text.trim(),
        'apellido': _apellidoClienteController.text.trim().isNotEmpty
            ? _apellidoClienteController.text.trim()
            : null,
        'dni': _dniController.text.trim(),
        'telefono': _telefonoClienteController.text.trim().isNotEmpty
            ? _telefonoClienteController.text.trim()
            : null,
        'email': _emailClienteController.text.trim().isNotEmpty
            ? _emailClienteController.text.trim()
            : null,
      });

      setState(() {
        _clienteSeleccionado = nuevo;
        _mostrarFormNuevoCliente = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar cliente: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _abrirSelectorServicios() {
    final catalogoState = ref.read(catalogoProvider);
    final todos = catalogoState.todosLosServicios;
    final seleccionTemp = Set<int>.from(_serviciosSeleccionados.map((s) => s.id));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Seleccionar Servicios', style: TextStyle(fontSize: 18)),
            content: SizedBox(
              width: double.maxFinite,
              child: todos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay servicios en el catálogo'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final serv = todos[index];
                        final isChecked = seleccionTemp.contains(serv.id);
                        return CheckboxListTile(
                          title: Text(serv.nombre, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            serv.precioFormateado,
                            style: const TextStyle(color: AppColors.rojoClaro, fontSize: 12),
                          ),
                          value: isChecked,
                          activeColor: AppColors.rojoPrimario,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                seleccionTemp.add(serv.id);
                              } else {
                                seleccionTemp.remove(serv.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _crearNuevoServicioEnCaliente();
                },
                child: const Text('Nuevo Servicio'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _serviciosSeleccionados.clear();
                    for (var s in todos) {
                      if (seleccionTemp.contains(s.id)) {
                        _serviciosSeleccionados.add(s);
                      }
                    }
                  });
                  Navigator.of(ctx).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _crearNuevoServicioEnCaliente() {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => CreateServiceDialog(
        onSave: (datos) async {
          final ok = await ref.read(catalogoProvider.notifier).agregarServicio(empresaId, datos);
          if (ok) {
            _abrirSelectorServicios();
          }
        },
      ),
    );
  }

  Future<void> _guardarOrden() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar o registrar un cliente')),
      );
      return;
    }

    if (_marcaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la marca del equipo')),
      );
      return;
    }

    if (_desperfectoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el desperfecto del equipo')),
      );
      return;
    }

    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    final tecnicoId = auth.tecnico?.id;

    if (empresaId == null || tecnicoId == null) return;

    setState(() => _guardando = true);

    try {
      final datosOrden = {
        'empresa_id': empresaId,
        'cliente_id': _clienteSeleccionado!.id,
        'tecnico_id': tecnicoId,
        'estado': 'pendiente',
        'prioridad': _prioridad,
        'adelanto': 0.0,
        'descuento': 0.0,
        if (_contrasenaController.text.trim().isNotEmpty)
          'contrasena_equipo': _contrasenaController.text.trim(),
        if (_fechaPrometida != null)
          'fecha_prometida': DateFormatter.fechaAFormatoIso(_fechaPrometida!),
      };

      final datosEquipo = {
        'tipo': _tipoEquipo,
        'marca': _marcaController.text.trim(),
        if (_modeloController.text.trim().isNotEmpty)
          'modelo': _modeloController.text.trim(),
        if (_serieController.text.trim().isNotEmpty)
          'numero_serie': _serieController.text.trim(),
        'desperfecto': _desperfectoController.text.trim(),
        if (_descripcionController.text.trim().isNotEmpty)
          'descripcion_general': _descripcionController.text.trim(),
        if (_accesoriosSeleccionados.isNotEmpty)
          'accesorios': _accesoriosSeleccionados.join(', '),
      };

      await ref.read(ordenRepositoryProvider).crearOrdenCompleta(
            empresaId: empresaId,
            tecnicoId: tecnicoId,
            datosOrden: datosOrden,
            datosEquipo: datosEquipo,
            servicios: _serviciosSeleccionados,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Orden guardada exitosamente!'),
            backgroundColor: AppColors.tertiary,
          ),
        );
        _limpiarFormulario();
        widget.onOrderCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar orden: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _clienteSeleccionado = null;
      _dniController.clear();
      _nombreClienteController.clear();
      _apellidoClienteController.clear();
      _telefonoClienteController.clear();
      _emailClienteController.clear();
      _mostrarFormNuevoCliente = false;
      _marcaController.clear();
      _modeloController.clear();
      _serieController.clear();
      _desperfectoController.clear();
      _descripcionController.clear();
      _contrasenaController.clear();
      _tipoEquipo = 'laptop';
      _prioridad = 'normal';
      _fechaPrometida = null;
      _accesoriosSeleccionados.clear();
      _serviciosSeleccionados.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        title: const Text('Nueva Orden de Servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. SECCIÓN CLIENTE ──
              _buildSectionCard(
                titulo: '1. DATOS DEL CLIENTE',
                icono: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_clienteSeleccionado != null) ...[
                      // Cliente ya seleccionado
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.fondoSuperficie,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.tertiary, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _clienteSeleccionado!.nombreCompleto,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'DNI: ${_clienteSeleccionado!.dni ?? "—"} • Tel: ${_clienteSeleccionado!.telefono ?? "—"}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _clienteSeleccionado = null;
                                  _dniController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Buscador de DNI
                      CustomTextField(
                        controller: _dniController,
                        label: 'DNI del Cliente (8 dígitos)',
                        hint: 'Ingresa DNI para buscar o registrar...',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.badge_outlined,
                        onChanged: (val) {
                          if (val.trim().length == 8) {
                            _buscarDni(val.trim());
                          }
                        },
                      ),
                      if (_buscandoDni)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rojoPrimario),
                            ),
                          ),
                        ),

                      if (_mostrarFormNuevoCliente) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.fondoSuperficie,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.fondoBorde),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registrar Nuevo Cliente',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              CustomTextField(
                                controller: _nombreClienteController,
                                label: 'Nombres *',
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _apellidoClienteController,
                                label: 'Apellidos',
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _telefonoClienteController,
                                label: 'Teléfono / Celular',
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _registrarClienteRapido,
                                child: const Text('Confirmar y Usar Cliente'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 2. SECCIÓN EQUIPO ──
              _buildSectionCard(
                titulo: '2. DATOS DEL EQUIPO',
                icono: Icons.devices_other,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Equipo:', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['laptop', 'computadora', 'impresora', 'tablet', 'celular', 'otro'].map((tipo) {
                        return ChoiceChip(
                          label: Text(tipo.toUpperCase()),
                          selected: _tipoEquipo == tipo,
                          onSelected: (selected) {
                            if (selected) setState(() => _tipoEquipo = tipo);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _marcaController,
                            label: 'Marca *',
                            hint: 'Ej. HP, Dell...',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            controller: _modeloController,
                            label: 'Modelo',
                            hint: 'Ej. Pavilion...',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _serieController,
                            label: 'N° de Serie',
                            hint: 'Opcional',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            controller: _contrasenaController,
                            label: 'Contraseña Equipo',
                            hint: 'PIN o clave',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _desperfectoController,
                      label: 'Problema / Falla Reportada *',
                      hint: 'Describe lo que reporta el cliente...',
                      textCapitalization: TextCapitalization.characters,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    const Text('Accesorios Entregados:', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _accesoriosDisponibles.map((acc) {
                        final isSel = _accesoriosSeleccionados.contains(acc);
                        return FilterChip(
                          label: Text(acc),
                          selected: isSel,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _accesoriosSeleccionados.add(acc);
                              } else {
                                _accesoriosSeleccionados.remove(acc);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 3. SERVICIOS Y COSTOS ──
              _buildSectionCard(
                titulo: '3. SERVICIOS Y ENTREGA',
                icono: Icons.build_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prioridad
                    const Text('Prioridad:', style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: ['baja', 'normal', 'alta', 'urgente'].map((prio) {
                        return ChoiceChip(
                          label: Text(prio.toUpperCase()),
                          selected: _prioridad == prio,
                          onSelected: (selected) {
                            if (selected) setState(() => _prioridad = prio);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Fecha Prometida
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha prometida de entrega:'),
                      subtitle: Text(
                        _fechaPrometida != null
                            ? DateFormatter.fechaAFormatoIso(_fechaPrometida!)
                            : 'No seleccionada (opcional)',
                        style: const TextStyle(color: AppColors.rojoClaro),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: AppColors.rojoPrimario),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 2)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _fechaPrometida = date);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // Botón para seleccionar servicios
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar Servicios del Catálogo'),
                      onPressed: _abrirSelectorServicios,
                    ),
                    const SizedBox(height: 8),

                    // Lista de servicios agregados
                    if (_serviciosSeleccionados.isNotEmpty) ...[
                      ..._serviciosSeleccionados.map((s) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.nombre, style: const TextStyle(fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.precioFormateado, style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.textoMuted),
                                onPressed: () {
                                  setState(() => _serviciosSeleccionados.remove(s));
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: AppColors.fondoBorde),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal Estimado:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.format(_subtotalCalculado),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.rojoClaro),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Botón Guardar Orden ──
              ElevatedButton(
                onPressed: _guardando ? null : _guardarOrden,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR ORDEN DE SERVICIO'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String titulo,
    required IconData icono,
    required Widget child,
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
            children: [
              Icon(icono, size: 18, color: AppColors.rojoPrimario),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
