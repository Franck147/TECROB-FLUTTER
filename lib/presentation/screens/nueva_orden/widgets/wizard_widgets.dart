import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Barra de progreso del asistente: un círculo numerado por paso, unidos por
/// una línea que se pinta de azul conforme se avanza.
class BarraPasos extends StatelessWidget {
  final int pasoActual;
  final List<String> etiquetas;
  final ValueChanged<int>? onTocarPaso;

  const BarraPasos({
    super.key,
    required this.pasoActual,
    required this.etiquetas,
    this.onTocarPaso,
  });

  @override
  Widget build(BuildContext context) {
    final azul = AppColors.primarioOf(context);
    final borde = AppColors.fondoBordeOf(context);

    return Row(
      children: List<Widget>.generate(etiquetas.length * 2 - 1, (i) {
        // Los índices impares son las líneas de unión entre círculos.
        if (i.isOdd) {
          final indiceLinea = (i - 1) ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: indiceLinea < pasoActual ? azul : borde,
            ),
          );
        }

        final indice = i ~/ 2;
        final completado = indice < pasoActual;
        final activo = indice == pasoActual;
        final alcanzable = indice <= pasoActual;

        return GestureDetector(
          onTap: alcanzable && onTocarPaso != null ? () => onTocarPaso!(indice) : null,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: activo || completado ? azul : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activo || completado ? azul : borde,
                    width: 1.6,
                  ),
                ),
                alignment: Alignment.center,
                child: completado
                    ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                    : Text(
                        '${indice + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: activo ? Colors.white : AppColors.textoMutedOf(context),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                etiquetas[indice],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                  color: activo ? azul : AppColors.textoSecundarioOf(context),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Tarjeta blanca con título e ícono, el contenedor base de cada sección.
class TarjetaSeccion extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final IconData icono;
  final Widget child;

  const TarjetaSeccion({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.icono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fondoBordeOf(context), width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primarioContenedorOf(context),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icono, color: AppColors.primarioOf(context), size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipalOf(context),
                      ),
                    ),
                    if (subtitulo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitulo!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textoSecundarioOf(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Bloque plegable para los campos opcionales, cerrado por defecto.
class BloquePlegable extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final Widget child;

  const BloquePlegable({
    super.key,
    required this.titulo,
    this.icono = Icons.tune_rounded,
    required this.child,
  });

  @override
  State<BloquePlegable> createState() => _BloquePlegableState();
}

class _BloquePlegableState extends State<BloquePlegable> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficieOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fondoBordeOf(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(widget.icono, size: 17, color: AppColors.textoSecundarioOf(context)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoSecundarioOf(context),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _abierto ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 21,
                      color: AppColors.textoSecundarioOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_abierto)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// Aviso breve en línea. El tono decide el color: informativo, éxito o alerta.
enum TonoAviso { info, exito, alerta }

class AvisoEnLinea extends StatelessWidget {
  final String texto;
  final TonoAviso tono;

  const AvisoEnLinea({super.key, required this.texto, this.tono = TonoAviso.info});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icono;

    if (tono == TonoAviso.exito) {
      color = AppColors.exitoOf(context);
      icono = Icons.check_circle_outline_rounded;
    } else if (tono == TonoAviso.alerta) {
      color = AppColors.avisoOf(context);
      icono = Icons.error_outline_rounded;
    } else {
      color = AppColors.textoSecundarioOf(context);
      icono = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta corta que encabeza un grupo de campos.
class EtiquetaCampo extends StatelessWidget {
  final String texto;

  const EtiquetaCampo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textoSecundarioOf(context),
        ),
      ),
    );
  }
}
