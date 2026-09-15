import '../../core/utils/currency_formatter.dart';
import '../../core/utils/status_helper.dart';
import 'cliente_model.dart';
import 'equipo_model.dart';
import 'historial_estado_model.dart';
import 'item_orden_model.dart';
import 'pago_model.dart';
import 'tecnico_model.dart';

class OrdenModel {
  final int id;
  final String? numeroOrden;
  final int? clienteId;
  final int? tecnicoId;
  final String estado;
  final String prioridad;
  final double subtotal;
  final double descuento;

  /// Lo que hay que cobrar por el trabajo, ya descontado. Lo calcula la base a
  /// partir de las líneas de servicio, no la app.
  final double total;

  final double saldoPendiente;
  final String? fechaPrometida;
  final String? contrasenaEquipo;
  final String? observaciones;
  final String? createdAt;
  final String? updatedAt;

  // Relaciones anidadas
  final ClienteModel? cliente;
  final EquipoModel? equipo;
  final TecnicoModel? tecnico;
  final List<ItemOrdenModel> itemsServicio;
  final List<PagoModel> pagos;
  final List<HistorialEstadoModel> historial;

  OrdenModel({
    required this.id,
    this.numeroOrden,
    this.clienteId,
    this.tecnicoId,
    this.estado = 'pendiente',
    this.prioridad = 'normal',
    this.subtotal = 0.0,
    this.descuento = 0.0,
    this.total = 0.0,
    this.saldoPendiente = 0.0,
    this.fechaPrometida,
    this.contrasenaEquipo,
    this.observaciones,
    this.createdAt,
    this.updatedAt,
    this.cliente,
    this.equipo,
    this.tecnico,
    this.itemsServicio = const [],
    this.pagos = const [],
    this.historial = const [],
  });

  String get numeroOrdenDisplay => numeroOrden != null && numeroOrden!.isNotEmpty
      ? '#$numeroOrden'
      : '#$id';

  String get codigoVisual => numeroOrdenDisplay;
  String get clienteNombreCompleto => cliente?.nombreCompleto ?? 'Cliente';

  String get estadoDisplay => StatusHelper.obtenerTexto(estado);

  /// Todo lo que el cliente ha entregado hasta ahora, adelanto incluido.
  ///
  /// El adelanto no se guarda aparte: al crear la orden entra como el primer
  /// pago, así que sumar los pagos es la única cuenta que siempre cuadra.
  double get totalPagado =>
      pagos.fold<double>(0, (suma, pago) => suma + pago.monto);

  String get subtotalFormateado => CurrencyFormatter.format(subtotal);
  String get descuentoFormateado => CurrencyFormatter.format(descuento);
  String get totalFormateado => CurrencyFormatter.format(total);
  String get totalPagadoFormateado => CurrencyFormatter.format(totalPagado);
  String get saldoPendienteFormateado => CurrencyFormatter.format(saldoPendiente);

  /// La orden ya no se trabaja: entregada, cancelada o sin reparación.
  bool get estaCerrada => StatusHelper.estaCerrada(estado);

  /// La orden sigue en el taller y ya pasó su fecha prometida.
  ///
  /// Una orden cerrada nunca está vencida, y una sin fecha prometida tampoco,
  /// porque no hay contra qué compararla.
  bool get estaVencida => diasDeRetraso > 0;

  /// Días completos transcurridos desde la fecha prometida. Cero si no aplica.
  int get diasDeRetraso {
    if (estaCerrada) return 0;
    if (fechaPrometida == null || fechaPrometida!.isEmpty) return 0;

    final prometida = DateTime.tryParse(fechaPrometida!);
    if (prometida == null) return 0;

    return _diasCompletosHasta(prometida);
  }

  /// Cuándo pasó la orden a su estado actual, según el historial.
  ///
  /// Null si el historial no llegó cargado o si la orden nunca cambió de
  /// estado desde que se creó.
  DateTime? get fechaEstadoActual {
    DateTime? ultima;
    for (final paso in historial) {
      if (paso.estadoNuevo.toLowerCase() != estado.toLowerCase()) continue;
      final fecha = paso.fecha;
      if (fecha == null) continue;
      if (ultima == null || fecha.isAfter(ultima)) ultima = fecha;
    }
    return ultima;
  }

  /// Días completos que la orden lleva esperando a que el cliente la recoja.
  ///
  /// Se cuentan desde que la orden pasó a 'listo', que es lo que registra el
  /// historial. Si el historial no viene en la consulta se usa la última
  /// actualización de la orden, que es una aproximación peor pero sirve.
  int get diasEsperandoRecojo {
    final desdeHistorial = fechaEstadoActual;
    if (desdeHistorial != null) return _diasCompletosHasta(desdeHistorial);

    final referencia = updatedAt ?? createdAt;
    if (referencia == null || referencia.isEmpty) return 0;

    final desde = DateTime.tryParse(referencia)?.toLocal();
    if (desde == null) return 0;

    return _diasCompletosHasta(desde);
  }

  /// Días de calendario entre [desde] y hoy, sin contar horas y sin bajar de
  /// cero: una fecha futura devuelve cero, no un negativo.
  int _diasCompletosHasta(DateTime desde) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicio = DateTime(desde.year, desde.month, desde.day);
    final dias = hoy.difference(inicio).inDays;
    return dias > 0 ? dias : 0;
  }

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    // Manejo de cliente anidado
    ClienteModel? clienteObj;
    if (json['cliente'] != null && json['cliente'] is Map<String, dynamic>) {
      clienteObj = ClienteModel.fromJson(json['cliente'] as Map<String, dynamic>);
    }

    // El equipo es uno a uno con la orden, pero Supabase devuelve la relación
    // inversa como lista mientras no reconozca la restricción única.
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

    // Manejo del historial de estados
    List<HistorialEstadoModel> listaHistorial = [];
    if (json['historial_estado'] != null && json['historial_estado'] is List) {
      listaHistorial = (json['historial_estado'] as List)
          .map((h) => HistorialEstadoModel.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    final subtotal = _aDouble(json['subtotal']);
    final descuento = _aDouble(json['descuento']);

    return OrdenModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      numeroOrden: json['numero_orden'] as String?,
      clienteId: json['cliente_id'] as int?,
      tecnicoId: json['tecnico_id'] as int?,
      estado: json['estado'] as String? ?? 'pendiente',
      prioridad: json['prioridad'] as String? ?? 'normal',
      subtotal: subtotal,
      descuento: descuento,
      // Bases antiguas pueden no traer la columna; ahí el total es la resta.
      total: json['total'] != null ? _aDouble(json['total']) : subtotal - descuento,
      saldoPendiente: _aDouble(json['saldo_pendiente']),
      fechaPrometida: json['fecha_prometida'] as String?,
      contrasenaEquipo: json['contrasena_equipo'] as String?,
      observaciones: json['observaciones'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      cliente: clienteObj,
      equipo: equipoObj,
      tecnico: tecnicoObj,
      itemsServicio: items,
      pagos: listaPagos,
      historial: listaHistorial,
    );
  }

  static double _aDouble(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (numeroOrden != null) 'numero_orden': numeroOrden,
      if (clienteId != null) 'cliente_id': clienteId,
      if (tecnicoId != null) 'tecnico_id': tecnicoId,
      'estado': estado,
      'prioridad': prioridad,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'saldo_pendiente': saldoPendiente,
      if (fechaPrometida != null) 'fecha_prometida': fechaPrometida,
      if (contrasenaEquipo != null) 'contrasena_equipo': contrasenaEquipo,
      if (observaciones != null) 'observaciones': observaciones,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  OrdenModel copyWith({
    int? id,
    String? numeroOrden,
    int? clienteId,
    int? tecnicoId,
    String? estado,
    String? prioridad,
    double? subtotal,
    double? descuento,
    double? total,
    double? saldoPendiente,
    String? fechaPrometida,
    String? contrasenaEquipo,
    String? observaciones,
    String? createdAt,
    String? updatedAt,
    ClienteModel? cliente,
    EquipoModel? equipo,
    TecnicoModel? tecnico,
    List<ItemOrdenModel>? itemsServicio,
    List<PagoModel>? pagos,
    List<HistorialEstadoModel>? historial,
  }) {
    return OrdenModel(
      id: id ?? this.id,
      numeroOrden: numeroOrden ?? this.numeroOrden,
      clienteId: clienteId ?? this.clienteId,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      total: total ?? this.total,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      fechaPrometida: fechaPrometida ?? this.fechaPrometida,
      contrasenaEquipo: contrasenaEquipo ?? this.contrasenaEquipo,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cliente: cliente ?? this.cliente,
      equipo: equipo ?? this.equipo,
      tecnico: tecnico ?? this.tecnico,
      itemsServicio: itemsServicio ?? this.itemsServicio,
      pagos: pagos ?? this.pagos,
      historial: historial ?? this.historial,
    );
  }
}
