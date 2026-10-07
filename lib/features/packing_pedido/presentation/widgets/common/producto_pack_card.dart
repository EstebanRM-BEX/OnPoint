import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/info_linea_pack.dart';

/// Tarjeta de una línea del pedido. Sirve para "Por hacer", "Preparado" y
/// "Empacado": cambia qué cantidad se resalta y las acciones opcionales.
class ProductoPackCard extends StatelessWidget {
  final ProductoPacking producto;
  final VoidCallback? onTap;

  /// null = sin checkbox.
  final bool? seleccionado;
  final ValueChanged<bool>? onSeleccionar;
  final Widget? accion;

  const ProductoPackCard({
    super.key,
    required this.producto,
    this.onTap,
    this.seleccionado,
    this.onSeleccionar,
    this.accion,
  });

  static String fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final empezado = p.isPorHacer && (p.locationOk || p.productOk);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      elevation: 3,
      color: seleccionado == true
          ? primaryColorAppLigth
          : (empezado ? const Color(0xFFFFF8E1) : white),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (seleccionado != null)
                Checkbox(
                  value: seleccionado,
                  activeColor: primaryColorApp,
                  onChanged: (v) => onSeleccionar?.call(v ?? false),
                )
              else
                const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.productName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: black,
                      ),
                    ),
                    InfoLineaPack(etiqueta: 'Código', valor: p.productCode),
                    if (p.barcode.isNotEmpty)
                      InfoLineaPack(etiqueta: 'Barcode', valor: p.barcode),
                    if (p.tieneLote || p.loteName.isNotEmpty)
                      InfoLineaPack(
                        etiqueta: 'Lote',
                        valor: [
                          p.loteName,
                          if (p.expireDate.isNotEmpty) 'vence ${p.expireDate}',
                        ].where((e) => e.isNotEmpty).join(' · '),
                      ),
                    if (p.isPorHacer)
                      InfoLineaPack(
                        icono: Icons.location_on_outlined,
                        valor: p.locationName,
                        vacio: 'Sin ubicación',
                      ),
                    if (p.isEmpacado)
                      InfoLineaPack(
                        icono: Icons.inventory_2_outlined,
                        valor: p.packageName,
                      ),
                    if (p.unidades.isNotEmpty)
                      InfoLineaPack(
                        etiqueta: 'Unidad de medida',
                        valor: p.unidades,
                      ),
                    _Cantidades(producto: p),
                    if (p.observation.isNotEmpty &&
                        p.observation != 'Sin novedad')
                      InfoLineaPack(
                        etiqueta: 'Novedad',
                        valor: p.observation,
                        colorValor: Colors.orange[800],
                      ),
                    if (p.manejaTemperatura)
                      InfoLineaPack(
                        icono: Icons.thermostat,
                        valor: p.temperatura == 0
                            ? ''
                            : '${fmt(p.temperatura)} °',
                        vacio: 'Temperatura pendiente',
                      ),
                    if (p.isProductSplit)
                      const InfoLineaPack(
                        icono: Icons.call_split,
                        valor: 'Producto dividido',
                      ),
                  ],
                ),
              ),
              if (accion != null) accion!,
            ],
          ),
        ),
      ),
    );
  }
}

class _Cantidades extends StatelessWidget {
  final ProductoPacking producto;
  const _Cantidades({required this.producto});

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final fmt = ProductoPackCard.fmt;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 12,
        children: [
          Text(
            'Cantidad: ${fmt(p.quantity)}',
            style: TextStyle(fontSize: 12, color: primaryColorApp),
          ),
          if (!p.isPorHacer || p.quantitySeparate > 0)
            Text(
              '${p.isEmpacado ? 'Empacado' : 'Separado'}: '
              '${fmt(p.isPorHacer ? p.quantitySeparate : p.cantidadAEnviar)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: p.cantidadAEnviar < p.quantity && !p.isPorHacer
                    ? Colors.orange[800]
                    : green,
              ),
            ),
        ],
      ),
    );
  }
}
