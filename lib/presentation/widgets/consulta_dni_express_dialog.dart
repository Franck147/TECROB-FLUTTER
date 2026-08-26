import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/dni_respuesta_model.dart';
import '../providers/app_providers.dart';
import 'custom_text_field.dart';

class ConsultaDniExpressDialog extends ConsumerStatefulWidget {
  const ConsultaDniExpressDialog({super.key});

  @override
  ConsumerState<ConsultaDniExpressDialog> createState() => _ConsultaDniExpressDialogState();
}

class _ConsultaDniExpressDialogState extends ConsumerState<ConsultaDniExpressDialog> {
  final _dniController = TextEditingController();
  bool _buscando = false;
  DniRespuestaModel? _resultado;
  String? _errorMensaje;

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _consultarDni() async {
    final dni = _dniController.text.replaceAll(RegExp(r'\D'), '').trim();
    if (dni.length != 8) {
      setState(() {
        _errorMensaje = 'Ingresa un número de DNI válido de 8 dígitos.';
        _resultado = null;
      });
      return;
    }

    setState(() {
      _buscando = true;
      _resultado = null;
      _errorMensaje = null;
    });

    final dniService = ref.read(dniServiceProvider);
    final respuesta = await dniService.consultarDni(dni);

    if (mounted) {
      setState(() {
        _buscando = false;
        if (respuesta != null && respuesta.nombres != null && respuesta.nombres!.isNotEmpty) {
          _resultado = respuesta;
          _errorMensaje = null;
        } else {
          _resultado = null;
          _errorMensaje = 'No se encontraron datos para el DNI $dni en RENIEC.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.fondoTarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.fondoBorde, width: 1.1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.rojoContenedor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.rojoPrimario.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.rojoClaro,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consulta Express RENIEC',
                        style: TextStyle(
                          color: AppColors.textoPrincipal,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Verificación directa de DNI ciudadano',
                        style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textoSecundario),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Input y botón de búsqueda
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _dniController,
                    label: 'Número de DNI',
                    hint: '8 dígitos...',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.search_rounded,
                    onChanged: (val) {
                      if (val.trim().length == 8) {
                        _consultarDni();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _buscando ? null : _consultarDni,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rojoPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _buscando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Resultados
            if (_buscando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: AppColors.rojoPrimario),
                ),
              )
            else if (_resultado != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fondoSuperficie,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.tertiary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'DNI: ${_resultado!.dni ?? _dniController.text}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Nombre Completo:',
                      style: TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                    ),
                    Text(
                      _resultado!.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nombres:',
                                  style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                              Text(_resultado!.nombres ?? '—',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Apellidos:',
                                  style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                              Text(_resultado!.apellidosCompletos,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (_errorMensaje != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fondoSuperficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.fondoBorde),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMensaje!,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textoSecundario),
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
}
