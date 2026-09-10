import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/status_helper.dart';
import '../../../widgets/custom_text_field.dart';
import '../nueva_orden_formulario.dart';
import 'wizard_widgets.dart';

/// Paso 2: el equipo que se recibe y la falla que reporta el cliente.
class PasoEquipo extends StatelessWidget {
  final NuevaOrdenFormulario datos;
  final VoidCallback onCambio;

  const PasoEquipo({super.key, required this.datos, required this.onCambio});

  /// Los mismos tipos que acepta la columna equipo.tipo.
  static const List<String> _tipos = [
    'laptop',
    'computadora',
    'impresora',
    'fotocopiadora',
    'tablet',
    'celular',
    'parlante',
    'otro',
  ];

  void _agregarAccesorioPersonalizado() {
    final texto = datos.accesorioPersonalizado.text.trim();
    if (texto.isEmpty) return;
    datos.accesorios.add(texto);
    datos.accesorioPersonalizado.clear();
    onCambio();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: datos.claveFormEquipo,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaSeccion(
            titulo: 'Equipo recibido',
            subtitulo: 'Qué entra al taller y con qué falla llega',
            icono: Icons.devices_other_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EtiquetaCampo('Tipo de equipo'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tipos.map((tipo) {
                    final seleccionado = datos.tipoEquipo == tipo;
                    return ChoiceChip(
                      avatar: Icon(
                        StatusHelper.obtenerIconoEquipo(tipo),
                        size: 16,
                        color: seleccionado
                            ? AppColors.primarioOf(context)
                            : AppColors.textoSecundarioOf(context),
                      ),
                      label: Text(StatusHelper.obtenerTipoEquipoTexto(tipo)),
                      selected: seleccionado,
                      onSelected: (activo) {
                        if (!activo) return;
                        datos.tipoEquipo = tipo;
                        onCambio();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: datos.marca,
                  label: 'Marca *',
                  hint: 'Ej. Lenovo, HP, Dell...',
                  textCapitalization: TextCapitalization.characters,
                  prefixIcon: Icons.sell_outlined,
                  validator: (valor) =>
                      (valor == null || valor.trim().isEmpty) ? 'Ingresa la marca del equipo' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: datos.modelo,
                  label: 'Modelo',
                  hint: 'Ej. ThinkPad E14',
                  textCapitalization: TextCapitalization.characters,
                  prefixIcon: Icons.numbers_rounded,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: datos.desperfecto,
                  label: 'Falla reportada *',
                  hint: 'Describe con las palabras del cliente...',
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Describe la falla que reporta el cliente'
                      : null,
                ),
                const SizedBox(height: 14),
                BloquePlegable(
                  titulo: 'Más detalles del equipo',
                  icono: Icons.description_outlined,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: datos.serie,
                        label: 'N° de serie',
                        hint: 'Opcional',
                        textCapitalization: TextCapitalization.characters,
                        prefixIcon: Icons.qr_code_2_rounded,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: datos.contrasena,
                        label: 'PIN o contraseña del equipo',
                        hint: 'Necesaria para poder probarlo',
                        prefixIcon: Icons.password_rounded,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: datos.descripcion,
                        label: 'Observaciones de recepción',
                        hint: 'Ej. Carcasa rayada, falta una tecla...',
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        prefixIcon: Icons.notes_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TarjetaSeccion(
            titulo: 'Accesorios entregados',
            subtitulo: 'Se imprime un sticker por cada accesorio',
            icono: Icons.cable_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NuevaOrdenFormulario.accesoriosSugeridos.map((accesorio) {
                    return FilterChip(
                      label: Text(accesorio),
                      selected: datos.accesorios.contains(accesorio),
                      onSelected: (activo) {
                        if (activo) {
                          datos.accesorios.add(accesorio);
                        } else {
                          datos.accesorios.remove(accesorio);
                        }
                        onCambio();
                      },
                    );
                  }).toList(),
                ),
                if (_accesoriosExtra.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _accesoriosExtra.map((accesorio) {
                      return InputChip(
                        label: Text(accesorio),
                        selected: true,
                        onDeleted: () {
                          datos.accesorios.remove(accesorio);
                          onCambio();
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: datos.accesorioPersonalizado,
                        label: 'Otro accesorio',
                        hint: 'Ej. Funda de cuero, cable HDMI...',
                        prefixIcon: Icons.add_box_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _agregarAccesorioPersonalizado,
                        child: const Text('Agregar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Accesorios escritos a mano, que no aparecen en la lista de sugeridos.
  List<String> get _accesoriosExtra => datos.accesorios
      .where((a) => !NuevaOrdenFormulario.accesoriosSugeridos.contains(a))
      .toList();
}
