import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tecnico_model.dart';

class TecnicoRepository {
  final SupabaseClient _supabase;

  TecnicoRepository(this._supabase);

  Future<List<TecnicoModel>> listarTecnicos(int empresaId) async {
    final response = await _supabase
        .from('tecnico')
        .select()
        .eq('empresa_id', empresaId)
        .eq('activo', true)
        .order('nombre', ascending: true);

    return (response as List).map((json) => TecnicoModel.fromJson(json)).toList();
  }

  Future<AuthResponse> registrarUsuarioAuth(String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<TecnicoModel> crearTecnico(Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('tecnico')
        .insert(datos)
        .select()
        .single();

    return TecnicoModel.fromJson(response);
  }

  Future<void> desactivarTecnico(int id) async {
    await _supabase
        .from('tecnico')
        .update({'activo': false})
        .eq('id', id);
  }
}
