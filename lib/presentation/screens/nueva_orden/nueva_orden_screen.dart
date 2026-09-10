import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/orden_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/create_service_dialog.dart';
import '../../widgets/imprimir_stickers_dialog.dart';
import 'nueva_orden_formulario.dart';
import 'widgets/paso_cliente.dart';
import 'widgets/paso_equipo.dart';
import 'widgets/paso_servicios.dart';
import 'widgets/resumen_orden_sheet.dart';
import 'widgets/wizard_widgets.dart';

/// Recepción de un equipo, dividida en tres pasos cortos.
///
/// La pantalla sólo orquesta: guarda el estado del formulario, valida el paso
/// visible antes de dejar avanzar, y al final delega el guardado en los
/// repositorios. Cada paso vive en su propio archivo bajo `widgets/`.
class NuevaOrdenScreen extends ConsumerStatefulWidget {
  final VoidCallback onOrderCreated;

  const NuevaOrdenScreen({super.key, required this.onOrderCreated});

  @override
  ConsumerState<NuevaOrdenScreen> createState() => _NuevaOrdenScreenState();
}

class _NuevaOrdenScreenState extends ConsumerState<NuevaOrdenScreen> {
  static const List<String> _etiquetasPasos = ['Cliente', 'Equipo', 'Cobro'];

  final _datos = NuevaOrdenFormulario();
  final _scrollController = ScrollController();

  int _paso = 0;
  bool _guardando = false;

  @override
  void dispose() {
    _datos.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refrescar() => setState(() {});

  // ── Navegación entre pasos ──

  /// Clave del formulario que corresponde al paso visible.
  GlobalKey<FormState> get _claveFormActual {
    if (_paso == 0) return _datos.claveFormCliente;
    if (_paso == 1) return _datos.claveFormEquipo;
    return _datos.claveFormCobro;
  }

  bool _validarPasoActual() {
    final estado = _claveFormActual.currentState;
    if (estado == null) return true;
    if (estado.validate()) return true;

    _avisar('Revisa los campos marcados antes de continuar');
    return false;
  }

  void _irA(int paso) {
    setState(() => _paso = paso);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _avanzar() {
    if (!_validarPasoActual()) return;
    if (_paso < _etiquetasPasos.length - 1) {
      _irA(_paso + 1);
    } else {
      _revisarYRegistrar();
    }
  }

  void _retroceder() {
    if (_paso > 0) _irA(_paso - 1);
  }

  void _avisar(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? AppColors.errorOf(context) : null,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── Búsqueda de cliente por documento ──

  Future<void> _buscarDni(String dniIngresado) async {
    final dni = dniIngresado.replaceAll(RegExp(r'\D'), '').trim();
    if (dni.length != 8) {
      _avisar('El DNI debe tener exactamente 8 dígitos numéricos.');
      return;
    }

    setState(() {
      _datos.buscandoDni = true;
      _datos.dniMensaje = null;
    });

    final empresaId = ref.read(authProvider).tecnico?.empresaId;

    // 1. Cliente ya registrado en la base de la empresa.
    if (empresaId != null) {
      try {
        final existente =
            await ref.read(clienteRepositoryProvider).buscarClientePorDni(empresaId, dni);

        if (existente != null) {
          if (!mounted) return;
          setState(() {
            _datos.buscandoDni = false;
            _datos.clienteSeleccionado = existente;
            _datos.nombre.text = existente.nombre;
            _datos.apellido.text = existente.apellido ?? '';
            if (existente.telefono != null && existente.telefono!.isNotEmpty) {
              _datos.telefono.text = existente.telefono!;
            }
            if (existente.email != null && existente.email!.isNotEmpty) {
              _datos.email.text = existente.email!;
            }
            _datos.dniMensajeEsExito = true;
            _datos.dniMensaje = 'Cliente ya registrado: ${existente.nombreCompleto}';
          });
          return;
        }
      } catch (e) {
        debugPrint('Aviso: error buscando cliente en la base local: $e');
      }
    }

    // 2. Consulta a RENIEC a través de ApisPeru.
    final datosDni = await ref.read(dniServiceProvider).consultarDni(dni);
    if (!mounted) return;

    setState(() {
      _datos.buscandoDni = false;
      _datos.clienteSeleccionado = null;

      final nombres = datosDni?.nombres?.trim() ?? '';
      if (nombres.isNotEmpty) {
        _datos.nombre.text = nombres;
        _datos.apellido.text = datosDni!.apellidosCompletos;
        _datos.dniMensajeEsExito = true;
        _datos.dniMensaje =
            'Datos traídos de RENIEC: ${datosDni.nombreCompleto}. Falta el celular.';
      } else {
        _datos.dniMensajeEsExito = false;
        _datos.dniMensaje = 'DNI no encontrado en RENIEC. Escribe los datos a mano.';
      }
    });
  }

  // ── Catálogo de servicios ──

  void _abrirSelectorServicios() {
    final servicios = ref.read(catalogoProvider).todosLosServicios;
    final seleccion = _datos.servicios.map((s) => s.id).toSet();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarDialogo) {
          return AlertDialog(
            title: const Text(
              'Servicios del catálogo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: SizedBox(
              width: double.maxFinite,
              child: servicios.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                      child: Text(
                        'Todavía no hay servicios en el catálogo. Crea el primero desde el '
                        'botón de abajo.',
                        style: TextStyle(color: AppColors.textoSecundarioOf(ctx), fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: servicios.length,
                      itemBuilder: (_, i) {
                        final servicio = servicios[i];
                        return CheckboxListTile(
                          dense: true,
                          title: Text(
                            servicio.nombre,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${servicio.categoriaFormateada} · ${servicio.precioFormateado}',
                            style: TextStyle(
                              color: AppColors.textoSecundarioOf(ctx),
                              fontSize: 12,
                            ),
                          ),
                          value: seleccion.contains(servicio.id),
                          activeColor: AppColors.primarioOf(ctx),
                          onChanged: (marcado) {
                            actualizarDialogo(() {
                              if (marcado == true) {
                                seleccion.add(servicio.id);
                              } else {
                                seleccion.remove(servicio.id);
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
                  _crearServicioEnCaliente();
                },
                child: const Text('Nuevo servicio'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _datos.servicios
                      ..clear()
                      ..addAll(servicios.where((s) => seleccion.contains(s.id)));
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

  void _crearServicioEnCaliente() {
    final empresaId = ref.read(authProvider).tecnico?.empresaId;
    if (empresaId == null) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => CreateServiceDialog(
        onSave: (nuevo) async {
          final creado =
              await ref.read(catalogoProvider.notifier).agregarServicio(empresaId, nuevo);
          if (creado && mounted) _abrirSelectorServicios();
        },
      ),
    );
  }

  // ── Registro de la orden ──

  Future<void> _revisarYRegistrar() async {
    if (!_validarPasoActual()) return;

    // Los pasos anteriores ya no están montados, así que se revisan a mano.
    if (_datos.nombre.text.trim().isEmpty || _datos.telefono.text.trim().isEmpty) {
      _avisar('Faltan datos del cliente', esError: true);
      _irA(0);
      return;
    }
    if (_datos.marca.text.trim().isEmpty || _datos.desperfecto.text.trim().isEmpty) {
      _avisar('Faltan datos del equipo', esError: true);
      _irA(1);
      return;
    }

    final confirmado = await ResumenOrdenSheet.mostrar(context, _datos);
    if (confirmado && mounted) await _guardarOrden();
  }

  Future<void> _guardarOrden() async {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    final tecnicoId = auth.tecnico?.id;

    if (empresaId == null || tecnicoId == null) {
      _avisar('Tu sesión no tiene una empresa asignada', esError: true);
      return;
    }

    setState(() => _guardando = true);

    try {
      final datosOrden = <String, dynamic>{
        'empresa_id': empresaId,
        'tecnico_id': tecnicoId,
        'estado': 'pendiente',
        'prioridad': _datos.prioridad,
        'adelanto': _datos.montoAdelanto,
        'metodo_adelanto': _datos.metodoAdelanto,
        'descuento': 0.0,
        if (_datos.contrasena.text.trim().isNotEmpty)
          'contrasena_equipo': _datos.contrasena.text.trim(),
        if (_datos.fechaPrometida != null)
          'fecha_prometida': DateFormatter.fechaAFormatoIso(_datos.fechaPrometida!),
      };

      final datosEquipo = <String, dynamic>{
        'tipo': _datos.tipoEquipo,
        'marca': _datos.marca.text.trim(),
        if (_datos.modelo.text.trim().isNotEmpty) 'modelo': _datos.modelo.text.trim(),
        if (_datos.serie.text.trim().isNotEmpty) 'numero_serie': _datos.serie.text.trim(),
        'desperfecto': _datos.desperfecto.text.trim(),
        if (_datos.descripcion.text.trim().isNotEmpty)
          'descripcion_general': _datos.descripcion.text.trim(),
        if (_datos.accesorios.isNotEmpty) 'accesorios': _datos.accesorios.join(', '),
      };

      final orden = await ref.read(ordenRepositoryProvider).crearOrdenCompleta(
            datosCliente: _datosCliente(empresaId),
            datosOrden: datosOrden,
            datosEquipo: datosEquipo,
            servicios: _datos.servicios,
          );

      if (!mounted) return;
      setState(() {
        _datos.limpiar();
        _paso = 0;
      });
      _mostrarModalExito(orden);
    } catch (e) {
      if (mounted) _avisar('No se pudo guardar la orden: $e', esError: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Los datos del cliente tal como viajan a la función de base.
  ///
  /// Si lleva id, la función actualiza ese cliente; si no, lo crea. Va en la
  /// misma llamada que la orden a propósito: guardarlo antes por separado
  /// dejaba el cliente escrito aunque la orden fallara después.
  Map<String, dynamic> _datosCliente(int empresaId) {
    final apellido = _datos.apellido.text.trim();
    final telefono = _datos.telefono.text.trim();
    final email = _datos.email.text.trim();
    final dni = _datos.dni.text.trim();
    final existente = _datos.clienteSeleccionado;

    return {
      if (existente != null) 'id': existente.id,
      'empresa_id': empresaId,
      'nombre': _datos.nombre.text.trim(),
      if (apellido.isNotEmpty) 'apellido': apellido,
      if (dni.isNotEmpty) 'dni': dni,
      if (telefono.isNotEmpty) 'telefono': telefono,
      if (email.isNotEmpty) 'email': email,
    };
  }

  void _mostrarModalExito(OrdenModel orden) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.exitoOf(ctx).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.exitoOf(ctx).withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.check_rounded, color: AppColors.exitoOf(ctx), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Orden ${orden.codigoVisual} registrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipalOf(ctx),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${orden.clienteNombreCompleto}\n${orden.equipo?.nombreCompleto ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textoSecundarioOf(ctx)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showDialog<void>(
                    context: context,
                    builder: (_) => ImprimirStickersDialog(orden: orden),
                  );
                },
                icon: const Icon(Icons.bluetooth_audio_rounded, size: 18),
                label: const Text('Imprimir stickers de accesorios'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      PdfInvoiceService.imprimirOCompartir(orden);
                    },
                    icon: const Icon(Icons.print_outlined, size: 17),
                    label: const Text('Imprimir A4', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      PdfInvoiceService.compartirCopiaCliente(orden);
                    },
                    icon: const Icon(Icons.send_outlined, size: 17),
                    label: const Text('Enviar copia', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onOrderCreated();
              },
              child: const Text('Ir a la lista de órdenes'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Construcción ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      appBar: AppBar(
        title: const Text('Nueva orden'),
        actions: [
          TextButton(
            onPressed: _guardando
                ? null
                : () {
                    setState(() {
                      _datos.limpiar();
                      _paso = 0;
                    });
                    _avisar('Formulario vaciado');
                  },
            child: const Text('Limpiar'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: BarraPasos(
              pasoActual: _paso,
              etiquetas: _etiquetasPasos,
              onTocarPaso: _guardando ? null : _irA,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _construirPaso(),
        ),
      ),
      bottomNavigationBar: _construirBarraAcciones(),
    );
  }

  Widget _construirPaso() {
    if (_paso == 0) {
      return PasoCliente(
        datos: _datos,
        onBuscarDni: _buscarDni,
        onCambio: _refrescar,
      );
    }
    if (_paso == 1) {
      return PasoEquipo(datos: _datos, onCambio: _refrescar);
    }
    return PasoServicios(
      datos: _datos,
      onAbrirCatalogo: _abrirSelectorServicios,
      onCambio: _refrescar,
    );
  }

  Widget _construirBarraAcciones() {
    final esUltimo = _paso == _etiquetasPasos.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        border: Border(top: BorderSide(color: AppColors.fondoBordeOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (_paso > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _guardando ? null : _retroceder,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Atrás'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _avanzar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            esUltimo
                                ? Icons.fact_check_outlined
                                : Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                    label: Text(
                      _guardando
                          ? 'Guardando...'
                          : esUltimo
                              ? 'Revisar y registrar'
                              : 'Continuar',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
