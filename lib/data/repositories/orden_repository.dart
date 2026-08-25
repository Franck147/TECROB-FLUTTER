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
    pago (*)
  ''';

  Future<List<OrdenModel>> listarOrdenes(
    int empresaId, {
    String? estado,
    int? limit,
  }) async {
    var query = _supabase
        .from('orden')
        .select(_selectQueryCompleta)
        .eq('empresa_id', empresaId);

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

  Future<OrdenModel> crearOrdenCompleta({
    required int empresaId,
    required int tecnicoId,
    required Map<String, dynamic> datosOrden,
    required Map<String, dynamic> datosEquipo,
    required List<ServicioCatalogoModel> servicios,
  }) async {
    // 1. Calcular subtotal de servicios
    double subtotalServicios = 0.0;
    for (var s in servicios) {
      subtotalServicios += s.precioBase;
    }

    double adelanto = (datosOrden['adelanto'] as num?)?.toDouble() ?? 0.0;
    double descuento = (datosOrden['descuento'] as num?)?.toDouble() ?? 0.0;
    double saldoPendiente = subtotalServicios - descuento - adelanto;

    datosOrden['subtotal'] = subtotalServicios;
    datosOrden['saldo_pendiente'] = saldoPendiente > 0 ? saldoPendiente : 0.0;

    // 2. Insertar orden
    final ordenJson = await _supabase
        .from('orden')
        .insert(datosOrden)
        .select()
        .single();

    final int ordenId = ordenJson['id'] as int;

    // 3. Insertar equipo
    datosEquipo['orden_id'] = ordenId;
    await _supabase.from('equipo').insert(datosEquipo);

    // 4. Insertar servicios asociados
    if (servicios.isNotEmpty) {
      final List<Map<String, dynamic>> itemsInsert = servicios.map((s) {
        return {
          'orden_id': ordenId,
          'servicio_id': s.id,
          'cantidad': 1,
          'precio_unitario': s.precioBase,
          'subtotal': s.precioBase,
        };
      }).toList();

      await _supabase.from('orden_servicio').insert(itemsInsert);
    }

    // 5. Si hubo adelanto inicial > 0, registrar pago inicial
    if (adelanto > 0) {
      await _supabase.from('pago').insert({
        'orden_id': ordenId,
        'monto': adelanto,
        'metodo': 'efectivo',
        'nota': 'Adelanto inicial al crear la orden',
      });
    }

    // 6. Retornar la orden completa cargada con sus relaciones
    final ordenCompleta = await obtenerOrdenPorId(ordenId);
    return ordenCompleta!;
  }

  Future<void> actualizarEstado(int ordenId, String nuevoEstado) async {
    await _supabase
        .from('orden')
        .update({'estado': nuevoEstado})
        .eq('id', ordenId);
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

  Future<int> contarOrdenesActivas(int empresaId) async {
    final response = await _supabase
        .from('orden')
        .select('id')
        .eq('empresa_id', empresaId)
        .not('estado', 'in', '("entregado","cancelado","sin_reparacion")');

    return (response as List).length;
  }

  Future<int> contarOrdenesPendientes(int empresaId) async {
    final response = await _supabase
        .from('orden')
        .select('id')
        .eq('empresa_id', empresaId)
        .eq('estado', 'pendiente');

    return (response as List).length;
  }
}
