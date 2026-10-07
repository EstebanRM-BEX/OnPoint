import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/info_linea_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/producto_pack_card.dart';

/// Caja del pedido: datos, selección, imprimir, eliminar y, abierta, sus
/// productos con la opción de desempacar cada uno.
class PaquetePackCard extends StatelessWidget {
  final PaquetePacking paquete;
  final bool seleccionado;
  final bool expandido;
  final bool editable;
  final ValueChanged<bool> onSeleccionar;
  final VoidCallback onExpandir;
  final VoidCallback onImprimir;
  final VoidCallback onEliminar;
  final ValueChanged<ProductoPacking> onDesempacar;

  const PaquetePackCard({
    super.key,
    required this.paquete,
    required this.seleccionado,
    required this.expandido,
    required this.editable,
    required this.onSeleccionar,
    required this.onExpandir,
    required this.onImprimir,
    required this.onEliminar,
    required this.onDesempacar,
  });

  @override
  Widget build(BuildContext context) {
    final p = paquete;
    final fmt = ProductoPackCard.fmt;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      elevation: 3,
      color: seleccionado ? primaryColorAppLigth : white,
      child: Column(
        children: [
          InkWell(
            onTap: onExpandir,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Row(
                children: [
                  Checkbox(
                    value: seleccionado,
                    activeColor: primaryColorApp,
                    onChanged: (v) => onSeleccionar(v ?? false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            p.name,
                            if (p.consecutivo.isNotEmpty) p.consecutivo,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColorApp,
                          ),
                        ),
                        InfoLineaPack(
                          etiqueta: 'Barcode',
                          valor: p.packingBarcode,
                        ),
                        InfoLineaPack(
                          etiqueta: 'Productos',
                          valor: '${p.cantidadProductos}',
                        ),
                        if (p.typePaquete.isNotEmpty || p.peso > 0)
                          InfoLineaPack(
                            etiqueta: 'Empaque',
                            valor: [
                              p.typePaquete,
                              if (p.peso > 0) '${fmt(p.peso)} kg',
                            ].where((e) => e.isNotEmpty).join(' · '),
                          ),
                        InfoLineaPack(
                          icono: Icons.location_on,
                          valor: p.locationDestName,
                          vacio: 'Sin ubicación de destino',
                        ),
                        Row(
                          children: [
                            Icon(
                              p.isSticker ? Icons.verified : Icons.label_off,
                              size: 14,
                              color: p.isSticker ? green : grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.isSticker ? 'Con sticker' : 'Sin sticker',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Imprimir',
                    icon: Icon(Icons.print, color: primaryColorApp),
                    onPressed: onImprimir,
                  ),
                  if (editable)
                    IconButton(
                      tooltip: 'Eliminar paquete',
                      icon: const Icon(Icons.delete_forever, color: red),
                      onPressed: onEliminar,
                    ),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: primaryColorApp,
                  ),
                ],
              ),
            ),
          ),
          if (expandido)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                children: [
                  const Divider(height: 1),
                  if (p.productos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Sin productos en el dispositivo',
                        style: TextStyle(color: grey, fontSize: 12),
                      ),
                    ),
                  for (final prod in p.productos)
                    ProductoPackCard(
                      producto: prod,
                      accion: editable
                          ? IconButton(
                              tooltip: 'Desempacar',
                              icon: const Icon(Icons.unarchive, color: red),
                              onPressed: () => onDesempacar(prod),
                            )
                          : null,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
