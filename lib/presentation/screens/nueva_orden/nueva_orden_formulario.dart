import 'package:flutter/material.dart';

import '../../../data/models/cliente_model.dart';
import '../../../data/models/servicio_catalogo_model.dart';

/// Estado del formulario de recepción, compartido por los tres pasos.
///
/// Vive en la pantalla contenedora, que es quien lo crea y lo libera. Los
/// pasos sólo leen y escriben aquí; no guardan estado propio, de modo que
/// nada se pierde al ir y volver entre pasos.
class NuevaOrdenFormulario {
  // ── Paso 1: Cliente ──
  final claveFormCliente = GlobalKey<FormState>();
  final dni = TextEditingController();
  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final telefono = TextEditingController();
  final email = TextEditingController();

  ClienteModel? clienteSeleccionado;
  bool buscandoDni = false;
  String? dniMensaje;
  bool dniMensajeEsExito = false;

  // ── Paso 2: Equipo ──
  final claveFormEquipo = GlobalKey<FormState>();
  String tipoEquipo = 'laptop';
  final marca = TextEditingController();
  final modelo = TextEditingController();
  final serie = TextEditingController();
  final desperfecto = TextEditingController();
  final descripcion = TextEditingController();
  final contrasena = TextEditingController();
  final accesorioPersonalizado = TextEditingController();

  static const List<String> accesoriosSugeridos = [
    'Cargador',
    'Mouse',
    'Mochila / Funda',
    'Cable de Poder',
    'Batería',
    'Memoria USB',
    'Teclado',
  ];
  final Set<String> accesorios = {};

  // ── Paso 3: Servicios y cobro ──
  final claveFormCobro = GlobalKey<FormState>();
  final List<ServicioCatalogoModel> servicios = [];
  String prioridad = 'normal';
  DateTime? fechaPrometida;
  final adelanto = TextEditingController();

  /// Con qué pagó el cliente el adelanto. Entra en la tabla de pagos como el
  /// primer cobro de la orden, así que tiene que ser el método real.
  String metodoAdelanto = 'efectivo';

  // ── Valores derivados ──
  double get totalServicios =>
      servicios.fold<double>(0, (suma, s) => suma + s.precioBase);

  double get montoAdelanto {
    final texto = adelanto.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return 0;
    final valor = double.tryParse(texto);
    if (valor == null || valor < 0) return 0;
    return valor;
  }

  double get saldoPendiente {
    final resto = totalServicios - montoAdelanto;
    return resto > 0 ? resto : 0;
  }

  String get nombreCompletoCliente {
    final partes = [nombre.text.trim(), apellido.text.trim()]
        .where((p) => p.isNotEmpty)
        .toList();
    return partes.isEmpty ? 'Sin nombre' : partes.join(' ');
  }

  String get resumenEquipo {
    final partes = [marca.text.trim(), modelo.text.trim()]
        .where((p) => p.isNotEmpty)
        .toList();
    return partes.isEmpty ? 'Equipo sin marca' : partes.join(' ');
  }

  void limpiar() {
    clienteSeleccionado = null;
    buscandoDni = false;
    dniMensaje = null;
    dniMensajeEsExito = false;
    tipoEquipo = 'laptop';
    prioridad = 'normal';
    metodoAdelanto = 'efectivo';
    fechaPrometida = null;
    accesorios.clear();
    servicios.clear();
    for (final c in _todosLosControladores) {
      c.clear();
    }
  }

  void dispose() {
    for (final c in _todosLosControladores) {
      c.dispose();
    }
  }

  List<TextEditingController> get _todosLosControladores => [
        dni,
        nombre,
        apellido,
        telefono,
        email,
        marca,
        modelo,
        serie,
        desperfecto,
        descripcion,
        contrasena,
        accesorioPersonalizado,
        adelanto,
      ];
}
