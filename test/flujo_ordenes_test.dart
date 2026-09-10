import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tecrobsys/core/utils/status_helper.dart';
import 'package:tecrobsys/data/models/cliente_model.dart';
import 'package:tecrobsys/data/models/equipo_model.dart';
import 'package:tecrobsys/data/models/orden_model.dart';
import 'package:tecrobsys/data/models/pago_model.dart';
import 'package:tecrobsys/data/repositories/orden_repository.dart';
import 'package:tecrobsys/presentation/providers/app_providers.dart';
import 'package:tecrobsys/presentation/widgets/register_payment_dialog.dart';

/// Estados que la base acepta hoy, según el CHECK de la columna orden.estado.
const estadosDeLaBase = [
  'pendiente',
  'diagnostico',
  'en_progreso',
  'listo',
  'entregado',
  'cancelado',
  'sin_reparacion',
];

/// Tipos que la base acepta hoy, según el CHECK de la columna equipo.tipo.
const tiposDeLaBase = [
  'laptop',
  'computadora',
  'impresora',
  'fotocopiadora',
  'tablet',
  'celular',
  'parlante',
  'otro',
];

String _fecha(int diasDesdeHoy) {
  final d = DateTime.now().add(Duration(days: diasDesdeHoy));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

OrdenModel _orden({
  required int id,
  required String estado,
  required double subtotal,
  double descuento = 0,
  double pagado = 0,
  int? prometidaEnDias,
  int diasEnEsteEstado = 2,
  String tipoEquipo = 'laptop',
}) {
  final total = subtotal - descuento;

  return OrdenModel(
    id: id,
    numeroOrden: 'ORD-${id.toString().padLeft(4, '0')}',
    empresaId: 1,
    estado: estado,
    subtotal: subtotal,
    descuento: descuento,
    total: total,
    saldoPendiente: total - pagado,
    fechaPrometida: prometidaEnDias == null ? null : _fecha(prometidaEnDias),
    createdAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    updatedAt: DateTime.now()
        .subtract(Duration(days: diasEnEsteEstado))
        .toIso8601String(),
    cliente: ClienteModel(id: id, nombre: 'Cliente $id', telefono: '9$id'),
    equipo: EquipoModel(id: id, tipo: tipoEquipo, marca: 'Marca$id', modelo: 'Modelo$id'),
    pagos: [
      if (pagado > 0) PagoModel(id: id, ordenId: id, monto: pagado, metodo: 'efectivo'),
    ],
  );
}

/// Un taller ficticio con una orden en cada punto del recorrido.
List<OrdenModel> _tallerDePrueba() => [
      _orden(id: 1, estado: 'pendiente', subtotal: 120, prometidaEnDias: 3),
      _orden(id: 2, estado: 'diagnostico', subtotal: 200, pagado: 50, prometidaEnDias: -3),
      _orden(id: 3, estado: 'en_progreso', subtotal: 300, descuento: 30, pagado: 100),
      _orden(
        id: 4,
        estado: 'listo',
        subtotal: 150,
        pagado: 150,
        tipoEquipo: 'impresora',
        diasEnEsteEstado: 6,
      ),
      _orden(
        id: 5,
        estado: 'listo',
        subtotal: 250,
        prometidaEnDias: -1,
        diasEnEsteEstado: 1,
      ),
      _orden(id: 6, estado: 'entregado', subtotal: 400, pagado: 400, prometidaEnDias: -9),
      _orden(id: 7, estado: 'cancelado', subtotal: 100, prometidaEnDias: -5),
      _orden(id: 8, estado: 'sin_reparacion', subtotal: 80, pagado: 80, prometidaEnDias: -4),
    ];

/// Repositorio de mentira: sirve el taller ficticio sin tocar la red y anota
/// las escrituras para poder comprobarlas.
class _RepoFalso extends OrdenRepository {
  final List<OrdenModel> ordenes;
  final List<String> estadosEscritos = [];
  final List<double> pagosEscritos = [];

  _RepoFalso(this.ordenes)
      : super(SupabaseClient('https://ficticio.supabase.co', 'clave-ficticia'));

  @override
  Future<List<OrdenModel>> listarOrdenes(int empresaId, {String? estado, int? limit}) async {
    return ordenes
        .where((o) => o.empresaId == empresaId)
        .where((o) => estado == null || o.estado == estado)
        .toList();
  }

  @override
  Future<OrdenModel?> obtenerOrdenPorId(int id) async {
    for (final o in ordenes) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Future<void> actualizarEstado(int ordenId, String nuevoEstado) async {
    estadosEscritos.add(nuevoEstado);
  }

  @override
  Future<PagoModel> registrarPago({
    required int ordenId,
    required double monto,
    required String metodo,
    String? nota,
  }) async {
    pagosEscritos.add(monto);
    return PagoModel(id: 99, ordenId: ordenId, monto: monto, metodo: metodo);
  }
}

/// Abre el diálogo de cobro como lo abre la pantalla de detalle, escribe un
/// monto y pulsa Registrar. Devuelve lo que llegó a guardarse, o null si el
/// diálogo lo rechazó.
Future<double?> _cobrar(
  WidgetTester tester, {
  required String escribiendo,
  required double sobreSaldo,
}) async {
  double? guardado;

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => RegisterPaymentDialog(
              saldoPendiente: sobreSaldo,
              onSave: (monto, metodo, nota) => guardado = monto,
            ),
          ),
          child: const Text('abrir cobro'),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('abrir cobro'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, escribiendo);
  await tester.tap(find.text('Registrar'));
  await tester.pumpAndSettle();

  return guardado;
}

Future<DashboardState> _panelCargado(List<OrdenModel> ordenes) async {
  final notifier = DashboardNotifier(_RepoFalso(ordenes));
  await notifier.cargarDatos(1);
  return notifier.state;
}

void main() {
  group('catálogo de estados', () {
    test('la app ofrece todos los estados que la base acepta', () {
      expect(StatusHelper.todosLosEstados, containsAll(estadosDeLaBase));
    });

    test('cada estado de la base tiene su etiqueta en español', () {
      for (final estado in estadosDeLaBase) {
        expect(StatusHelper.obtenerTexto(estado), isNot(estado),
            reason: 'el estado $estado se muestra en crudo');
      }
    });

    test('las etiquetas del catálogo coinciden en número con los estados', () {
      expect(
        StatusHelper.etiquetasEstados.length,
        StatusHelper.todosLosEstados.length,
      );
    });
  });

  group('tipos de equipo', () {
    test('cada tipo de la base tiene etiqueta propia', () {
      final genericos = tiposDeLaBase
          .where((t) => t != 'otro')
          .where((t) => StatusHelper.obtenerTipoEquipoTexto(t) == 'Otro')
          .toList();

      expect(genericos, isEmpty,
          reason: 'estos tipos caen en la etiqueta Otro: $genericos');
    });

    test('cada tipo de la base tiene icono propio', () {
      final genericos = tiposDeLaBase
          .where((t) => t != 'otro')
          .where((t) =>
              StatusHelper.obtenerIconoEquipo(t) == Icons.devices_rounded ||
              StatusHelper.obtenerIconoEquipo(t) == Icons.devices_other_rounded)
          .toList();

      expect(genericos, isEmpty,
          reason: 'estos tipos caen en el icono genérico: $genericos');
    });
  });

  group('panel con un taller ficticio', () {
    test('cuenta todas las órdenes cargadas', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      expect(panel.totalOrdenes, 8);
    });

    test('cuenta como activas sólo las que siguen en el taller', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      expect(panel.activasCount, 5);
    });

    test('cuenta las que esperan diagnóstico', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      expect(panel.pendientesCount, 1);
    });

    test('cuenta las que esperan al cliente', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      expect(panel.listasCount, 2);
      // La que más lleva esperando va primero, que es a quien hay que avisar.
      expect(panel.ordenesListasParaEntrega.map((o) => o.id), [4, 5]);
    });

    test('una orden entregada fuera de plazo ya no está atrasada', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      expect(panel.ordenesVencidas.map((o) => o.id), isNot(contains(6)));
    });

    test('una orden cancelada fuera de plazo no está atrasada', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      expect(panel.ordenesVencidas.map((o) => o.id), isNot(contains(7)));
    });

    test('una orden sin reparación no se cuenta como atrasada', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      expect(panel.ordenesVencidas.map((o) => o.id), isNot(contains(8)),
          reason: 'el equipo no tiene arreglo, el plazo ya no aplica');
    });

    test('las atrasadas salen de la más antigua a la más reciente', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      final dias = panel.ordenesVencidas.map((o) => o.diasDeRetraso).toList();
      final ordenado = [...dias]..sort((a, b) => b.compareTo(a));
      expect(dias, ordenado);
    });

    test('la distribución de estados reparte todas las órdenes', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      final suma = panel.distribucionEstados.values.fold<int>(0, (a, b) => a + b);
      expect(suma, 8);
    });

    test('las cuentas por cobrar suman sólo lo que se puede cobrar', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      // Pendiente 120 + diagnóstico 150 + en progreso 170 + lista 250.
      // La cancelada no se cobra y las cerradas no deben nada.
      expect(panel.cuentasPorCobrar, 690);
    });

    test('los ingresos suman el dinero realmente cobrado', () async {
      final panel = await _panelCargado(_tallerDePrueba());
      // Adelantos y pagos: 50 + 100 + 150 + 400 + 80.
      expect(panel.totalIngresos, 780);
    });

    test('un taller vacío no rompe el panel', () async {
      final panel = await _panelCargado([]);
      expect(panel.totalOrdenes, 0);
      expect(panel.ticketPromedio, 0);
      expect(panel.ordenesListasParaEntrega, isEmpty);
    });
  });

  group('listado de órdenes', () {
    test('el filtro por estado deja sólo ese estado', () async {
      final notifier = OrdenesNotifier(_RepoFalso(_tallerDePrueba()));
      await notifier.cargarOrdenes(1);
      notifier.setFiltroEstado('listo');

      expect(notifier.state.ordenesFiltradas.map((o) => o.id), [4, 5]);
    });

    test('la búsqueda encuentra por número de orden', () async {
      final notifier = OrdenesNotifier(_RepoFalso(_tallerDePrueba()));
      await notifier.cargarOrdenes(1);
      notifier.setBusqueda('ORD-0003');

      expect(notifier.state.ordenesFiltradas.map((o) => o.id), [3]);
    });

    test('la búsqueda encuentra por nombre de cliente', () async {
      final notifier = OrdenesNotifier(_RepoFalso(_tallerDePrueba()));
      await notifier.cargarOrdenes(1);
      notifier.setBusqueda('cliente 5');

      expect(notifier.state.ordenesFiltradas.map((o) => o.id), [5]);
    });

    test('la búsqueda encuentra por teléfono del cliente', () async {
      final notifier = OrdenesNotifier(_RepoFalso(_tallerDePrueba()));
      await notifier.cargarOrdenes(1);
      notifier.setBusqueda('93');

      expect(notifier.state.ordenesFiltradas.map((o) => o.id), [3]);
    });

    test('el filtro de atrasadas descarta el filtro de estado', () async {
      final notifier = OrdenesNotifier(_RepoFalso(_tallerDePrueba()));
      await notifier.cargarOrdenes(1);
      notifier.setFiltroEstado('listo');
      notifier.setSoloVencidas();

      expect(notifier.state.filtroEstado, isNull);
      expect(notifier.state.ordenesFiltradas.every((o) => o.estaVencida), isTrue);
    });

    test('otra empresa no ve las órdenes de esta', () async {
      final ajena = _orden(id: 90, estado: 'pendiente', subtotal: 10)
          .copyWith(empresaId: 2);
      final notifier = OrdenesNotifier(_RepoFalso([..._tallerDePrueba(), ajena]));
      await notifier.cargarOrdenes(1);

      expect(notifier.state.todasLasOrdenes.map((o) => o.id), isNot(contains(90)));
    });
  });

  group('registro de pagos', () {
    testWidgets('no acepta cobrar más de lo que se debe', (tester) async {
      final monto = await _cobrar(tester, escribiendo: '500', sobreSaldo: 150);

      expect(monto, isNull,
          reason: 'cobrar de más deja la orden con saldo negativo');
    });

    testWidgets('acepta un pago parcial dentro del saldo', (tester) async {
      final monto = await _cobrar(tester, escribiendo: '50', sobreSaldo: 150);

      expect(monto, 50);
    });

    testWidgets('acepta cancelar el saldo exacto', (tester) async {
      final monto = await _cobrar(tester, escribiendo: '150', sobreSaldo: 150);

      expect(monto, 150);
    });
  });
}
