import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/qr_paquete_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/packages/producto_en_paquete_tile.dart';

/// Caja del pedido con el diseño del módulo anterior: nombre con imprimir y
/// eliminar, consecutivo (y peso en cluster), cantidad de productos,
/// unidades totales y QR; en cluster, ubicación de destino y empaque. Al
/// abrirla muestra sus productos.
class PaquetePackCard extends StatelessWidget {
  final PaquetePacking paquete;
  final bool esCluster;
  final bool seleccionado;
  final bool expandido;
  final bool editable;
  final ValueChanged<bool> onSeleccionar;
  final VoidCallback onExpandir;
  final VoidCallback onImprimir;
  final VoidCallback onEliminar;
  final VoidCallback onAsignarUbicacion;
  final ValueChanged<ProductoPacking> onDesempacar;

  const PaquetePackCard({
    super.key,
    required this.paquete,
    required this.esCluster,
    required this.seleccionado,
    required this.expandido,
    required this.editable,
    required this.onSeleccionar,
    required this.onExpandir,
    required this.onImprimir,
    required this.onEliminar,
    required this.onAsignarUbicacion,
    required this.onDesempacar,
  });

  static const _negro = TextStyle(fontSize: 12, color: black);

  @override
  Widget build(BuildContext context) {
    final p = paquete;
    final unidades = p.productos.fold<double>(
      0,
      (s, prod) => s + prod.cantidadAEnviar,
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: seleccionado ? primaryColorAppLigth : white,
      elevation: 3,
      child: Column(
        children: [
          InkWell(
            onTap: onExpandir,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    activeColor: primaryColorApp,
                    value: seleccionado,
                    onChanged: (v) => onSeleccionar(v ?? false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColorApp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: onImprimir,
                              child: Icon(
                                Icons.print,
                                color: primaryColorApp,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (editable)
                              GestureDetector(
                                onTap: onEliminar,
                                child: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                  size: 25,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              p.consecutivo,
                              style: const TextStyle(
                                fontSize: 10,
                                color: black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (esCluster) ...[
                              Icon(
                                Icons.scale,
                                size: 12,
                                color: primaryColorApp,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                PackFormatos.cantidad(p.peso),
                                style: _negro,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cant. productos: ${p.cantidadProductos}',
                                  style: _negro,
                                ),
                                Text(
                                  'Unidades totales: '
                                  '${PackFormatos.cantidad(unidades)}',
                                  style: _negro,
                                ),
                              ],
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => showQrPaqueteDialog(context, p.name),
                              child: Icon(
                                Icons.qr_code,
                                color: primaryColorApp,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        if (esCluster) ...[
                          Text(
                            'Ubicación destino:\n'
                            '${p.locationDestName.isEmpty ? 'Sin asignar' : p.locationDestName}',
                            style: _negro,
                          ),
                          Row(
                            children: [
                              Text(
                                'Empaque: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColorApp,
                                ),
                              ),
                              Text(
                                p.typePaquete.isEmpty
                                    ? 'No asignado'
                                    : p.typePaquete,
                                style: _negro,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: [
                  if (esCluster && editable)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 8,
                      ),
                      child: ElevatedButton(
                        onPressed: onAsignarUbicacion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Asignar ubicación de destino',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (p.productos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Sin productos en el dispositivo',
                        style: TextStyle(color: grey, fontSize: 12),
                      ),
                    ),
                  for (final prod in p.productos)
                    ProductoEnPaqueteTile(
                      producto: prod,
                      onDesempacar: editable ? () => onDesempacar(prod) : null,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
