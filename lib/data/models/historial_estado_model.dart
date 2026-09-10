/// Un salto de estado de una orden, tal como lo guarda la tabla
/// historial_estado. Es lo que permite saber cuándo pasó algo y no sólo en qué
/// punto está la orden ahora.
class HistorialEstadoModel {
  final int id;
  final int ordenId;
  final String? estadoPrevio;
  final String estadoNuevo;
  final int? tecnicoId;
  final String? createdAt;

  const HistorialEstadoModel({
    required this.id,
    required this.ordenId,
    this.estadoPrevio,
    required this.estadoNuevo,
    this.tecnicoId,
    this.createdAt,
  });

  /// El momento del cambio, en hora local. Null si la fila no trae fecha.
  DateTime? get fecha => createdAt == null || createdAt!.isEmpty
      ? null
      : DateTime.tryParse(createdAt!)?.toLocal();

  factory HistorialEstadoModel.fromJson(Map<String, dynamic> json) {
    return HistorialEstadoModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      ordenId: json['orden_id'] is int
          ? json['orden_id'] as int
          : int.tryParse(json['orden_id'].toString()) ?? 0,
      estadoPrevio: json['estado_prev'] as String?,
      estadoNuevo: json['estado_nuevo'] as String? ?? '',
      tecnicoId: json['tecnico_id'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orden_id': ordenId,
      if (estadoPrevio != null) 'estado_prev': estadoPrevio,
      'estado_nuevo': estadoNuevo,
      if (tecnicoId != null) 'tecnico_id': tecnicoId,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
