import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';

class ProductDropdownConteoWidget extends StatelessWidget {
  final String? selectedProduct;
  final List<String> listOfProductsName;
  final String currentProductId;
  final ConteoBloc conteoBloc;
  final CountedLine currentProduct;

  const ProductDropdownConteoWidget({
    super.key,
    required this.selectedProduct,
    required this.listOfProductsName,
    required this.currentProductId,
    required this.conteoBloc,
    required this.currentProduct,
  });

  @override
  Widget build(BuildContext context) {
    final AudioService _audioService = AudioService();
    final VibrationService _vibrationService = VibrationService();
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 50,
      child: Center(
        child: DropdownButton<String>(
          underline: const SizedBox(),
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
          items: listOfProductsName.map((String product) {
            final isSelected = currentProductId == product;
            return DropdownMenuItem<String>(
              value: product,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected ? Colors.green[100] : Colors.white,
                ),
                width: screenWidth * 0.9,
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text(
                  product,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: black, fontSize: 14),
                ),
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return listOfProductsName.map((String product) {
              final isSelected = currentProductId == product;
              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[100] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 45,
                child: Text(
                  product,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: black, fontSize: 14),
                ),
              );
            }).toList();
          },
          onChanged: conteoBloc.configurations.result?.result
                      ?.manualProductSelectionInventory ==
                  false
              ? null
              : conteoBloc.locationIsOk && !conteoBloc.productIsOk
                  ? (String? newValue) {
                      if (newValue == currentProduct.productName.toString()) {
                        conteoBloc.add(
                            ValidateFieldsEvent(field: "product", isOk: true));
                        conteoBloc.add(ChangeProductIsOkEvent(
                          false,
                          Product(),
                          currentProduct.orderId ?? 0,
                          true,
                          currentProduct.productId ?? 0,
                          0,
                          currentProduct.idMove ?? 0,
                        ));
                      } else {
                        _vibrationService.vibrate();
                        _audioService.playErrorSound();
                        conteoBloc.add(
                            ValidateFieldsEvent(field: "product", isOk: false));
                      }
                    }
                  : null,
        ),
      ),
    );
  }
}
