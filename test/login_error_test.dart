import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tecrobsys/data/models/tecnico_model.dart';
import 'package:tecrobsys/data/repositories/auth_repository.dart';
import 'package:tecrobsys/main.dart';
import 'package:tecrobsys/presentation/providers/app_providers.dart';

/// Supabase acepta la contraseña, pero la base rechaza leer el perfil.
///
/// Es lo que pasa cuando el rol authenticated no tiene permisos sobre la
/// tabla tecnico. Las demoras imitan la red: sin ellas todo ocurre dentro del
/// mismo fotograma y el fallo de la pantalla no se ve.
class _AuthSinPermisoEnTecnico extends AuthRepository {
  _AuthSinPermisoEnTecnico()
      : super(SupabaseClient('https://ficticio.supabase.co', 'clave-ficticia'));

  @override
  User? get currentAuthUser => null;

  @override
  Session? get currentSession => null;

  @override
  Future<AuthResponse> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AuthResponse(
      user: const User(
        id: 'usuario-de-prueba',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
      ),
    );
  }

  @override
  Future<TecnicoModel?> obtenerPerfilTecnico(String authUserId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw const PostgrestException(
      message: 'permission denied for table tecnico',
      code: '42501',
    );
  }
}

void main() {
  late final AuthRepository autenticacion;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    autenticacion = _AuthSinPermisoEnTecnico();
  });

  testWidgets('si falla la lectura del perfil, el login muestra el error',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(autenticacion),
        ],
        child: const TecrobSysApp(),
      ),
    );
    // Deja terminar la animación de entrada.
    await tester.pump(const Duration(seconds: 2));

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'tecnico@taller.pe');
    await tester.enterText(campos.at(1), 'secreto123');

    final boton = find.text('INGRESAR AL SISTEMA');
    await tester.ensureVisible(boton);
    await tester.tap(boton);

    // Recorre las dos llamadas a la red fotograma a fotograma.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('permission denied for table tecnico'),
        findsOneWidget);
    // El formulario sigue siendo el mismo: no se reconstruyó vacío.
    expect(find.text('tecnico@taller.pe'), findsOneWidget);
  });
}
