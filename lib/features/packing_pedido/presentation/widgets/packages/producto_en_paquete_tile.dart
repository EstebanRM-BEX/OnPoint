import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';

/// Producto dentro de una caja, con el diseño del módulo anterior: nombre
/// con desempacar, cantidad (o "No certificado"), UND, novedad y
/// temperatura.
class ProductoEnPaqueteTile extends StatelessWidget {
  final ProductoPacking producto;

  /// null = pedido terminado (sin desempacar).
  final VoidCallback? onDesempacar;

  const ProductoEnPaqueteTile({
    super.key,
    required this.producto,
    this.onDesempacar,
  });

  static const _negro = TextStyle(fontSize: 12, color: black);
  TextStyle get _marca => TextStyle(fontSize: 12, color: primaryColorApp);

  Widget _par(String etiqueta, String valor, {TextStyle? estiloValor}) =>
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: etiqueta, style: _negro),
            TextSpan(text: valor, style: estiloValor ?? _marca),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final fmt = PackFormatos.cantidad;
    return Card(
      color: white,
      elevation: 2,
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(p.productName, style: _negro)),
            if (onDesempacar != null)
              GestureDetector(
                onTap: onDesempacar,
                child: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (p.certificado)
                  _par('Cant. empacada: ', fmt(p.quantitySeparate))
                else
                  _par(
                    'Cantidad: ',
                    'No certificado',
                    estiloValor: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(width: 5),
                p.certificado
                    ? const Icon(Icons.check, color: green, size: 15)
                    : const Icon(Icons.warning, color: Colors.amber, size: 15),
                const Spacer(),
                _par('UND: ', p.unidades),
              ],
            ),
            if (!p.certificado)
              _par('Cantidad empacada: ', fmt(p.quantity))
            else
              _par(
                'Novedad: ',
                p.observation.isEmpty ? 'Sin novedad' : p.observation,
              ),
            if (p.manejaTemperatura)
              Row(
                children: [
                  _par(
                    'Temperatura: ',
                    p.temperatura == 0 ? 'Sin temperatura' : fmt(p.temperatura),
                  ),
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
          ],
        ),
      ),
    );
  }
}
