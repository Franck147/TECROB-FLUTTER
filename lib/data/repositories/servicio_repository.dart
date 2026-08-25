import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servicio_catalogo_model.dart';

class ServicioRepository {
  final SupabaseClient _supabase;

  ServicioRepository(this._supabase);

  Future<List<ServicioCatalogoModel>> listarServicios(
    int empresaId, {
    bool soloActivos = true,
  }) async {
    var query = _supabase
        .from('servicio_catalogo')
        .select()
        .eq('empresa_id', empresaId);

    if (soloActivos) {
      query = query.eq('activo', true);
    }

    final response = await query.order('nombre', ascending: true);

    return (response as List)
        .map((json) => ServicioCatalogoModel.fromJson(json))
        .toList();
  }

  Future<List<ServicioCatalogoModel>> listarPorCategoria(
    int empresaId,
    String categoria,
  ) async {
    final response = await _supabase
        .from('servicio_catalogo')
        .select()
        .eq('empresa_id', empresaId)
        .eq('categoria', categoria)
        .eq('activo', true)
        .order('nombre', ascending: true);

    return (response as List)
        .map((json) => ServicioCatalogoModel.fromJson(json))
        .toList();
  }

  Future<ServicioCatalogoModel> crearServicio(Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('servicio_catalogo')
        .insert(datos)
        .select()
        .single();

    return ServicioCatalogoModel.fromJson(response);
  }

  Future<ServicioCatalogoModel> actualizarServicio(
    int id,
    Map<String, dynamic> datos,
  ) async {
    final response = await _supabase
        .from('servicio_catalogo')
        .update(datos)
        .eq('id', id)
        .select()
        .single();

    return ServicioCatalogoModel.fromJson(response);
  }

  Future<void> eliminarServicio(int id) async {
    await _supabase.from('servicio_catalogo').delete().eq('id', id);
  }
}
