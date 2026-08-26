import '../../core/utils/currency_formatter.dart';
import '../../core/utils/status_helper.dart';
import 'cliente_model.dart';
import 'equipo_model.dart';
import 'item_orden_model.dart';
import 'pago_model.dart';
import 'tecnico_model.dart';

class OrdenModel {
  final int id;
  final String? numeroOrden;
  final int? empresaId;
  final int? clienteId;
  final int? tecnicoId;
  final String estado;
  final String prioridad;
  final double subtotal;
  final double adelanto;
  final double descuento;
  final double saldoPendiente;
  final String? fechaPrometida;
  final String? contrasenaEquipo;
  final String? createdAt;
  final String? updatedAt;

  // Relaciones anidadas
  final ClienteModel? cliente;
  final EquipoModel? equipo;
  final TecnicoModel? tecnico;
  final List<ItemOrdenModel> itemsServicio;
  final List<PagoModel> pagos;

  OrdenModel({
    required this.id,
    this.numeroOrden,
    this.empresaId,
    this.clienteId,
    this.tecnicoId,
    this.estado = 'pendiente',
    this.prioridad = 'normal',
    this.subtotal = 0.0,
    this.adelanto = 0.0,
    this.descuento = 0.0,
    this.saldoPendiente = 0.0,
    this.fechaPrometida,
    this.contrasenaEquipo,
    this.createdAt,
    this.updatedAt,
    this.cliente,
    this.equipo,
    this.tecnico,
    this.itemsServicio = const [],
    this.pagos = const [],
  });

  String get numeroOrdenDisplay => numeroOrden != null && numeroOrden!.isNotEmpty
      ? '#$numeroOrden'
      : '#$id';

  String get codigoVisual => numeroOrdenDisplay;
  String get clienteNombreCompleto => cliente?.nombreCompleto ?? 'Cliente';

  String get estadoDisplay => StatusHelper.obtenerTexto(estado);

  String get subtotalFormateado => CurrencyFormatter.format(subtotal);
  String get adelantoFormateado => CurrencyFormatter.format(adelanto);
  String get descuentoFormateado => CurrencyFormatter.format(descuento);
  String get saldoPendienteFormateado => CurrencyFormatter.format(saldoPendiente);

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    // Manejo de cliente anidado
    ClienteModel? clienteObj;
    if (json['cliente'] != null && json['cliente'] is Map<String, dynamic>) {
      clienteObj = ClienteModel.fromJson(json['cliente'] as Map<String, dynamic>);
    }

    // Manejo de equipo anidado (puede venir como mapa o como lista si 1-to-many en Supabase)
    EquipoModel? equipoObj;
    if (json['equipo'] != null) {
      if (json['equipo'] is Map<String, dynamic>) {
        equipoObj = EquipoModel.fromJson(json['equipo'] as Map<String, dynamic>);
      } else if (json['equipo'] is List && (json['equipo'] as List).isNotEmpty) {
        equipoObj = EquipoModel.fromJson((json['equipo'] as List).first as Map<String, dynamic>);
      }
    }

    // Manejo de técnico anidado
    TecnicoModel? tecnicoObj;
    if (json['tecnico'] != null && json['tecnico'] is Map<String, dynamic>) {
      tecnicoObj = TecnicoModel.fromJson(json['tecnico'] as Map<String, dynamic>);
    }

    // Manejo de items de servicio
    List<ItemOrdenModel> items = [];
    final itemsJson = json['orden_servicio'] ?? json['items_servicio'];
    if (itemsJson != null && itemsJson is List) {
      items = itemsJson
          .map((item) => ItemOrdenModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Manejo de pagos
    List<PagoModel> listaPagos = [];
    if (json['pago'] != null && json['pago'] is List) {
      listaPagos = (json['pago'] as List)
          .map((p) => PagoModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return OrdenModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      numeroOrden: json['numero_orden'] as String?,
      empresaId: json['empresa_id'] as int?,
      clienteId: json['cliente_id'] as int?,
      tecnicoId: json['tecnico_id'] as int?,
      estado: json['estado'] as String? ?? 'pendiente',
      prioridad: json['prioridad'] as String? ?? 'normal',
      subtotal: json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : 0.0,
      adelanto: json['adelanto'] != null ? (json['adelanto'] as num).toDouble() : 0.0,
      descuento: json['descuento'] != null ? (json['descuento'] as num).toDouble() : 0.0,
      saldoPendiente: json['saldo_pendiente'] != null
          ? (json['saldo_pendiente'] as num).toDouble()
          : 0.0,
      fechaPrometida: json['fecha_prometida'] as String?,
      contrasenaEquipo: json['contrasena_equipo'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      cliente: clienteObj,
      equipo: equipoObj,
      tecnico: tecnicoObj,
      itemsServicio: items,
      pagos: listaPagos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (numeroOrden != null) 'numero_orden': numeroOrden,
      if (empresaId != null) 'empresa_id': empresaId,
      if (clienteId != null) 'cliente_id': clienteId,
      if (tecnicoId != null) 'tecnico_id': tecnicoId,
      'estado': estado,
      'prioridad': prioridad,
      'subtotal': subtotal,
      'adelanto': adelanto,
      'descuento': descuento,
      'saldo_pendiente': saldoPendiente,
      if (fechaPrometida != null) 'fecha_prometida': fechaPrometida,
      if (contrasenaEquipo != null) 'contrasena_equipo': contrasenaEquipo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  OrdenModel copyWith({
    int? id,
    String? numeroOrden,
    int? empresaId,
    int? clienteId,
    int? tecnicoId,
    String? estado,
    String? prioridad,
    double? subtotal,
    double? adelanto,
    double? descuento,
    double? saldoPendiente,
    String? fechaPrometida,
    String? contrasenaEquipo,
    String? createdAt,
    String? updatedAt,
    ClienteModel? cliente,
    EquipoModel? equipo,
    TecnicoModel? tecnico,
    List<ItemOrdenModel>? itemsServicio,
    List<PagoModel>? pagos,
  }) {
    return OrdenModel(
      id: id ?? this.id,
      numeroOrden: numeroOrden ?? this.numeroOrden,
      empresaId: empresaId ?? this.empresaId,
      clienteId: clienteId ?? this.clienteId,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      subtotal: subtotal ?? this.subtotal,
      adelanto: adelanto ?? this.adelanto,
      descuento: descuento ?? this.descuento,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      fechaPrometida: fechaPrometida ?? this.fechaPrometida,
      contrasenaEquipo: contrasenaEquipo ?? this.contrasenaEquipo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cliente: cliente ?? this.cliente,
      equipo: equipo ?? this.equipo,
      tecnico: tecnico ?? this.tecnico,
      itemsServicio: itemsServicio ?? this.itemsServicio,
      pagos: pagos ?? this.pagos,
    );
  }
}
