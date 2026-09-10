import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/status_helper.dart';
import '../../data/models/orden_model.dart';
import 'custom_text_field.dart';

/// Corrige lo que se puede corregir de una orden ya creada.
///
/// Sin esto, un descuento mal puesto o un plazo cambiado por teléfono no
/// tenían arreglo desde la app: la orden se creaba y quedaba congelada.
class EditOrdenDialog extends StatefulWidget {
  final OrdenModel orden;
  final Future<bool> Function(Map<String, dynamic> cambios) onGuardar;

  const EditOrdenDialog({
    super.key,
    required this.orden,
    required this.onGuardar,
  });

  @override
  State<EditOrdenDialog> createState() => _EditOrdenDialogState();
}

class _EditOrdenDialogState extends State<EditOrdenDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descuento;
  late final TextEditingController _observaciones;
  late String _prioridad;
  DateTime? _fechaPrometida;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _descuento = TextEditingController(
      text: widget.orden.descuento == 0
          ? ''
          : widget.orden.descuento.toStringAsFixed(2),
    );
    _observaciones = TextEditingController(text: widget.orden.observaciones ?? '');
    _prioridad = StatusHelper.prioridades.containsKey(widget.orden.prioridad)
        ? widget.orden.prioridad
        : 'normal';
    final prometida = widget.orden.fechaPrometida;
    _fechaPrometida =
        prometida == null || prometida.isEmpty ? null : DateTime.tryParse(prometida);
  }

  @override
  void dispose() {
    _descuento.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  double get _montoDescuento {
    final texto = _descuento.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return 0;
    return double.tryParse(texto) ?? 0;
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaPrometida ?? hoy.add(const Duration(days: 2)),
      firstDate: hoy.subtract(const Duration(days: 365)),
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Fecha prometida de entrega',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (elegida != null) setState(() => _fechaPrometida = elegida);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final observaciones = _observaciones.text.trim();
    final cambios = <String, dynamic>{
      'prioridad': _prioridad,
      'descuento': _montoDescuento,
      'observaciones': observaciones.isEmpty ? null : observaciones,
      'fecha_prometida': _fechaPrometida == null
          ? null
          : DateFormatter.fechaAFormatoIso(_fechaPrometida!),
    };

    setState(() => _guardando = true);
    final ok = await widget.onGuardar(cambios);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.orden.subtotal;

    return AlertDialog(
      backgroundColor: AppColors.fondoTarjetaOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.fondoBordeOf(context)),
      ),
      title: Text(
        'Editar ${widget.orden.codigoVisual}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textoPrincipalOf(context),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prioridad',
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
                  for (final entrada in StatusHelper.prioridades.entries)
                    ChoiceChip(
                      label: Text(entrada.value),
                      selected: _prioridad == entrada.key,
                      onSelected: (elegido) {
                        if (!elegido) return;
                        setState(() => _prioridad = entrada.key);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _elegirFecha,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.fondoSuperficieOf(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.fondoBordeOf(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_outlined,
                          size: 20, color: AppColors.textoSecundarioOf(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fechaPrometida == null
                              ? 'Sin fecha prometida'
                              : DateFormatter.formatearFechaLarga(_fechaPrometida!),
                          style: TextStyle(
                            fontSize: 14,
                            color: _fechaPrometida == null
                                ? AppColors.textoMutedOf(context)
                                : AppColors.textoPrincipalOf(context),
                          ),
                        ),
                      ),
                      if (_fechaPrometida != null)
                        IconButton(
                          tooltip: 'Quitar fecha',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _fechaPrometida = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descuento,
                label: 'Descuento (S/)',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.percent_rounded,
                validator: (valor) {
                  final texto = (valor ?? '').trim().replaceAll(',', '.');
                  if (texto.isEmpty) return null;
                  final monto = double.tryParse(texto);
                  if (monto == null) return 'Escribe sólo números, por ejemplo 20.00';
                  if (monto < 0) return 'El descuento no puede ser negativo';
                  if (monto > subtotal + 0.01) {
                    return 'No puede superar el subtotal de '
                        '${CurrencyFormatter.format(subtotal)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _observaciones,
                label: 'Observaciones',
                hint: 'Lo que conviene recordar de esta orden',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar',
              style: TextStyle(color: AppColors.textoSecundarioOf(context))),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primario,
            foregroundColor: Colors.white,
          ),
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
