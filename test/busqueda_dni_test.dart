import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tecrobsys/core/services/dni_service.dart';
import 'package:tecrobsys/data/models/cliente_model.dart';
import 'package:tecrobsys/data/models/dni_respuesta_model.dart';
import 'package:tecrobsys/data/repositories/cliente_repository.dart';
import 'package:tecrobsys/presentation/providers/app_providers.dart';
import 'package:tecrobsys/presentation/screens/nueva_orden/nueva_orden_screen.dart';

/// La base no conoce a nadie: toda búsqueda pasa a RENIEC.
class _SinClientes extends ClienteRepository {
  _SinClientes()
      : super(SupabaseClient('https://ficticio.supabase.co', 'clave-ficticia'));

  @override
  Future<ClienteModel?> buscarClientePorDni(String dni) async => null;
}

/// ApisPeru sin respuesta útil, con o sin token según [disponible].
class _DniVacio extends DniService {
  _DniVacio({required this.disponible});

  @override
  final bool disponible;

  int consultas = 0;

  @override
  Future<DniRespuestaModel?> consultarDni(String numeroDni) async {
    consultas++;
    return null;
  }
}

/// Se crea una sola vez, fuera de las pruebas. El cliente de Supabase arranca
/// un temporizador periódico que, creado dentro, quedaría pendiente al final.
late final ClienteRepository _clientes;

Future<void> _buscar(WidgetTester tester, DniService dni) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clienteRepositoryProvider.overrideWithValue(_clientes),
        dniServiceProvider.overrideWithValue(dni),
      ],
      child: MaterialApp(home: NuevaOrdenScreen(onOrderCreated: () {})),
    ),
  );

  // Con ocho dígitos la búsqueda arranca sola.
  await tester.enterText(
    find.widgetWithText(TextFormField, 'DNI (8 dígitos)'),
    '74985447',
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    _clientes = _SinClientes();
  });

  testWidgets('sin token no culpa a RENIEC: avisa que falta configurarlo',
      (tester) async {
    final dni = _DniVacio(disponible: false);
    await _buscar(tester, dni);

    expect(find.textContaining('falta el token'), findsOneWidget);
    expect(find.textContaining('no encontrado en RENIEC'), findsNothing);
    expect(dni.consultas, 0);
  });

  testWidgets('con token y sin resultado, dice que RENIEC no lo encontró',
      (tester) async {
    final dni = _DniVacio(disponible: true);
    await _buscar(tester, dni);

    expect(find.textContaining('no encontrado en RENIEC'), findsOneWidget);
    expect(dni.consultas, 1);
  });
}
