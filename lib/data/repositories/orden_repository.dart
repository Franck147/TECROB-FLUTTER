import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/orden_model.dart';
import '../models/pago_model.dart';
import '../models/servicio_catalogo_model.dart';

class OrdenRepository {
  final SupabaseClient _supabase;

  OrdenRepository(this._supabase);

  static const String _selectQueryCompleta = '''
    *,
    cliente:cliente_id (*),
    equipo (*),
    tecnico:tecnico_id (*),
    orden_servicio (*, servicio_catalogo:servicio_id (*)),
    pago (*),
    historial_estado (*)
  ''';

  Future<List<OrdenModel>> listarOrdenes({
    String? estado,
    int? limit,
  }) async {
    var query = _supabase.from('orden').select(_selectQueryCompleta);

    if (estado != null && estado.isNotEmpty) {
      query = query.eq('estado', estado);
    }

    var orderQuery = query.order('created_at', ascending: false);

    if (limit != null) {
      final response = await orderQuery.limit(limit);
      return (response as List).map((json) => OrdenModel.fromJson(json)).toList();
    }

    final response = await orderQuery;
    return (response as List).map((json) => OrdenModel.fromJson(json)).toList();
  }

  Future<OrdenModel?> obtenerOrdenPorId(int id) async {
    final response = await _supabase
        .from('orden')
        .select(_selectQueryCompleta)
        .eq('id', id)
        .maybeSingle();

    if (response != null) {
      return OrdenModel.fromJson(response);
    }
    return null;
  }

  /// Crea cliente, orden, equipo, servicios y adelanto en una sola transacción.
  ///
  /// El cliente entra en la misma llamada a propósito: cuando se guardaba antes
  /// desde la app, un fallo al crear la orden dejaba el cliente suelto en la
  /// base.
  Future<OrdenModel> crearOrdenCompleta({
    required Map<String, dynamic> datosCliente,
    required Map<String, dynamic> datosOrden,
    required Map<String, dynamic> datosEquipo,
    required List<ServicioCatalogoModel> servicios,
  }) async {
    // Las líneas de servicio viajan como lista; la función calcula el subtotal
    // a partir de ellas. 'subtotal' no se manda: en orden_servicio la genera la
    // propia base a partir de cantidad y precio_unitario.
    final serviciosPayload = servicios
        .map((s) => {
              'servicio_id': s.id,
              'cantidad': 1,
              'precio_unitario': s.precioBase,
            })
        .toList();

    final resultado = await _supabase.rpc(
      'crear_orden_completa',
      params: {
        'p_cliente': datosCliente,
        'p_orden': datosOrden,
        'p_equipo': datosEquipo,
        'p_servicios': serviciosPayload,
      },
    );

    final int ordenId = resultado is int
        ? resultado
        : int.parse(resultado.toString());

    // Retornar la orden completa cargada con sus relaciones
    final ordenCompleta = await obtenerOrdenPorId(ordenId);
    return ordenCompleta!;
  }

  /// Cambia el estado de la orden.
  ///
  /// El historial y la fecha de actualización los escribe la base con sus
  /// propios disparadores, para que ninguna ruta de escritura pueda saltárselos.
  Future<void> actualizarEstado(int ordenId, String nuevoEstado) async {
    await _supabase
        .from('orden')
        .update({'estado': nuevoEstado})
        .eq('id', ordenId);
  }

  /// Corrige los datos comerciales de una orden ya creada: prioridad, plazo,
  /// descuento y observaciones. Los importes los recalcula la base.
  Future<void> actualizarOrden(int ordenId, Map<String, dynamic> cambios) async {
    if (cambios.isEmpty) return;

    await _supabase.from('orden').update(cambios).eq('id', ordenId);
  }

  Future<PagoModel> registrarPago({
    required int ordenId,
    required double monto,
    required String metodo,
    String? nota,
  }) async {
    final response = await _supabase
        .from('pago')
        .insert({
          'orden_id': ordenId,
          'monto': monto,
          'metodo': metodo,
          if (nota != null && nota.isNotEmpty) 'nota': nota,
        })
        .select()
        .single();

    return PagoModel.fromJson(response);
  }
}
