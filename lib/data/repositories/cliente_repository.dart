import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final SupabaseClient _supabase;

  ClienteRepository(this._supabase);

  Future<List<ClienteModel>> listarClientes(int empresaId) async {
    final response = await _supabase
        .from('cliente')
        .select()
        .eq('empresa_id', empresaId)
        .order('nombre', ascending: true);

    return (response as List).map((json) => ClienteModel.fromJson(json)).toList();
  }

  Future<ClienteModel?> buscarClientePorDni(int empresaId, String dni) async {
    final response = await _supabase
        .from('cliente')
        .select()
        .eq('empresa_id', empresaId)
        .eq('dni', dni)
        .maybeSingle();

    if (response != null) {
      return ClienteModel.fromJson(response);
    }
    return null;
  }

  Future<List<ClienteModel>> buscarClientes(int empresaId, String query) async {
    final response = await _supabase
        .from('cliente')
        .select()
        .eq('empresa_id', empresaId)
        .or('nombre.ilike.%$query%,apellido.ilike.%$query%,dni.ilike.%$query%,telefono.ilike.%$query%')
        .order('nombre', ascending: true);

    return (response as List).map((json) => ClienteModel.fromJson(json)).toList();
  }

  Future<ClienteModel> crearCliente(Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('cliente')
        .insert(datos)
        .select()
        .single();

    return ClienteModel.fromJson(response);
  }

  Future<void> actualizarTelefono(int clienteId, String nuevoTelefono) async {
    await _supabase
        .from('cliente')
        .update({'telefono': nuevoTelefono})
        .eq('id', clienteId);
  }

  Future<void> actualizarCliente(int clienteId, Map<String, dynamic> datos) async {
    await _supabase
        .from('cliente')
        .update(datos)
        .eq('id', clienteId);
  }
}
