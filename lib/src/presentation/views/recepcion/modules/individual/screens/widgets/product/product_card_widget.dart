import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';

class ProductDropdownOrderWidget extends StatelessWidget {
  final String? selectedProduct;
  final List<LineasTransferencia> listOfProductsName;
  final String currentProductId;
  final LineasTransferencia currentProduct;

  final bool isPDA;

  const ProductDropdownOrderWidget({
    super.key,
    required this.selectedProduct,
    required this.listOfProductsName,
    required this.currentProductId,
    required this.currentProduct,
    required this.isPDA,
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
              items: listOfProductsName.map((LineasTransferencia product) {
                return DropdownMenuItem<String>(
                  value: product.productName.toString(),
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
                      product.productName.toString(),
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
              onChanged: context.read<RecepcionBloc>().configurations.result?.result
                          ?.manualProductReading ==
                      false
                  ? null
                  : !context.read<RecepcionBloc>().productIsOk
                      ? (String? newValue) {
                          if (newValue ==
                              currentProduct.productName.toString()) {
                            context.read<RecepcionBloc>().add(ValidateFieldsOrderEvent(
                                field: "product", isOk: true));

                            context.read<RecepcionBloc>().add(ChangeQuantitySeparate(
                              0,
                              int.parse(currentProduct.productId),
                              currentProduct.idRecepcion ?? 0,
                              currentProduct.idMove ?? 0,
                            ));

                            context.read<RecepcionBloc>().add(ChangeProductIsOkEvent(
                                currentProduct.idRecepcion ?? 0,
                                true,
                                int.parse(currentProduct.productId),
                                0,
                                currentProduct.idMove ?? 0));
                          } else {
                            _audioService.playErrorSound();
                            _vibrationService.vibrate();

                            context.read<RecepcionBloc>().add(ValidateFieldsOrderEvent(
                                field: "product", isOk: false));

                          
                          }
                        }
                      : null,
            ),

            // Información del producto

            if (isPDA)
              Align(
                alignment: Alignment.centerLeft,
                child: Visibility(
                  visible: currentProductId.isEmpty,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Sin código de barras",
                      textAlign: TextAlign.start,
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
