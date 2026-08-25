import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/status_helper.dart';
import '../../data/models/orden_model.dart';
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: N° Orden + Fecha + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        orden.numeroOrdenDisplay,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.rojoClaro,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${DateFormatter.formatearFechaCorta(orden.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(estado: orden.estado),
                ],
              ),
              const SizedBox(height: 10),

              // Fila 2: Cliente
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cliente?.nombreCompleto ?? 'Cliente no asignado',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoPrincipal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Fila 3: Equipo y Desperfecto
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    tipoEquipoIcon,
                    size: 16,
                    color: AppColors.textoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipo != null
                              ? '${equipo.tipoFormateado}: ${equipo.nombreCompleto}'
                              : 'Sin equipo registrado',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textoPrincipal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (equipo?.desperfecto != null &&
                            equipo!.desperfecto!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              equipo.desperfecto!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textoMuted,
                                fontStyle: FontStyle.italic,
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
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.fondoBorde),
              const SizedBox(height: 8),

              // Fila 4: Totales Financieros
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${CurrencyFormatter.format(orden.subtotal)}',
                    style: const TextStyle(
                      fontSize: 12,
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
                          fontWeight: FontWeight.bold,
                          color: orden.saldoPendiente > 0
                              ? AppColors.secondary
                              : AppColors.tertiary,
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
    );
  }
}
