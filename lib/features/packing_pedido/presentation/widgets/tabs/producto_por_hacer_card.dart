import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';

/// Tarjeta de producto de "Por hacer", con el mismo diseño que el módulo de
/// packing por pedido anterior: nombre, ubicación (con ícono de
/// temperatura), pedido con imprimir, cantidad y unidad de medida, y lote
/// si el producto lo maneja.
class ProductoPorHacerCard extends StatelessWidget {
  final ProductoPacking producto;

  /// null = sin checkbox (sin permiso para empacar sin escanear).
  final bool? seleccionado;
  final ValueChanged<bool>? onSeleccionar;
  final VoidCallback? onTap;
  final VoidCallback onImprimir;

  const ProductoPorHacerCard({
    super.key,
    required this.producto,
    required this.onImprimir,
    this.seleccionado,
    this.onSeleccionar,
    this.onTap,
  });

  static const _valor = TextStyle(fontSize: 12, color: black);
  TextStyle get _etiqueta => TextStyle(fontSize: 12, color: primaryColorApp);

  @override
  Widget build(BuildContext context) {
    final p = producto;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        color: seleccionado == true ? primaryColorAppLigth : Colors.white,
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (seleccionado != null)
                Checkbox(
                  value: seleccionado,
                  onChanged: (v) => onSeleccionar?.call(v ?? false),
                ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.productName, style: _valor),
                      Row(
                        children: [
                          Text('Ubicación: ', style: _etiqueta),
                          const Spacer(),
                          if (p.manejaTemperatura)
                            Icon(
                              Icons.thermostat_outlined,
                              color: primaryColorApp,
                              size: 16,
                            ),
                        ],
                      ),
                      Text(p.locationName, style: _valor),
                      Row(
                        children: [
                          Text('Pedido: ', style: _etiqueta),
                          Text('${p.pedidoId}', style: _valor),
                          const Spacer(),
                          GestureDetector(
                            onTap: onImprimir,
                            child: Icon(
                              Icons.print,
                              color: primaryColorApp,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 3),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Cantidad: ', style: _etiqueta),
                          Text(
                            PackFormatos.cantidad(p.quantity),
                            style: _valor,
                          ),
                          const Spacer(),
                          Text('Unidad de medida: ', style: _etiqueta),
                          Text(p.unidades, style: _valor),
                        ],
                      ),
                      if (p.tracking == 'lot') ...[
                        Text('Número de serie/lote: ', style: _etiqueta),
                        Text(
                          p.loteName.isEmpty ? 'Sin lote' : p.loteName,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.loteName.isEmpty ? Colors.red : black,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
