import 'package:flutter/material.dart';
import '../../data/models/servicio_catalogo_model.dart';
import 'custom_text_field.dart';

class CreateServiceDialog extends StatefulWidget {
  final ServicioCatalogoModel? servicioExistente;
  final Function(Map<String, dynamic> datos) onSave;

  const CreateServiceDialog({
    super.key,
    this.servicioExistente,
    required this.onSave,
  });

  @override
  State<CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<CreateServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descController = TextEditingController();
  String _categoriaSeleccionada = 'mantenimiento';

  final List<Map<String, String>> _categorias = [
    {'id': 'mantenimiento', 'label': 'Mantenimiento'},
    {'id': 'reparacion', 'label': 'Reparación'},
    {'id': 'software', 'label': 'Software'},
    {'id': 'repuesto', 'label': 'Repuesto'},
    {'id': 'diagnostico', 'label': 'Diagnóstico'},
    {'id': 'otro', 'label': 'Otro'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.servicioExistente != null) {
      final s = widget.servicioExistente!;
      _nombreController.text = s.nombre;
      _precioController.text = s.precioBase.toStringAsFixed(2);
      _descController.text = s.descripcion ?? '';
      _categoriaSeleccionada = s.categoria;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text.trim()) ?? 0.0;
    final desc = _descController.text.trim().isNotEmpty ? _descController.text.trim() : null;

    final datos = {
      'nombre': nombre,
      'precio_base': precio,
      'categoria': _categoriaSeleccionada,
      'descripcion': desc,
    };

    widget.onSave(datos);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.servicioExistente != null;

    return AlertDialog(
      title: Text(
        esEdicion ? 'Editar Servicio' : 'Nuevo Servicio',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nombreController,
                label: 'Nombre del servicio *',
                hint: 'Ej. Formateo y Mantenimiento',
                textCapitalization: TextCapitalization.sentences,
                prefixIcon: Icons.handyman_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el nombre del servicio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _precioController,
                label: 'Precio base (S/) *',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el precio';
                  }
                  final n = double.tryParse(val.trim());
                  if (n == null || n < 0) {
                    return 'Precio inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                items: _categorias.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['id'],
                    child: Text(c['label']!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _categoriaSeleccionada = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descController,
                label: 'Descripción (opcional)',
                hint: 'Detalles del servicio...',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(esEdicion ? 'Guardar Cambios' : 'Agregar'),
        ),
      ],
    );
  }
}
