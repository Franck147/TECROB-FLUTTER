import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/status_helper.dart';
import '../../data/models/orden_model.dart';
import 'imprimir_stickers_dialog.dart';
import 'status_badge.dart';

class OrdenCard extends StatelessWidget {
  final OrdenModel orden;
  final VoidCallback onTap;

  const OrdenCard({
    super.key,
    required this.orden,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cliente = orden.cliente;
    final equipo = orden.equipo;
    final tipoEquipoIcon = StatusHelper.obtenerIconoEquipo(equipo?.tipo);

    final listaAccesorios = (equipo?.accesorios != null && equipo!.accesorios!.trim().isNotEmpty)
        ? equipo.accesorios!
            .split(RegExp(r'[,;\n\+]'))
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList()
        : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila 1: Código de Orden + Fecha + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.rojoContenedor,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: AppColors.rojoPrimario.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            orden.numeroOrdenDisplay,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rojoClaro,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.formatearFechaCorta(orden.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textoSecundario,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(estado: orden.estado),
                  ],
                ),
                const SizedBox(height: 12),

                // Fila 2: Cliente
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.fondoSuperficie,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.fondoBorde),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cliente?.nombreCompleto ?? 'Cliente no asignado',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cliente?.telefono != null && cliente!.telefono!.isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.verdeWhatsapp,
                          size: 18,
                        ),
                        onPressed: () {
                          WhatsappService.enviarNotificacionEstado(
                            telefono: cliente.telefono!,
                            nombreCliente: cliente.nombreCompleto,
                            numeroOrden: orden.codigoVisual,
                            estado: orden.estado,
                          );
                        },
                        tooltip: 'Notificar por WhatsApp',
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Fila 3: Equipo y Desperfecto
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.fondoSuperficie,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.fondoBorde.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tipoEquipoIcon,
                        size: 18,
                        color: AppColors.rojoPrimario,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipo != null
                                  ? '${equipo.tipoFormateado}: ${equipo.nombreCompleto}'
                                  : 'Sin equipo asignado',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textoPrincipal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (equipo?.desperfecto != null && equipo!.desperfecto!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  equipo.desperfecto!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textoSecundario,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fila de Accesorios detectados (si tiene)
                if (listaAccesorios.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.fondoSuperficie,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.fondoBorde),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cable_rounded, size: 12, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              '${listaAccesorios.length} ${listaAccesorios.length == 1 ? 'Accesorio' : 'Accesorios'}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...listaAccesorios.take(2).map(
                            (acc) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.fondoPrincipal,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                acc,
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textoMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      if (listaAccesorios.length > 2)
                        Text(
                          '+${listaAccesorios.length - 2} más',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textoMuted),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.fondoBorde),
                const SizedBox(height: 10),

                // Fila 4: Totales Financieros & Botón de Stickers Bluetooth
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ${CurrencyFormatter.format(orden.subtotal)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Saldo: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textoSecundario,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(orden.saldoPendiente),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: orden.saldoPendiente > 0
                                    ? AppColors.secondary
                                    : AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Botón de Stickers Térmicos Bluetooth
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => ImprimirStickersDialog(orden: orden),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(
                              color: AppColors.rojoPrimario.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(
                            Icons.bluetooth_audio_rounded,
                            size: 15,
                            color: AppColors.rojoPrimario,
                          ),
                          label: const Text(
                            'Stickers',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textoPrincipal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
