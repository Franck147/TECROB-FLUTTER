import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_helper.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/models/servicio_catalogo_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/create_service_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/imprimir_stickers_dialog.dart';

class NuevaOrdenScreen extends ConsumerStatefulWidget {
  final VoidCallback onOrderCreated;

  const NuevaOrdenScreen({super.key, required this.onOrderCreated});

  @override
  ConsumerState<NuevaOrdenScreen> createState() => _NuevaOrdenScreenState();
}

class _NuevaOrdenScreenState extends ConsumerState<NuevaOrdenScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores Cliente
  final _dniController = TextEditingController();
  final _nombreClienteController = TextEditingController();
  final _apellidoClienteController = TextEditingController();
  final _telefonoClienteController = TextEditingController();
  final _emailClienteController = TextEditingController();

  ClienteModel? _clienteSeleccionado;
  bool _buscandoDni = false;
  bool _mostrarFormNuevoCliente = false;
  String? _dniMensajeEstado;

  // Controladores Equipo
  String _tipoEquipo = 'laptop';
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _serieController = TextEditingController();
  final _desperfectoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _accesorioPersonalizadoController = TextEditingController();

  // Accesorios
  final List<String> _accesoriosDisponibles = [
    'Cargador',
    'Mouse',
    'Mochila / Funda',
    'Cable de Poder',
    'Batería',
    'Memoria USB',
    'Teclado',
  ];
  final Set<String> _accesoriosSeleccionados = {};

  // Servicios
  final List<ServicioCatalogoModel> _serviciosSeleccionados = [];

  // Parámetros Orden
  String _prioridad = 'normal';
  DateTime? _fechaPrometida;
  final _adelantoController = TextEditingController();

  bool _guardando = false;

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
    _accesorioPersonalizadoController.dispose();
    _adelantoController.dispose();
    super.dispose();
  }

  Future<void> _buscarDni(String dniInput) async {
    final dni = dniInput.replaceAll(RegExp(r'\D'), '').trim();
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null || dni.length != 8) return;

    setState(() {
      _buscandoDni = true;
      _clienteSeleccionado = null;
      _mostrarFormNuevoCliente = false;
      _dniMensajeEstado = null;
    });

    // 1. Buscar en BD local de Supabase de la empresa
    final clienteRepo = ref.read(clienteRepositoryProvider);
    final clienteExistente = await clienteRepo.buscarClientePorDni(empresaId, dni);

    if (clienteExistente != null) {
      setState(() {
        _clienteSeleccionado = clienteExistente;
        _buscandoDni = false;
        _dniMensajeEstado = '✓ Cliente encontrado en la base de datos';
      });
      return;
    }

    // 2. Consultar a la API de RENIEC con fallback multi-proveedor
    final dniService = ref.read(dniServiceProvider);
    final datosDni = await dniService.consultarDni(dni);

    setState(() {
      _buscandoDni = false;
      _mostrarFormNuevoCliente = true;
      if (datosDni != null && datosDni.nombres != null && datosDni.nombres!.isNotEmpty) {
        _nombreClienteController.text = datosDni.nombres ?? '';
        _apellidoClienteController.text = datosDni.apellidosCompletos;
        _dniMensajeEstado = '✓ Datos obtenidos de RENIEC: ${datosDni.nombreCompleto}';
      } else {
        _nombreClienteController.clear();
        _apellidoClienteController.clear();
        _dniMensajeEstado = 'ℹ️ DNI no encontrado en RENIEC. Ingrésalo manualmente.';
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
          SnackBar(
            content: Text('Error al registrar cliente: $e'),
            backgroundColor: AppColors.error,
          ),
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
            backgroundColor: AppColors.fondoTarjeta,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.fondoBorde),
            ),
            title: const Text('Seleccionar Servicios del Catálogo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: todos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay servicios en el catálogo',
                          style: TextStyle(color: AppColors.textoSecundario)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final serv = todos[index];
                        final isChecked = seleccionTemp.contains(serv.id);
                        return CheckboxListTile(
                          title: Text(serv.nombre,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                child: const Text('Cancelar', style: TextStyle(color: AppColors.textoSecundario)),
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
      final adelantoVal = double.tryParse(_adelantoController.text.trim()) ?? 0.0;

      final datosOrden = {
        'empresa_id': empresaId,
        'cliente_id': _clienteSeleccionado!.id,
        'tecnico_id': tecnicoId,
        'estado': 'pendiente',
        'prioridad': _prioridad,
        'adelanto': adelantoVal,
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

      final ordenCreada = await ref.read(ordenRepositoryProvider).crearOrdenCompleta(
            empresaId: empresaId,
            tecnicoId: tecnicoId,
            datosOrden: datosOrden,
            datosEquipo: datosEquipo,
            servicios: _serviciosSeleccionados,
          );

      if (mounted) {
        _limpiarFormulario();
        _mostrarModalExito(ordenCreada);
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

  void _mostrarModalExito(dynamic orden) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoTarjetaOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.fondoBordeOf(context), width: 1.2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.tertiary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Orden ${orden.codigoVisual} Registrada!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrincipalOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Cliente: ${orden.clienteNombreCompleto}\n${orden.equipo?.nombreCompleto ?? ""}',
              style: TextStyle(fontSize: 12.5, color: AppColors.textoSecundarioOf(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Botón 1: Stickers Bluetooth
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showDialog(
                    context: context,
                    builder: (_) => ImprimirStickersDialog(orden: orden),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rojoPrimario,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.bluetooth_audio_rounded, size: 18),
                label: const Text(
                  '🏷️ Imprimir Stickers de Accesorios',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Botón 2: Comprobante PDF
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  PdfInvoiceService.imprimirOCompartir(orden);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.fondoBorde),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.rojoClaro),
                label: const Text(
                  '📄 Comprobante PDF de Recepción',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Botón 3: Ir a lista
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onOrderCreated();
              },
              child: const Text('Continuar a la lista de órdenes',
                  style: TextStyle(color: AppColors.textoSecundario, fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
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
      _dniMensajeEstado = null;
      _marcaController.clear();
      _modeloController.clear();
      _serieController.clear();
      _desperfectoController.clear();
      _descripcionController.clear();
      _contrasenaController.clear();
      _accesorioPersonalizadoController.clear();
      _adelantoController.clear();
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
      backgroundColor: AppColors.fondoPrincipalOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipalOf(context),
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
                icono: Icons.person_search_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_clienteSeleccionado != null) ...[
                      // Cliente ya seleccionado
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.fondoSuperficieOf(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.tertiaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: AppColors.tertiary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _clienteSeleccionado!.nombreCompleto,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                  Text(
                                    'DNI: ${_clienteSeleccionado!.dni ?? "—"} • Tel: ${_clienteSeleccionado!.telefono ?? "—"}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textoSecundario),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                setState(() {
                                  _clienteSeleccionado = null;
                                  _dniController.clear();
                                  _dniMensajeEstado = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Buscador de DNI con Botón de Búsqueda
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _dniController,
                              label: 'DNI del Cliente (8 dígitos)',
                              hint: 'Ingresa DNI para autocompletar...',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.badge_outlined,
                              onChanged: (val) {
                                if (val.trim().length == 8) {
                                  _buscarDni(val.trim());
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _buscandoDni
                                  ? null
                                  : () => _buscarDni(_dniController.text.trim()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.rojoContenedor,
                                foregroundColor: AppColors.rojoClaro,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: AppColors.rojoPrimario.withValues(alpha: 0.3),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: _buscandoDni
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.rojoClaro,
                                      ),
                                    )
                                  : const Icon(Icons.search_rounded, size: 22),
                            ),
                          ),
                        ],
                      ),

                      if (_dniMensajeEstado != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            _dniMensajeEstado!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _dniMensajeEstado!.startsWith('✓')
                                  ? AppColors.tertiary
                                  : AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      if (_mostrarFormNuevoCliente) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.fondoSuperficie,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.fondoBorde),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registrar Nuevo Cliente',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.textoPrincipal,
                                ),
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
                                label: 'Teléfono / Celular WhatsApp',
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_android_rounded,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _registrarClienteRapido,
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                  label: const Text('Confirmar y Asignar Cliente'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 2. SECCIÓN EQUIPO ──
              _buildSectionCard(
                titulo: '2. DATOS DEL EQUIPO',
                icono: Icons.devices_other_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Equipo:',
                        style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: ['laptop', 'computadora', 'impresora', 'tablet', 'celular', 'otro']
                          .map((tipo) {
                        final isSel = _tipoEquipo == tipo;
                        return ChoiceChip(
                          avatar: Icon(
                            StatusHelper.obtenerIconoEquipo(tipo),
                            size: 16,
                            color: isSel ? AppColors.rojoClaro : AppColors.textoSecundario,
                          ),
                          label: Text(tipo.toUpperCase()),
                          selected: isSel,
                          onSelected: (selected) {
                            if (selected) setState(() => _tipoEquipo = tipo);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _marcaController,
                            label: 'Marca *',
                            hint: 'Ej. Lenovo, HP, Dell...',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            controller: _modeloController,
                            label: 'Modelo',
                            hint: 'Ej. ThinkPad E14...',
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
                            label: 'PIN / Clave',
                            hint: 'Contraseña de equipo',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _desperfectoController,
                      label: 'Problema / Falla Reportada *',
                      hint: 'Describe la falla que reporta el cliente...',
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // Accesorios con rotulado
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Accesorios Entregados (Se generará sticker para c/u):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _accesorioPersonalizadoController,
                            label: 'Otro accesorio...',
                            hint: 'Ej. Funda cuero, Cable HDMI...',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final custom = _accesorioPersonalizadoController.text.trim();
                            if (custom.isNotEmpty) {
                              setState(() {
                                _accesoriosSeleccionados.add(custom);
                                _accesorioPersonalizadoController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.fondoSuperficie,
                            foregroundColor: AppColors.textoPrincipal,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 3. SECCIÓN SERVICIOS & PARÁMETROS ──
              _buildSectionCard(
                titulo: '3. SERVICIOS Y RECEPCIÓN',
                icono: Icons.build_circle_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Servicios agregados:',
                          style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                        ),
                        TextButton.icon(
                          onPressed: _abrirSelectorServicios,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Catálogo'),
                        ),
                      ],
                    ),
                    if (_serviciosSeleccionados.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.fondoSuperficie,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.fondoBorde),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textoMuted),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Puedes añadir servicios ahora o después durante el diagnóstico.',
                                style: TextStyle(fontSize: 12, color: AppColors.textoMuted),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._serviciosSeleccionados.map(
                        (serv) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.fondoSuperficie,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(serv.nombre, style: const TextStyle(fontSize: 13)),
                              Row(
                                children: [
                                  Text(serv.precioFormateado,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.rojoClaro)),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16, color: AppColors.textoMuted),
                                    onPressed: () {
                                      setState(() => _serviciosSeleccionados.remove(serv));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prioridad:',
                                  style: TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _prioridad,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'baja', child: Text('Baja')),
                                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                                  DropdownMenuItem(value: 'alta', child: Text('Alta (Urgente)')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _prioridad = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: _adelantoController,
                            label: 'Adelanto S/',
                            hint: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.attach_money_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botón Guardar Orden
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardarOrden,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rojoPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 22),
                  label: Text(
                    _guardando ? 'Guardando Orden...' : 'REGISTRAR ORDEN DE SERVICIO',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: AppColors.rojoPrimario, size: 18),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textoPrincipalOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
