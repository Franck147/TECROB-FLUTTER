import 'package:flutter/material.dart';
import '../../core/utils/status_helper.dart';

class StatusBadge extends StatelessWidget {
  final String estado;
  final VoidCallback? onTap;
  final bool mostrarIcono;

  const StatusBadge({
    super.key,
    required this.estado,
    this.onTap,
    this.mostrarIcono = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = StatusHelper.obtenerColorFondo(estado);
    final textColor = StatusHelper.obtenerColorTexto(estado);
    final text = StatusHelper.obtenerTexto(estado);
    final iconData = StatusHelper.obtenerIconoEstado(estado);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.12),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarIcono) ...[
            Icon(iconData, color: textColor, size: 13),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6.5,
              height: 6.5,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: textColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: badge,
      );
    }
    return badge;
  }
}
