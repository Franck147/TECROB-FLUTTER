import 'package:flutter/material.dart';
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
    return AlertDialog(
      title: const Text(
        'Cambiar Estado de la Orden',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: StatusHelper.todosLosEstados.map((estado) {
            final isCurrent = estado == estadoActual;
            final colorTexto = StatusHelper.obtenerColorTexto(estado);
            final colorFondo = StatusHelper.obtenerColorFondo(estado);
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
                  color: isCurrent ? colorTexto : Colors.white,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
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
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
