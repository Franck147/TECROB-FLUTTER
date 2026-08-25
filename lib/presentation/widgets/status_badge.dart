import 'package:flutter/material.dart';
import '../../core/utils/status_helper.dart';

class StatusBadge extends StatelessWidget {
  final String estado;
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    required this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = StatusHelper.obtenerColorFondo(estado);
    final textColor = StatusHelper.obtenerColorTexto(estado);
    final text = StatusHelper.obtenerTexto(estado);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
