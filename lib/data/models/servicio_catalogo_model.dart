import '../../core/utils/currency_formatter.dart';

class ServicioCatalogoModel {
  final int id;
  final int? empresaId;
  final String nombre;
  final String? descripcion;
  final double precioBase;
  final String categoria;
  final bool activo;
  final String? createdAt;

  // Transient para selección en UI
  bool seleccionado;

  ServicioCatalogoModel({
    required this.id,
    this.empresaId,
    required this.nombre,
    this.descripcion,
    required this.precioBase,
    required this.categoria,
    this.activo = true,
    this.createdAt,
    this.seleccionado = false,
  });

  String get precioFormateado => CurrencyFormatter.format(precioBase);

  String get categoriaFormateada {
    switch (categoria.toLowerCase()) {
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'reparacion':
        return 'Reparación';
      case 'software':
        return 'Software';
      case 'repuesto':
        return 'Repuesto';
      case 'diagnostico':
        return 'Diagnóstico';
      case 'otro':
      default:
        return 'Otro';
    }
  }

  factory ServicioCatalogoModel.fromJson(Map<String, dynamic> json) {
    return ServicioCatalogoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      empresaId: json['empresa_id'] as int?,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      precioBase: json['precio_base'] != null
          ? (json['precio_base'] as num).toDouble()
          : 0.0,
      categoria: json['categoria'] as String? ?? 'otro',
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      seleccionado: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'precio_base': precioBase,
      'categoria': categoria,
      'activo': activo,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  ServicioCatalogoModel copyWith({
    int? id,
    int? empresaId,
    String? nombre,
    String? descripcion,
    double? precioBase,
    String? categoria,
    bool? activo,
    String? createdAt,
    bool? seleccionado,
  }) {
    return ServicioCatalogoModel(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioBase: precioBase ?? this.precioBase,
      categoria: categoria ?? this.categoria,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      seleccionado: seleccionado ?? this.seleccionado,
    );
  }
}
