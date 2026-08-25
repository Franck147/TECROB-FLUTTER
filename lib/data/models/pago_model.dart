class PagoModel {
  final int id;
  final int ordenId;
  final double monto;
  final String metodo; // 'efectivo', 'yape', 'plin', 'transferencia', 'tarjeta'
  final String? nota;
  final String? createdAt;

  PagoModel({
    required this.id,
    required this.ordenId,
    required this.monto,
    required this.metodo,
    this.nota,
    this.createdAt,
  });

  String get metodoFormateado {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return metodo;
    }
  }

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      ordenId: json['orden_id'] is int ? json['orden_id'] as int : int.tryParse(json['orden_id'].toString()) ?? 0,
      monto: json['monto'] != null ? (json['monto'] as num).toDouble() : 0.0,
      metodo: json['metodo'] as String? ?? 'efectivo',
      nota: json['nota'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orden_id': ordenId,
      'monto': monto,
      'metodo': metodo,
      if (nota != null) 'nota': nota,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
