import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../nueva_orden_formulario.dart';
import 'wizard_widgets.dart';

/// Paso 1: identificación del cliente.
///
/// Lo mínimo indispensable queda a la vista (documento, nombres, celular) y el
/// correo se guarda en el bloque plegable de datos opcionales.
class PasoCliente extends StatelessWidget {
  final NuevaOrdenFormulario datos;

  /// Dispara la búsqueda del documento contra la base local y RENIEC.
  final ValueChanged<String> onBuscarDni;

  /// Notifica al asistente que debe redibujarse.
  final VoidCallback onCambio;

  const PasoCliente({
    super.key,
    required this.datos,
    required this.onBuscarDni,
    required this.onCambio,
  });

  void _limpiarCliente() {
    datos.dni.clear();
    datos.nombre.clear();
    datos.apellido.clear();
    datos.telefono.clear();
    datos.email.clear();
    datos.clienteSeleccionado = null;
    datos.dniMensaje = null;
    onCambio();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: datos.claveFormCliente,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TarjetaSeccion(
        titulo: 'Datos del cliente',
        subtitulo: 'Busca por documento o escribe los datos a mano',
        icono: Icons.person_search_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: datos.dni,
                    label: 'DNI (8 dígitos)',
                    hint: 'Opcional, acelera el registro',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.badge_outlined,
                    suffixIcon: datos.dni.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar datos del cliente',
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: _limpiarCliente,
                          ),
                    onChanged: (valor) {
                      onCambio();
                      if (valor.trim().length == 8) onBuscarDni(valor.trim());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  width: 52,
                  child: ElevatedButton(
                    onPressed: datos.buscandoDni ? null : () => onBuscarDni(datos.dni.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarioContenedorOf(context),
                      foregroundColor: AppColors.primarioOf(context),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: AppColors.primarioOf(context).withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: datos.buscandoDni
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primarioOf(context),
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 22),
                  ),
                ),
              ],
            ),
            if (datos.dniMensaje != null) ...[
              const SizedBox(height: 10),
              AvisoEnLinea(
                texto: datos.dniMensaje!,
                tono: datos.dniMensajeEsExito ? TonoAviso.exito : TonoAviso.alerta,
              ),
            ],
            const SizedBox(height: 16),
            CustomTextField(
              controller: datos.nombre,
              label: 'Nombres *',
              hint: 'Ej. Juan Carlos',
              textCapitalization: TextCapitalization.words,
              prefixIcon: Icons.person_outline_rounded,
              validator: (valor) =>
                  (valor == null || valor.trim().isEmpty) ? 'Ingresa el nombre del cliente' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: datos.apellido,
              label: 'Apellidos',
              hint: 'Ej. Pérez Quispe',
              textCapitalization: TextCapitalization.words,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: datos.telefono,
              label: 'Celular WhatsApp *',
              hint: 'Ej. 987654321',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_android_rounded,
              validator: (valor) {
                final digitos = (valor ?? '').replaceAll(RegExp(r'\D'), '');
                if (digitos.isEmpty) return 'Ingresa el celular para avisar al cliente';
                if (digitos.length < 6) return 'El número parece incompleto';
                return null;
              },
            ),
            const SizedBox(height: 14),
            BloquePlegable(
              titulo: 'Datos de contacto opcionales',
              icono: Icons.alternate_email_rounded,
              child: CustomTextField(
                controller: datos.email,
                label: 'Correo electrónico',
                hint: 'cliente@gmail.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                validator: (valor) {
                  final texto = (valor ?? '').trim();
                  if (texto.isEmpty) return null;
                  final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
                  return valido ? null : 'Revisa el formato del correo';
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
