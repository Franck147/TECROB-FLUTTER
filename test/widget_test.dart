import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tecrobsys/data/repositories/auth_repository.dart';
import 'package:tecrobsys/main.dart';
import 'package:tecrobsys/presentation/providers/app_providers.dart';

/// Autenticación de mentira: ni hay sesión ni hay red.
///
/// Sin esto la prueba arrancaba la app de verdad, que necesita Supabase
/// inicializado, y fallaba siempre.
class _AuthSinSesion extends AuthRepository {
  _AuthSinSesion()
      : super(SupabaseClient('https://ficticio.supabase.co', 'clave-ficticia'));

  @override
  User? get currentAuthUser => null;

  @override
  Session? get currentSession => null;
}

void main() {
  // El cliente de Supabase arranca un temporizador de refresco al construirse.
  // Se crea aquí, fuera del reloj falso de la prueba, para que no lo cuente
  // como temporizador pendiente.
  late final AuthRepository autenticacion;

  setUpAll(() {
    // En pruebas no hay red para bajar las fuentes; con esto Material usa la
    // suya en vez de lanzar una excepción.
    GoogleFonts.config.allowRuntimeFetching = false;
    autenticacion = _AuthSinSesion();
  });

  testWidgets('sin sesión la app arranca en la pantalla de acceso',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(autenticacion),
        ],
        child: const TecrobSysApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Cargando TecrobSys...'), findsNothing);
  });
}
