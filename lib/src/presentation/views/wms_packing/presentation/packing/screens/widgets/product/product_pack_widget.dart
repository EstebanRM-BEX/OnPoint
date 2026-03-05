import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';

class ProductDropdownPackWidget extends StatelessWidget {
  final String? selectedProduct;
  final List<ProductoPedido> listOfProductsName;
  final String currentProductId;
  final PackingPedidoBloc batchBloc;
  final ProductoPedido currentProduct;

  const ProductDropdownPackWidget({
    super.key,
    required this.selectedProduct,
    required this.listOfProductsName,
    required this.currentProductId,
    required this.batchBloc,
    required this.currentProduct,
  });

  @override
  Widget build(BuildContext context) {
    final IAudioService _audioService = getIt<IAudioService>();
    final IVibrationService _vibrationService = getIt<IVibrationService>();

    return SizedBox(
      height: 48,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // DropdownButton for Product selection
            DropdownButton<String>(
              underline: Container(height: 0),
              borderRadius: BorderRadius.circular(10),
              focusColor: Colors.white,
              isExpanded: true,
              hint: Text(
                'Producto',
                style: TextStyle(fontSize: 14, color: primaryColorApp),
              ),
              icon: Image.asset(
                "assets/icons/producto.png",
                color: primaryColorApp,
                width: 20,
              ),
              value: selectedProduct,
              items: listOfProductsName.map((ProductoPedido product) {
                return DropdownMenuItem<String>(
                  value: product.productId.toString(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: currentProduct.idMove == product.idMove
                          ? Colors.green[100]
                          : Colors.white,
                    ),
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Text(
                      product.productId.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: black,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: batchBloc.configurations.result?.result
                          ?.manualProductSelectionPack ==
                      false
                  ? null
                  : batchBloc.locationIsOk && !batchBloc.productIsOk
                      ? (String? newValue) {
                          if (newValue == currentProduct.productId.toString()) {
                            batchBloc.add(ValidateFieldsPackingEvent(
                                field: "product", isOk: true));

                            batchBloc.add(ChangeQuantitySeparate(
                                0,
                                currentProduct.idProduct ?? 0,
                                currentProduct.pedidoId ?? 0,
                                currentProduct.idMove ?? 0));

                            batchBloc.add(ChangeProductIsOkEvent(
                                true,
                                currentProduct.idProduct ?? 0,
                                currentProduct.pedidoId ?? 0,
                                0,
                                currentProduct.idMove ?? 0));

                            batchBloc.add(ChangeIsOkQuantity(
                                true,
                                currentProduct.idProduct ?? 0,
                                currentProduct.pedidoId ?? 0,
                                currentProduct.idMove ?? 0));
                          } else {
                            _audioService.playErrorSound();
                            _vibrationService.vibrate();

                            batchBloc.add(ValidateFieldsPackingEvent(
                                field: "product", isOk: false));

                            // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            //   duration: const Duration(milliseconds: 1000),
                            //   content: const Text('Producto erroneo'),
                            //   backgroundColor: Colors.red[200],
                            // ));
                          }
                        }
                      : null,
            ),

            // Información del producto
          ],
        ),
      ),
    );
  }
}
