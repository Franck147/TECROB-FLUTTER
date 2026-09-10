import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/orden_model.dart';

/// Cómo queda la cuenta del cliente en el momento de entregarle el equipo.
enum EstadoSaldoRecojo {
  /// No hay nada que cobrar ni que devolver.
  pagado,

  /// Queda saldo por cobrar antes de entregar.
  porCobrar,

  /// El cliente pagó de más y hay que devolverle la diferencia.
  aFavor;

  /// Los céntimos de redondeo no cuentan como deuda ni como saldo a favor.
  static EstadoSaldoRecojo desde(double saldo) {
    if (saldo.abs() < 0.01) return pagado;
    return saldo > 0 ? porCobrar : aFavor;
  }
}

/// Las órdenes terminadas que esperan a que el cliente venga por su equipo.
///
/// Cada fila antepone cuánto lleva esperando, porque es lo que decide a quién
/// avisar primero, y cierra con el estado de la cuenta, que es lo que decide
/// si hay que cobrar al entregar. La lista se recorta a [maxVisibles] para que
/// el dashboard no se convierta en un listado largo.
class ListasPorRecogerCard extends StatefulWidget {
  final List<OrdenModel> ordenes;
  final ValueChanged<OrdenModel> onAvisar;
  final ValueChanged<OrdenModel> onAbrirOrden;
  final int maxVisibles;

  const ListasPorRecogerCard({
    super.key,
    required this.ordenes,
    required this.onAvisar,
    required this.onAbrirOrden,
    this.maxVisibles = 5,
  });

  @override
  State<ListasPorRecogerCard> createState() => _ListasPorRecogerCardState();
}

class _ListasPorRecogerCardState extends State<ListasPorRecogerCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final ordenadas = [...widget.ordenes]
      ..sort((a, b) => b.diasEsperandoRecojo.compareTo(a.diasEsperandoRecojo));

    final ocultas = ordenadas.length - widget.maxVisibles;
    final visibles = _expandido || ocultas <= 0
        ? ordenadas
        : ordenadas.take(widget.maxVisibles).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondoTarjetaOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.verdeWhatsapp.withValues(alpha: isDark ? 0.35 : 0.4),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.verdeWhatsapp.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < visibles.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 14,
                endIndent: 14,
                color: AppColors.fondoBordeOf(context),
              ),
            _FilaRecojo(
              orden: visibles[i],
              onAvisar: widget.onAvisar,
              onAbrirOrden: widget.onAbrirOrden,
            ),
          ],
          if (ocultas > 0) _buildPieExpansor(context, ocultas),
        ],
      ),
    );
  }

  Widget _buildPieExpansor(BuildContext context, int ocultas) {
    final etiqueta = _expandido
        ? 'Ver menos'
        : 'Ver ${ocultas == 1 ? 'la restante' : 'las $ocultas restantes'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fondoSuperficieOf(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: TextButton.icon(
        onPressed: () => setState(() => _expandido = !_expandido),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primarioOf(context),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
          ),
        ),
        icon: Icon(
          _expandido
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 18,
        ),
        label: Text(
          etiqueta,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Una orden lista: antigüedad, quién es, qué equipo, cuánto se cobra y el
/// atajo para avisar por WhatsApp.
class _FilaRecojo extends StatelessWidget {
  final OrdenModel orden;
  final ValueChanged<OrdenModel> onAvisar;
  final ValueChanged<OrdenModel> onAbrirOrden;

  const _FilaRecojo({
    required this.orden,
    required this.onAvisar,
    required this.onAbrirOrden,
  });

  @override
  Widget build(BuildContext context) {
    final equipo = orden.equipo?.nombreCompleto ?? 'Equipo';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('recojo-fila-${orden.id}'),
        onTap: () => onAbrirOrden(orden),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // En pantallas angostas la etiqueta de saldo no cabe junto al
              // nombre, así que baja a la línea del equipo.
              final angosta = constraints.maxWidth < 520;

              return Row(
                children: [
                  _InsigniaEspera(dias: orden.diasEsperandoRecojo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key: const Key('recojo-titulo-fila'),
                          '${orden.codigoVisual} • ${orden.clienteNombreCompleto}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: AppColors.textoPrincipalOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                equipo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textoSecundarioOf(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (angosta) ...[
                              const SizedBox(width: 8),
                              _EtiquetaSaldo(saldo: orden.saldoPendiente),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!angosta) ...[
                    const SizedBox(width: 10),
                    _EtiquetaSaldo(saldo: orden.saldoPendiente),
                  ],
                  const SizedBox(width: 10),
                  _BotonAvisar(
                    key: Key('recojo-avisar-${orden.id}'),
                    onPressed: () => onAvisar(orden),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Cuánto lleva esperando el equipo. Verde recién terminado, ámbar cuando ya
/// van varios días y rojo cuando lleva más de una semana en el mostrador.
class _InsigniaEspera extends StatelessWidget {
  final int dias;

  const _InsigniaEspera({required this.dias});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final Color color;
    if (dias >= 6) {
      color = AppColors.errorOf(context);
    } else if (dias >= 2) {
      color = AppColors.avisoOf(context);
    } else {
      color = AppColors.exitoOf(context);
    }

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        dias == 0 ? 'hoy' : '${dias}d',
        style: TextStyle(
          fontSize: dias >= 100 ? 10 : 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// El estado de la cuenta al entregar, en una sola etiqueta de color.
class _EtiquetaSaldo extends StatelessWidget {
  final double saldo;

  const _EtiquetaSaldo({required this.saldo});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final estado = EstadoSaldoRecojo.desde(saldo);

    final Color color;
    final String texto;
    switch (estado) {
      case EstadoSaldoRecojo.pagado:
        color = AppColors.exitoOf(context);
        texto = 'Pagado';
      case EstadoSaldoRecojo.porCobrar:
        color = AppColors.avisoOf(context);
        texto = 'Cobrar ${CurrencyFormatter.format(saldo)}';
      case EstadoSaldoRecojo.aFavor:
        color = AppColors.primarioOf(context);
        texto = 'A favor ${CurrencyFormatter.format(saldo.abs())}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// El atajo a WhatsApp, reducido a un botón redondo para que una lista larga
/// no se convierta en una columna de botones verdes.
class _BotonAvisar extends StatelessWidget {
  final VoidCallback onPressed;

  const _BotonAvisar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Avisar por WhatsApp',
      child: Material(
        color: AppColors.verdeWhatsapp,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.chat_rounded, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
