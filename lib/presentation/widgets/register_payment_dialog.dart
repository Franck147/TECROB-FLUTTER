import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'custom_text_field.dart';

class RegisterPaymentDialog extends StatefulWidget {
  final double saldoPendiente;
  final Function(double monto, String metodo, String? nota) onSave;

  const RegisterPaymentDialog({
    super.key,
    required this.saldoPendiente,
    required this.onSave,
  });

  @override
  State<RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<RegisterPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _notaController = TextEditingController();
  String _metodoSeleccionado = 'efectivo';

  final List<Map<String, String>> _metodos = [
    {'id': 'efectivo', 'label': 'Efectivo'},
    {'id': 'yape', 'label': 'Yape'},
    {'id': 'plin', 'label': 'Plin'},
    {'id': 'transferencia', 'label': 'Transferencia'},
    {'id': 'tarjeta', 'label': 'Tarjeta'},
  ];

  @override
  void initState() {
    super.initState();
    // Sugerir el saldo pendiente completo como monto por defecto
    if (widget.saldoPendiente > 0) {
      _montoController.text = widget.saldoPendiente.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;
    if (monto <= 0) return;

    final nota = _notaController.text.trim().isNotEmpty
        ? _notaController.text.trim()
        : null;

    widget.onSave(monto, _metodoSeleccionado, nota);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.fondoTarjetaOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.fondoBordeOf(context)),
      ),
      title: Row(
        children: [
          const Icon(Icons.payment_rounded, color: AppColors.rojoPrimario, size: 22),
          const SizedBox(width: 8),
          Text(
            'Registrar Pago',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textoPrincipalOf(context),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _montoController,
                label: 'Monto (S/) *',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa un monto';
                  }
                  final n = double.tryParse(val.trim());
                  if (n == null || n <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Método de pago:',
                style: TextStyle(fontSize: 13, color: AppColors.textoSecundarioOf(context)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _metodos.map((m) {
                  final isSelected = _metodoSeleccionado == m['id'];
                  return ChoiceChip(
                    label: Text(m['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _metodoSeleccionado = m['id']!;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notaController,
                label: 'Nota / Referencia (opcional)',
                hint: 'Ej. N° de operación Yape...',
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundarioOf(context))),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.rojoPrimario,
            foregroundColor: Colors.white,
          ),
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
