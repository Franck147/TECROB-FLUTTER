import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/status_helper.dart';
import '../../../widgets/custom_text_field.dart';
import '../nueva_orden_formulario.dart';
import 'wizard_widgets.dart';

/// Paso 3: servicios presupuestados, plazo de entrega y adelanto.
///
/// El total y el saldo se recalculan mientras se escribe, para que quien
/// recibe el equipo pueda decirle la cifra al cliente sin salir de la pantalla.
class PasoServicios extends StatelessWidget {
  final NuevaOrdenFormulario datos;
  final VoidCallback onAbrirCatalogo;
  final VoidCallback onCambio;

  const PasoServicios({
    super.key,
    required this.datos,
    required this.onAbrirCatalogo,
    required this.onCambio,
  });

  Future<void> _elegirFecha(BuildContext context) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: datos.fechaPrometida ?? hoy.add(const Duration(days: 2)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha prometida de entrega',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (elegida != null) {
      datos.fechaPrometida = elegida;
      onCambio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = datos.fechaPrometida;

    return Form(
      key: datos.claveFormCobro,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaSeccion(
            titulo: 'Servicios',
            subtitulo: 'Puedes dejarlo vacío y cotizarlo tras el diagnóstico',
            icono: Icons.build_circle_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (datos.servicios.isEmpty)
                  const AvisoEnLinea(
                    texto: 'Aún no agregas servicios. La orden se registra igual y el '
                        'presupuesto se completa después.',
                  )
                else
                  ...datos.servicios.map((servicio) => _FilaServicio(
                        nombre: servicio.nombre,
                        precio: servicio.precioFormateado,
                        onQuitar: () {
                          datos.servicios.remove(servicio);
                          onCambio();
                        },
                      )),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onAbrirCatalogo,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar del catálogo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TarjetaSeccion(
            titulo: 'Entrega y cobro',
            subtitulo: 'Prioridad, plazo y adelanto recibido',
            icono: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EtiquetaCampo('Prioridad'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: StatusHelper.prioridades.entries.map((entrada) {
                    return ChoiceChip(
                      label: Text(entrada.value),
                      selected: datos.prioridad == entrada.key,
                      onSelected: (activo) {
                        if (!activo) return;
                        datos.prioridad = entrada.key;
                        onCambio();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const EtiquetaCampo('Fecha prometida de entrega'),
                InkWell(
                  onTap: () => _elegirFecha(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.fondoSuperficieOf(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.fondoBordeOf(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 20,
                          color: AppColors.textoSecundarioOf(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fecha == null
                                ? 'Sin fecha definida'
                                : DateFormatter.formatearFechaLarga(fecha),
                            style: TextStyle(
                              fontSize: 14,
                              color: fecha == null
                                  ? AppColors.textoMutedOf(context)
                                  : AppColors.textoPrincipalOf(context),
                            ),
                          ),
                        ),
                        if (fecha != null)
                          IconButton(
                            tooltip: 'Quitar fecha',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              datos.fechaPrometida = null;
                              onCambio();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: datos.adelanto,
                  label: 'Adelanto recibido (S/)',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money_rounded,
                  onChanged: (_) => onCambio(),
                  validator: (valor) {
                    final texto = (valor ?? '').trim().replaceAll(',', '.');
                    if (texto.isEmpty) return null;
                    final monto = double.tryParse(texto);
                    if (monto == null) return 'Escribe sólo números, por ejemplo 50.00';
                    if (monto < 0) return 'El adelanto no puede ser negativo';
                    // Un adelanto mayor que el trabajo presupuestado deja a la
                    // orden con dinero a favor del cliente desde el minuto uno.
                    if (monto > datos.totalServicios + 0.01) {
                      return 'El adelanto no puede superar '
                          '${CurrencyFormatter.format(datos.totalServicios)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _SelectorMetodoAdelanto(datos: datos, onCambio: onCambio),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TarjetaTotales(datos: datos),
        ],
      ),
    );
  }
}

class _FilaServicio extends StatelessWidget {
  final String nombre;
  final String precio;
  final VoidCallback onQuitar;

  const _FilaServicio({
    required this.nombre,
    required this.precio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficieOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fondoBordeOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nombre,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textoPrincipalOf(context),
              ),
            ),
          ),
          Text(
            precio,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primarioOf(context),
            ),
          ),
          IconButton(
            tooltip: 'Quitar servicio',
            icon: Icon(Icons.close_rounded, size: 17, color: AppColors.textoMutedOf(context)),
            onPressed: onQuitar,
          ),
        ],
      ),
    );
  }
}

/// Resumen económico en vivo: total, adelanto y saldo.
class _TarjetaTotales extends StatelessWidget {
  final NuevaOrdenFormulario datos;

  const _TarjetaTotales({required this.datos});

  @override
  Widget build(BuildContext context) {
    final azul = AppColors.primarioOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarioContenedorOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: azul.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          _Linea(
            etiqueta: 'Total de servicios',
            valor: CurrencyFormatter.format(datos.totalServicios),
          ),
          const SizedBox(height: 8),
          _Linea(
            etiqueta: 'Adelanto',
            valor: '- ${CurrencyFormatter.format(datos.montoAdelanto)}',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: azul.withValues(alpha: 0.25)),
          ),
          _Linea(
            etiqueta: 'Saldo pendiente',
            valor: CurrencyFormatter.format(datos.saldoPendiente),
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _Linea({required this.etiqueta, required this.valor, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    final color = destacado
        ? AppColors.primarioOf(context)
        : AppColors.textoSecundarioOf(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: destacado ? 14 : 13,
            fontWeight: destacado ? FontWeight.w600 : FontWeight.w500,
            color: destacado ? AppColors.textoPrincipalOf(context) : color,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: destacado ? 19 : 13.5,
            fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
            color: destacado ? AppColors.primarioOf(context) : AppColors.textoPrincipalOf(context),
          ),
        ),
      ],
    );
  }
}

/// Con qué pagó el cliente el adelanto. El adelanto entra en la tabla de pagos
/// como el primer cobro, así que el método tiene que quedar registrado.
class _SelectorMetodoAdelanto extends StatelessWidget {
  final NuevaOrdenFormulario datos;
  final VoidCallback onCambio;

  const _SelectorMetodoAdelanto({required this.datos, required this.onCambio});

  static const List<List<String>> _metodos = [
    ['efectivo', 'Efectivo'],
    ['yape', 'Yape'],
    ['plin', 'Plin'],
    ['transferencia', 'Transferencia'],
    ['tarjeta', 'Tarjeta'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método del adelanto',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textoSecundarioOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final metodo in _metodos)
              ChoiceChip(
                label: Text(metodo[1]),
                selected: datos.metodoAdelanto == metodo[0],
                onSelected: (elegido) {
                  if (!elegido) return;
                  datos.metodoAdelanto = metodo[0];
                  onCambio();
                },
              ),
          ],
        ),
      ],
    );
  }
}
