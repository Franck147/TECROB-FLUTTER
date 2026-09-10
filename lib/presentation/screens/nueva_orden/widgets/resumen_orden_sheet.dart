import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/status_helper.dart';
import '../nueva_orden_formulario.dart';

/// Última revisión antes de guardar: todo lo capturado en una sola vista.
///
/// Se devuelve `true` cuando la persona confirma el registro.
class ResumenOrdenSheet extends StatelessWidget {
  final NuevaOrdenFormulario datos;

  const ResumenOrdenSheet({super.key, required this.datos});

  static Future<bool> mostrar(BuildContext context, NuevaOrdenFormulario datos) async {
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ResumenOrdenSheet(datos: datos),
    );
    return confirmado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accesorios = datos.accesorios.toList();
    final altoMaximo = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: altoMaximo),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fondoBordeOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: AppColors.primarioOf(context), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Revisa antes de registrar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipalOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                children: [
                  _Grupo(
                    titulo: 'Cliente',
                    filas: [
                      _Fila('Nombre', datos.nombreCompletoCliente),
                      if (datos.dni.text.trim().isNotEmpty) _Fila('DNI', datos.dni.text.trim()),
                      _Fila('Celular', datos.telefono.text.trim()),
                      if (datos.email.text.trim().isNotEmpty)
                        _Fila('Correo', datos.email.text.trim()),
                    ],
                  ),
                  _Grupo(
                    titulo: 'Equipo',
                    filas: [
                      _Fila('Tipo', StatusHelper.obtenerTipoEquipoTexto(datos.tipoEquipo)),
                      _Fila('Marca y modelo', datos.resumenEquipo),
                      if (datos.serie.text.trim().isNotEmpty)
                        _Fila('N° de serie', datos.serie.text.trim()),
                      if (datos.contrasena.text.trim().isNotEmpty)
                        _Fila('PIN o clave', datos.contrasena.text.trim()),
                      _Fila('Falla reportada', datos.desperfecto.text.trim()),
                      if (datos.descripcion.text.trim().isNotEmpty)
                        _Fila('Observaciones', datos.descripcion.text.trim()),
                      _Fila(
                        'Accesorios',
                        accesorios.isEmpty ? 'Ninguno' : accesorios.join(', '),
                      ),
                    ],
                  ),
                  _Grupo(
                    titulo: 'Servicios y cobro',
                    filas: [
                      _Fila(
                        'Servicios',
                        datos.servicios.isEmpty
                            ? 'Se cotizan tras el diagnóstico'
                            : datos.servicios.map((s) => s.nombre).join(', '),
                      ),
                      _Fila('Prioridad', _textoPrioridad(datos.prioridad)),
                      _Fila(
                        'Entrega prometida',
                        datos.fechaPrometida == null
                            ? 'Sin fecha definida'
                            : DateFormatter.formatearFechaLarga(datos.fechaPrometida!),
                      ),
                      _Fila('Total', CurrencyFormatter.format(datos.totalServicios)),
                      _Fila('Adelanto', CurrencyFormatter.format(datos.montoAdelanto)),
                      _Fila(
                        'Saldo pendiente',
                        CurrencyFormatter.format(datos.saldoPendiente),
                        destacado: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.fondoBordeOf(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Seguir editando'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
                      label: const Text('Registrar orden'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _textoPrioridad(String valor) {
    if (valor == 'alta') return 'Urgente';
    if (valor == 'baja') return 'Baja';
    return 'Normal';
  }
}

class _Grupo extends StatelessWidget {
  final String titulo;
  final List<_Fila> filas;

  const _Grupo({required this.titulo, required this.filas});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficieOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fondoBordeOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primarioOf(context),
            ),
          ),
          const SizedBox(height: 10),
          ...filas,
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _Fila(this.etiqueta, this.valor, {this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              etiqueta,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textoSecundarioOf(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor.isEmpty ? '—' : valor,
              style: TextStyle(
                fontSize: destacado ? 15 : 13,
                fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
                color: destacado
                    ? AppColors.primarioOf(context)
                    : AppColors.textoPrincipalOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
