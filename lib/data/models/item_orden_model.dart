import 'servicio_catalogo_model.dart';

class ItemOrdenModel {
  final int id;
  final int? ordenId;
  final int? servicioId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final ServicioCatalogoModel? servicio;

  ItemOrdenModel({
    required this.id,
    this.ordenId,
    this.servicioId,
    this.cantidad = 1,
    required this.precioUnitario,
    required this.subtotal,
    this.servicio,
  });

  factory ItemOrdenModel.fromJson(Map<String, dynamic> json) {
    return ItemOrdenModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      ordenId: json['orden_id'] as int?,
      servicioId: json['servicio_id'] as int?,
      cantidad: json['cantidad'] is int ? json['cantidad'] as int : 1,
      precioUnitario: json['precio_unitario'] != null
          ? (json['precio_unitario'] as num).toDouble()
          : 0.0,
      subtotal: json['subtotal'] != null
          ? (json['subtotal'] as num).toDouble()
          : 0.0,
      servicio: json['servicio_catalogo'] != null
          ? ServicioCatalogoModel.fromJson(json['servicio_catalogo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (ordenId != null) 'orden_id': ordenId,
      if (servicioId != null) 'servicio_id': servicioId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}
