import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';

/// Tarjeta de "Preparado" con el diseño del módulo anterior: nombre con
/// eliminar, recuadro con unidades, cantidad a empacar, temperatura y
/// novedad (con sus fotos), y lote, peso y tiempo total.
class ProductoPreparadoCard extends StatelessWidget {
  final ProductoPacking producto;

  /// null = pedido terminado (sin eliminar).
  final VoidCallback? onEliminar;

  const ProductoPreparadoCard({
    super.key,
    required this.producto,
    this.onEliminar,
  });

  static const _valor = TextStyle(fontSize: 12, color: black);
  TextStyle get _etiqueta => TextStyle(fontSize: 12, color: primaryColorApp);

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final fmt = PackFormatos.cantidad;
    final completo = p.quantitySeparate >= p.quantity;
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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      p.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _valor,
                    ),
                  ),
                  if (onEliminar != null)
                    GestureDetector(
                      onTap: onEliminar,
                      child: const Icon(Icons.delete, color: red, size: 20),
                    ),
                ],
              ),
              Card(
                elevation: 3,
                color: completo ? white : Colors.amber[100],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Unidades: ', style: _etiqueta),
                          Text(p.unidades, style: _valor),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Cantidad a empacar: ', style: _etiqueta),
                          Text(fmt(p.quantitySeparate), style: _valor),
                        ],
                      ),
                      if (p.manejaTemperatura)
                        _FilaConImagen(
                          etiqueta: 'Temperatura: ',
                          valor: fmt(p.temperatura),
                          imagen: p.image,
                          estilo: _etiqueta,
                        ),
                      _FilaConImagen(
                        etiqueta: 'Novedad: ',
                        valor: p.observation.isEmpty
                            ? 'Sin novedad'
                            : p.observation,
                        imagen: p.imageNovedad,
                        estilo: _etiqueta,
                      ),
                    ],
                  ),
                ),
              ),
              if (p.tracking == 'lot')
                Row(
                  children: [
                    Text('Numero de serie/lote: ', style: _etiqueta),
                    Expanded(
                      child: Text(
                        '${p.tracking} / ${p.loteName}',
                        style: _valor,
                      ),
                    ),
                  ],
                ),
              Row(
                children: [
                  Text('Peso: ', style: _etiqueta),
                  Text(fmt(p.weight), style: _valor),
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

/// Fila "Etiqueta: valor" con ícono para ver la foto si existe.
class _FilaConImagen extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String imagen;
  final TextStyle estilo;

  const _FilaConImagen({
    required this.etiqueta,
    required this.valor,
    required this.imagen,
    required this.estilo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(etiqueta, style: estilo),
        Expanded(
          child: Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: black),
          ),
        ),
        if (imagen.isNotEmpty)
          GestureDetector(
            onTap: () => showImageDialog(context, imagen),
            child: Icon(Icons.image, color: primaryColorApp, size: 23),
          ),
      ],
    );
  }
}
