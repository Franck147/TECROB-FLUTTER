import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/status_helper.dart';

class ChangeStatusDialog extends StatelessWidget {
  final String estadoActual;
  final Function(String nuevoEstado) onSelectStatus;

  const ChangeStatusDialog({
    super.key,
    required this.estadoActual,
    required this.onSelectStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return AlertDialog(
      backgroundColor: AppColors.fondoTarjetaOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.fondoBordeOf(context)),
      ),
      title: Text(
        'Cambiar Estado de la Orden',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textoPrincipalOf(context),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: StatusHelper.todosLosEstados.map((estado) {
            final isCurrent = estado == estadoActual;
            final colorTexto = StatusHelper.obtenerColorTexto(estado, isDark: isDark);
            final colorFondo = StatusHelper.obtenerColorFondo(estado, isDark: isDark);
            final label = StatusHelper.obtenerTexto(estado);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorTexto,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                label,
                style: TextStyle(
                  color: isCurrent ? colorTexto : AppColors.textoPrincipalOf(context),
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isCurrent
                  ? Icon(Icons.check_rounded, color: colorTexto, size: 20)
                  : null,
              tileColor: isCurrent ? colorFondo : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                Navigator.of(context).pop();
                if (!isCurrent) {
                  onSelectStatus(estado);
                }
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundarioOf(context))),
        ),
      ],
    );
  }
}
