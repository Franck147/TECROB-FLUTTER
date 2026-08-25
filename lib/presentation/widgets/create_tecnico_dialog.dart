import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class CreateTecnicoDialog extends StatefulWidget {
  final Function({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String rol,
  }) onSave;

  const CreateTecnicoDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<CreateTecnicoDialog> createState() => _CreateTecnicoDialogState();
}

class _CreateTecnicoDialogState extends State<CreateTecnicoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _rolSeleccionado = 'tecnico';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      rol: _rolSeleccionado,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Nuevo Técnico',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nombreController,
                label: 'Nombre *',
                textCapitalization: TextCapitalization.words,
                prefixIcon: Icons.person_outline,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el nombre';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _apellidoController,
                label: 'Apellido *',
                textCapitalization: TextCapitalization.words,
                prefixIcon: Icons.person_outline,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el apellido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emailController,
                label: 'Correo Electrónico *',
                hint: 'tecnico@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el correo';
                  if (!val.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _passwordController,
                label: 'Contraseña de acceso *',
                hint: 'Mínimo 6 caracteres',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa una contraseña';
                  if (val.trim().length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _rolSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Rol en el Sistema *',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
                  DropdownMenuItem(value: 'administrador', child: Text('Administrador')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _rolSeleccionado = val;
                    });
                  }
                },
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
          child: const Text('Crear Usuario'),
        ),
      ],
    );
  }
}
