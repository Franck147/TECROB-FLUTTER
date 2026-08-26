import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sticker_label_service.dart';
import '../../data/models/orden_model.dart';

class ImprimirStickersDialog extends StatefulWidget {
  final OrdenModel orden;

  const ImprimirStickersDialog({
    super.key,
    required this.orden,
  });

  @override
  State<ImprimirStickersDialog> createState() => _ImprimirStickersDialogState();
}

class _ImprimirStickersDialogState extends State<ImprimirStickersDialog> {
  late List<StickerItem> _todosLosItems;
  late Set<int> _indicesSeleccionados;
  bool _imprimiendo = false;

  @override
  void initState() {
    super.initState();
    _todosLosItems = StickerLabelService.generarListaStickers(widget.orden);
    _indicesSeleccionados = Set.from(List.generate(_todosLosItems.length, (i) => i));
  }

  Future<void> _ejecutarImpresion() async {
    if (_indicesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un sticker para imprimir')),
      );
      return;
    }

    setState(() => _imprimiendo = true);
    try {
      final itemsAImprimir = _indicesSeleccionados.map((i) => _todosLosItems[i]).toList();
      await StickerLabelService.imprimirStickers(
        items: itemsAImprimir,
        tituloTrabajo: 'Stickers_${widget.orden.codigoVisual}',
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al imprimir stickers: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _imprimiendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cantidad = _indicesSeleccionados.length;

    return Dialog(
      backgroundColor: AppColors.fondoTarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.fondoBorde, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 650),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con icono Bluetooth / Térmica
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
                    Icons.bluetooth_audio_rounded,
                    color: AppColors.rojoPrimario,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Imprimir Stickers Térmicos',
                        style: TextStyle(
                          color: AppColors.textoPrincipal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Orden ${widget.orden.codigoVisual} • Rotulado de accesorios',
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 12,
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

            // Vista previa estilo Sticker Adhesivo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TECROBSYS',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'STICKER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.orden.codigoVisual,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Cli: ${widget.orden.clienteNombreCompleto}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black87, fontSize: 9.5),
                        ),
                        Text(
                          widget.orden.equipo?.nombreCompleto ?? 'Equipo Técnico',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 46),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Selector de qué accesorios incluir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Etiquetas para imprimir:',
                  style: TextStyle(
                    color: AppColors.textoPrincipal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_indicesSeleccionados.length == _todosLosItems.length) {
                        _indicesSeleccionados.clear();
                      } else {
                        _indicesSeleccionados =
                            Set.from(List.generate(_todosLosItems.length, (i) => i));
                      }
                    });
                  },
                  child: Text(
                    _indicesSeleccionados.length == _todosLosItems.length
                        ? 'Deseleccionar todo'
                        : 'Seleccionar todo',
                    style: const TextStyle(color: AppColors.rojoPrimario, fontSize: 12),
                  ),
                ),
              ],
            ),

            // Lista de Ítems
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _todosLosItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = _todosLosItems[index];
                  final isSelected = _indicesSeleccionados.contains(index);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _indicesSeleccionados.remove(index);
                        } else {
                          _indicesSeleccionados.add(index);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.fondoSuperficie : AppColors.fondoPrincipal,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.rojoPrimario.withValues(alpha: 0.5)
                              : AppColors.fondoBorde,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: isSelected ? AppColors.rojoPrimario : AppColors.textoMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.titulo,
                                  style: TextStyle(
                                    color: item.esPrincipal
                                        ? AppColors.rojoPrimario
                                        : AppColors.textoPrincipal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item.subtitulo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.sell_outlined,
                            color: AppColors.textoMuted,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Botón de Acción Principal
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _imprimiendo ? null : _ejecutarImpresion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rojoPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.rojoPrimario.withValues(alpha: 0.4),
                ),
                icon: _imprimiendo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_rounded, size: 20),
                label: Text(
                  _imprimiendo
                      ? 'Preparando Impresión...'
                      : 'Imprimir $cantidad ${cantidad == 1 ? 'Sticker' : 'Stickers'} (Bluetooth / POS)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
