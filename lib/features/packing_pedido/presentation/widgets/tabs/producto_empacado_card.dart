import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';

/// Tarjeta de "Listo" con el diseño del módulo anterior: recuadro con
/// certificado, unidades, temperatura, cantidad empacada (con imagen del
/// producto), paquete y novedad; debajo lote, peso con imprimir y tiempo.
class ProductoEmpacadoCard extends StatelessWidget {
  final ProductoPacking producto;
  final VoidCallback onImprimir;
  final VoidCallback onVerImagenProducto;

  const ProductoEmpacadoCard({
    super.key,
    required this.producto,
    required this.onImprimir,
    required this.onVerImagenProducto,
  });

  static const _valor = TextStyle(fontSize: 12, color: black);
  TextStyle get _etiqueta => TextStyle(fontSize: 12, color: primaryColorApp);

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final fmt = PackFormatos.cantidad;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        color: Colors.green[100],
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _valor,
              ),
              Card(
                elevation: 3,
                color: white,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Certificado: ', style: _etiqueta),
                          Text(p.certificado ? 'Si' : 'No', style: _valor),
                          const Spacer(),
                          Text('Unidades: ', style: _etiqueta),
                          Text(p.unidades, style: _valor),
                        ],
                      ),
                      if (p.manejaTemperatura)
                        Row(
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: primaryColorApp,
                              size: 15,
                            ),
                            Text('Temperatura: ', style: _etiqueta),
                            Text(fmt(p.temperatura), style: _valor),
                            const Spacer(),
                            if (p.image.isNotEmpty)
                              GestureDetector(
                                onTap: () => showImageDialog(context, p.image),
                                child: Icon(
                                  Icons.image,
                                  color: primaryColorApp,
                                  size: 23,
                                ),
                              ),
                          ],
                        ),
                      Row(
                        children: [
                          Text('Cantidad empacada: ', style: _etiqueta),
                          Text(fmt(p.cantidadAEnviar), style: _valor),
                          const Spacer(),
                          GestureDetector(
                            onTap: onVerImagenProducto,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              elevation: 2,
                              color: white,
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.image,
                                  color: primaryColorApp,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Paquete: ', style: _etiqueta),
                          Text(p.packageName, style: _valor),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Novedad: ', style: _etiqueta),
                          Expanded(
                            child: Text(
                              p.observation.isEmpty
                                  ? 'Sin novedad'
                                  : p.observation,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _valor,
                            ),
                          ),
                          if (p.imageNovedad.isNotEmpty)
                            GestureDetector(
                              onTap: () =>
                                  showImageDialog(context, p.imageNovedad),
                              child: Icon(
                                Icons.image,
                                color: primaryColorApp,
                                size: 23,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (p.tracking == 'lot')
                Row(
                  children: [
                    Text('Numero de serie/lote: ', style: _etiqueta),
                    Text(' ${p.loteName}', style: _valor),
                  ],
                ),
              Row(
                children: [
                  Text('Peso: ', style: _etiqueta),
                  Text(fmt(p.weight), style: _valor),
                  const Spacer(),
                  GestureDetector(
                    onTap: onImprimir,
                    child: Icon(Icons.print, color: primaryColorApp, size: 25),
                  ),
                  const SizedBox(width: 3),
                ],
              ),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Tiempo total: ', style: _valor),
                    TextSpan(
                      text: PackFormatos.duracion(p.timeSeparate),
                      style: _etiqueta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
