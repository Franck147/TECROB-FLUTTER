import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Identidad visual de TecrobSys: la marca (robot + swoosh) acompañada del
/// logotipo "TECROBSYS".
///
/// El widget no gestiona su propia animación: recibe [progreso] entre 0 y 1
/// para que la pantalla que lo usa lo integre en su propia secuencia de
/// entrada. Con [progreso] en 1 se dibuja en su estado final y estático, de
/// modo que también sirve como logo fijo en cualquier otra pantalla.
class AnimatedLogo extends StatelessWidget {
  /// Avance de la animación de entrada, de 0 (oculto) a 1 (asentado).
  final double progreso;

  /// Alto de la marca gráfica en píxeles lógicos.
  final double tamanoMarca;

  /// Tamaño de fuente del logotipo "TECROBSYS".
  final double tamanoTexto;

  /// Dispone la marca y el logotipo en horizontal en vez de en vertical.
  final bool horizontal;

  /// Con false se dibuja sólo el logotipo, sin el robot.
  final bool mostrarMarca;

  const AnimatedLogo({
    super.key,
    this.progreso = 1.0,
    this.tamanoMarca = 96,
    this.tamanoTexto = 30,
    this.horizontal = false,
    this.mostrarMarca = true,
  });

  @override
  Widget build(BuildContext context) {
    final logotipo = _LogotipoAnimado(
      progreso: progreso,
      tamanoTexto: tamanoTexto,
    );

    if (!mostrarMarca) return logotipo;

    final marca = _MarcaAnimada(
      progreso: progreso,
      tamano: tamanoMarca,
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          marca,
          SizedBox(width: tamanoMarca * 0.14),
          logotipo,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        marca,
        SizedBox(height: tamanoMarca * 0.16),
        logotipo,
      ],
    );
  }
}

/// El robot con su swoosh. Entra creciendo desde el 82 % con un leve rebote y
/// arrastra un halo azul que se desvanece a medida que se asienta.
class _MarcaAnimada extends StatelessWidget {
  final double progreso;
  final double tamano;

  const _MarcaAnimada({required this.progreso, required this.tamano});

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutBack.transform(progreso.clamp(0.0, 1.0));
    final opacidad = Curves.easeOut.transform(progreso.clamp(0.0, 1.0));
    // El halo alcanza su punto álgido a media entrada y se apaga al final.
    final halo = math.sin(progreso.clamp(0.0, 1.0) * math.pi);

    return Opacity(
      opacity: opacidad,
      child: Transform.scale(
        scale: 0.82 + 0.18 * t,
        child: Container(
          height: tamano,
          width: tamano,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primarioOf(context)
                    .withValues(alpha: 0.30 * halo),
                blurRadius: tamano * 0.45,
                spreadRadius: tamano * 0.06,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_mark.png',
            height: tamano,
            width: tamano,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            // Si el asset falta, la pantalla sigue siendo usable.
            errorBuilder: (_, __, ___) => Icon(
              Icons.precision_manufacturing_rounded,
              size: tamano * 0.7,
              color: AppColors.primarioOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// "TECROBSYS" con las letras entrando escalonadas desde abajo.
///
/// "TECROB" toma el color de texto principal y "SYS" el azul de marca, igual
/// que en el logo impreso.
class _LogotipoAnimado extends StatelessWidget {
  final double progreso;
  final double tamanoTexto;

  static const String _texto = 'TECROBSYS';
  static const int _corte = 6; // TECROB | SYS

  const _LogotipoAnimado({required this.progreso, required this.tamanoTexto});

  @override
  Widget build(BuildContext context) {
    final letras = <Widget>[];
    for (var i = 0; i < _texto.length; i++) {
      // Cada letra ocupa una ventana del avance total, solapada con la
      // siguiente para que la cascada se vea continua.
      final inicio = i / (_texto.length * 1.6);
      final fin = inicio + (1 / _texto.length);
      final t = _ventana(progreso, inicio, fin);

      letras.add(
        Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * tamanoTexto * 0.55),
            child: Text(
              _texto[i],
              style: TextStyle(
                fontSize: tamanoTexto,
                fontWeight: FontWeight.w900,
                letterSpacing: tamanoTexto * 0.06,
                height: 1.05,
                color: i < _corte
                    ? AppColors.textoPrincipalOf(context)
                    : AppColors.primarioOf(context),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: letras,
    );
  }

  /// Normaliza [valor] dentro del tramo [inicio, fin] y le aplica una curva
  /// de salida suave.
  static double _ventana(double valor, double inicio, double fin) {
    if (fin <= inicio) return valor >= fin ? 1.0 : 0.0;
    final bruto = ((valor - inicio) / (fin - inicio)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(bruto);
  }
}
