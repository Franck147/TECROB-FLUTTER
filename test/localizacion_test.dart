import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Réplica de la configuración de idioma de [MaterialApp] en main.dart.
///
/// Sin los delegados globales, los widgets de Material caen a
/// DefaultMaterialLocalizations, que sólo habla inglés: el calendario muestra
/// "September" y las cabeceras "S M T W T F S" aunque los botones lleven texto
/// propio en español.
Widget _appDePrueba({required Widget child}) {
  return MaterialApp(
    locale: const Locale('es', 'PE'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('es', 'PE'),
      Locale('es'),
    ],
    home: child,
  );
}

void main() {
  testWidgets('el selector de fecha se muestra en español', (tester) async {
    final hoy = DateTime(2026, 9, 9);

    await tester.pumpWidget(
      _appDePrueba(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: hoy,
              firstDate: hoy,
              lastDate: DateTime(2027, 9, 9),
              helpText: 'Fecha prometida de entrega',
              cancelText: 'Cancelar',
              confirmText: 'Confirmar',
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // El mes lo escribe MaterialLocalizations, no el código de la pantalla.
    expect(find.textContaining('septiembre', findRichText: true), findsWidgets);
    expect(find.textContaining('September', findRichText: true), findsNothing);

    // Los botones propios siguen en su sitio.
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
  });

  testWidgets('la semana del calendario empieza en lunes', (tester) async {
    final hoy = DateTime(2026, 9, 9);

    await tester.pumpWidget(
      _appDePrueba(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: hoy,
              firstDate: hoy,
              lastDate: DateTime(2027, 9, 9),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // En inglés la fila de cabecera arranca en domingo ("S"); en español
    // arranca en lunes ("L").
    final materialLocalizations = MaterialLocalizations.of(
      tester.element(find.text('abrir')),
    );
    expect(materialLocalizations.firstDayOfWeekIndex, 1);
  });
}
