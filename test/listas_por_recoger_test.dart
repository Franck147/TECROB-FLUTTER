import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tecrobsys/data/models/cliente_model.dart';
import 'package:tecrobsys/data/models/equipo_model.dart';
import 'package:tecrobsys/data/models/historial_estado_model.dart';
import 'package:tecrobsys/data/models/pago_model.dart';
import 'package:tecrobsys/data/models/orden_model.dart';
import 'package:tecrobsys/presentation/widgets/listas_por_recoger_card.dart';

/// Construye una orden en estado "listo" que lleva [dias] días esperando a
/// que el cliente la recoja.
OrdenModel _ordenLista({
  required int id,
  required int dias,
  double saldo = 0.0,
  String nombre = 'Cliente',
}) {
  final desde = DateTime.now().subtract(Duration(days: dias));
  return OrdenModel(
    id: id,
    numeroOrden: 'ORD-${id.toString().padLeft(4, '0')}',
    estado: 'listo',
    saldoPendiente: saldo,
    updatedAt: desde.toIso8601String(),
    cliente: ClienteModel(id: id, nombre: nombre, telefono: '999888777'),
    equipo: EquipoModel(id: id, tipo: 'laptop', marca: 'Lenovo'),
  );
}

Widget _envoltura(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('días esperando el recojo', () {
    test('cuenta los días completos desde la última actualización', () {
      final orden = _ordenLista(id: 1, dias: 6);

      expect(orden.diasEsperandoRecojo, 6);
    });

    test('es cero cuando la orden no tiene fecha de actualización', () {
      final orden = OrdenModel(id: 1, estado: 'listo');

      expect(orden.diasEsperandoRecojo, 0);
    });

    test('prefiere la fecha del historial a la de actualización', () {
      final orden = OrdenModel(
        id: 1,
        estado: 'listo',
        updatedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        historial: [
          HistorialEstadoModel(
            id: 1,
            ordenId: 1,
            estadoPrevio: 'en_progreso',
            estadoNuevo: 'listo',
            createdAt:
                DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
          ),
        ],
      );

      expect(orden.diasEsperandoRecojo, 9);
    });

    test('ignora los pasos del historial hacia otros estados', () {
      final orden = OrdenModel(
        id: 1,
        estado: 'listo',
        updatedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        historial: [
          HistorialEstadoModel(
            id: 1,
            ordenId: 1,
            estadoNuevo: 'diagnostico',
            createdAt:
                DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          ),
          HistorialEstadoModel(
            id: 2,
            ordenId: 1,
            estadoPrevio: 'diagnostico',
            estadoNuevo: 'listo',
            createdAt:
                DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
          ),
        ],
      );

      expect(orden.diasEsperandoRecojo, 4);
    });

    test('es cero cuando la fecha de actualización está en el futuro', () {
      final manana = DateTime.now().add(const Duration(days: 3));
      final orden = OrdenModel(
        id: 1,
        estado: 'listo',
        updatedAt: manana.toIso8601String(),
      );

      expect(orden.diasEsperandoRecojo, 0);
    });
  });

  group('dinero de la orden', () {
    test('lo pagado es la suma de todos los pagos, no sólo del adelanto', () {
      final orden = OrdenModel(
        id: 1,
        estado: 'en_progreso',
        subtotal: 300,
        total: 300,
        saldoPendiente: 150,
        pagos: [
          PagoModel(id: 1, ordenId: 1, monto: 50, metodo: 'efectivo'),
          PagoModel(id: 2, ordenId: 1, monto: 100, metodo: 'yape'),
        ],
      );

      expect(orden.totalPagado, 150);
      // El desglose tiene que cerrar: total menos pagado es el saldo.
      expect(orden.total - orden.totalPagado, orden.saldoPendiente);
    });

    test('una orden sin pagos no tiene nada pagado', () {
      final orden = OrdenModel(id: 1, estado: 'pendiente', subtotal: 80, total: 80);

      expect(orden.totalPagado, 0);
    });

    test('el total cae al subtotal menos el descuento si la base no lo trae', () {
      final orden = OrdenModel.fromJson({
        'id': 1,
        'estado': 'pendiente',
        'subtotal': 300,
        'descuento': 30,
      });

      expect(orden.total, 270);
    });
  });

  group('estado del saldo al entregar', () {
    test('sin saldo la orden está pagada', () {
      expect(EstadoSaldoRecojo.desde(0), EstadoSaldoRecojo.pagado);
    });

    test('con saldo positivo queda por cobrar', () {
      expect(EstadoSaldoRecojo.desde(150), EstadoSaldoRecojo.porCobrar);
    });

    test('con saldo negativo el cliente pagó de más', () {
      expect(EstadoSaldoRecojo.desde(-100), EstadoSaldoRecojo.aFavor);
    });

    test('los céntimos de redondeo no cuentan como deuda', () {
      expect(EstadoSaldoRecojo.desde(0.004), EstadoSaldoRecojo.pagado);
    });
  });

  group('tarjeta de listas por recoger', () {
    testWidgets('ordena las órdenes de la que más espera a la que menos',
        (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [
          _ordenLista(id: 1, dias: 2, nombre: 'Ana'),
          _ordenLista(id: 2, dias: 9, nombre: 'Beto'),
          _ordenLista(id: 3, dias: 5, nombre: 'Carla'),
        ],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      final nombres = tester
          .widgetList<Text>(find.byKey(const Key('recojo-titulo-fila')))
          .map((t) => t.data ?? '')
          .toList();

      expect(nombres[0], contains('Beto'));
      expect(nombres[1], contains('Carla'));
      expect(nombres[2], contains('Ana'));
    });

    testWidgets('muestra sólo las primeras cinco y ofrece ver el resto',
        (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [
          for (var i = 1; i <= 8; i++) _ordenLista(id: i, dias: i),
        ],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      expect(find.byKey(const Key('recojo-titulo-fila')), findsNWidgets(5));
      expect(find.text('Ver las 3 restantes'), findsOneWidget);
    });

    testWidgets('al tocar el enlace despliega todas las órdenes',
        (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [
          for (var i = 1; i <= 8; i++) _ordenLista(id: i, dias: i),
        ],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      await tester.tap(find.text('Ver las 3 restantes'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recojo-titulo-fila')), findsNWidgets(8));
      expect(find.text('Ver menos'), findsOneWidget);
    });

    testWidgets('el botón de WhatsApp avisa sobre la orden de esa fila',
        (tester) async {
      OrdenModel? avisada;

      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [
          _ordenLista(id: 1, dias: 2, nombre: 'Ana'),
          _ordenLista(id: 2, dias: 9, nombre: 'Beto'),
        ],
        onAvisar: (orden) => avisada = orden,
        onAbrirOrden: (_) {},
      )));

      await tester.tap(find.byKey(const Key('recojo-avisar-2')));
      await tester.pump();

      expect(avisada?.id, 2);
    });

    testWidgets('al tocar la fila se abre esa orden', (tester) async {
      OrdenModel? abierta;

      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [
          _ordenLista(id: 1, dias: 2, nombre: 'Ana'),
          _ordenLista(id: 2, dias: 9, nombre: 'Beto'),
        ],
        onAvisar: (_) {},
        onAbrirOrden: (orden) => abierta = orden,
      )));

      await tester.tap(find.byKey(const Key('recojo-fila-1')));
      await tester.pump();

      expect(abierta?.id, 1);
    });

    testWidgets('una orden sin deuda se anuncia como pagada', (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [_ordenLista(id: 1, dias: 1, saldo: 0)],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      expect(find.text('Pagado'), findsOneWidget);
    });

    testWidgets('una orden con deuda muestra cuánto falta cobrar',
        (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [_ordenLista(id: 1, dias: 1, saldo: 150)],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      expect(find.textContaining('Cobrar'), findsOneWidget);
      expect(find.textContaining('150'), findsOneWidget);
    });

    testWidgets('una orden con saldo negativo se marca a favor del cliente',
        (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [_ordenLista(id: 1, dias: 1, saldo: -100)],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      expect(find.textContaining('A favor'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('la insignia dice cuántos días lleva esperando',
        (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [_ordenLista(id: 1, dias: 4)],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      expect(find.text('4d'), findsOneWidget);
    });

    testWidgets('el mismo día de terminada la insignia dice hoy',
        (tester) async {
      await tester.pumpWidget(_envoltura(ListasPorRecogerCard(
        ordenes: [_ordenLista(id: 1, dias: 0)],
        onAvisar: (_) {},
        onAbrirOrden: (_) {},
      )));

      expect(find.text('hoy'), findsOneWidget);
    });
  });
}
