import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart';

class ProductDropdownReceptionBatchWidget extends StatelessWidget {
  final String? selectedProduct;
  final List<LineasRecepcionBatch> listOfProductsName;
  final String currentProductId;
  final LineasRecepcionBatch currentProduct;

  final bool isPDA;

  const ProductDropdownReceptionBatchWidget({
    super.key,
    required this.selectedProduct,
    required this.listOfProductsName,
    required this.currentProductId,
    required this.currentProduct,
    required this.isPDA,
  });

  @override
  Widget build(BuildContext context) {
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
              items: listOfProductsName.map((LineasRecepcionBatch product) {
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
              onChanged: context.read<RecepcionBatchBloc>().configurations.result?.result
                          ?.manualProductReading ==
                      false
                  ? null
                  : !context.read<RecepcionBatchBloc>().productIsOk
                      ? (String? newValue) {
                          if (newValue ==
                              currentProduct.productName.toString()) {
                            context.read<RecepcionBatchBloc>().add(ValidateFieldsOrderEvent(
                                field: "product", isOk: true));

                            context.read<RecepcionBatchBloc>().add(ChangeQuantitySeparate(
                              0,
                              int.parse(currentProduct.productId),
                              currentProduct.idRecepcion ?? 0,
                              currentProduct.idMove ?? 0,
                            ));

                            context.read<RecepcionBatchBloc>().add(ChangeProductIsOkEvent(
                                currentProduct.idRecepcion ?? 0,
                                true,
                                int.parse(currentProduct.productId),
                                0,
                                currentProduct.idMove ?? 0));

                           
                          } else {
                            context.read<RecepcionBatchBloc>().add(ValidateFieldsOrderEvent(
                                field: "product", isOk: false));

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(milliseconds: 1000),
                              content: const Text('Producto erroneo'),
                              backgroundColor: Colors.red[200],
                            ));
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
