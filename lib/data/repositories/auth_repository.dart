import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tecnico_model.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentAuthUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentSession != null;

  Future<AuthResponse> login(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<TecnicoModel?> obtenerPerfilTecnico(String authUserId) async {
    final response = await _supabase
        .from('tecnico')
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    if (response != null) {
      return TecnicoModel.fromJson(response);
    }
    return null;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
