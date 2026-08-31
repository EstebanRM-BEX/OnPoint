import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';

class RecepcionPoolItemCardWidget extends StatelessWidget {
  const RecepcionPoolItemCardWidget({
    super.key,
    required this.item,
    required this.companyId,
    required this.mostrarCantidad,
  });

  final RecepcionPoolItem item;

  /// Almacén de la sesión (warehouse_id); se usa como company_id al imprimir.
  final dynamic companyId;

  /// Espejo del permiso hideExpectedQty (tbl_configurations): si está
  /// desactivado, no se muestran "Disponible"/"Solicitado".
  final bool mostrarCantidad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        elevation: 3,
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName ?? '',
                      style: TextStyle(
                        color: primaryColorApp,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.print, color: primaryColorApp, size: 20),
                    tooltip: 'Imprimir etiqueta',
                    onPressed: item.productId == null
                        ? null
                        : () => ModalPrintersList.show(
                            context,
                            resIds: [item.productId],
                            companyId: companyId ?? 1,
                          ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Código: ${item.defaultCode ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: black),
                  ),
                  const SizedBox(width: 12),
                  SvgPicture.asset(
                    'assets/icons/barcode.svg',
                    width: 15,
                    height: 15,
                    color: primaryColorApp,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.barcode ?? '-',
                      style: const TextStyle(fontSize: 12, color: black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (mostrarCantidad) ...[
                Text(
                  'Disponible: ${item.qtyAvailable ?? 0} ${item.uom ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (item.qtyAvailable ?? 0) > 0 ? green : red,
                  ),
                ),
                Text(
                  'Solicitado: ${item.qtyDemanded ?? 0} ${item.uom ?? ''}',
                  style: const TextStyle(fontSize: 12, color: black),
                ),
              ],
              if ((item.asignacionesActivas ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline, color: yellow, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item.asignacionesActivas} operario(s) trabajándolo',
                      style: const TextStyle(fontSize: 11, color: yellow),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
