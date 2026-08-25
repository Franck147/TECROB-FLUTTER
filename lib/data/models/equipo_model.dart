import '../../core/utils/status_helper.dart';

class EquipoModel {
  final int id;
  final int? ordenId;
  final String tipo;
  final String marca;
  final String? modelo;
  final String? numeroSerie;
  final String? desperfecto;
  final String? descripcionGeneral;
  final String? accesorios;
  final String? createdAt;

  EquipoModel({
    required this.id,
    this.ordenId,
    required this.tipo,
    required this.marca,
    this.modelo,
    this.numeroSerie,
    this.desperfecto,
    this.descripcionGeneral,
    this.accesorios,
    this.createdAt,
  });

  String get tipoFormateado => StatusHelper.obtenerTipoEquipoTexto(tipo);

  String get nombreCompleto {
    if (modelo != null && modelo!.trim().isNotEmpty) {
      return '$marca $modelo'.trim();
    }
    return marca;
  }

  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      ordenId: json['orden_id'] as int?,
      tipo: json['tipo'] as String? ?? 'laptop',
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String?,
      numeroSerie: json['numero_serie'] as String?,
      desperfecto: json['desperfecto'] as String?,
      descripcionGeneral: json['descripcion_general'] as String?,
      accesorios: json['accesorios'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (ordenId != null) 'orden_id': ordenId,
      'tipo': tipo,
      'marca': marca,
      if (modelo != null) 'modelo': modelo,
      if (numeroSerie != null) 'numero_serie': numeroSerie,
      if (desperfecto != null) 'desperfecto': desperfecto,
      if (descripcionGeneral != null) 'descripcion_general': descripcionGeneral,
      if (accesorios != null) 'accesorios': accesorios,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
