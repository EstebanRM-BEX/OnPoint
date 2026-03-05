import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';

class ProductDropdownWidget extends StatelessWidget {
  final String? selectedProduct;
  final List<String> listOfProductsName;
  final String currentProductId;
  final BatchBloc batchBloc;
  final ProductsBatch currentProduct;

  const ProductDropdownWidget({
    super.key,
    required this.selectedProduct,
    required this.listOfProductsName,
    required this.currentProductId,
    required this.batchBloc,
    required this.currentProduct,
  });

  @override
  Widget build(BuildContext context) {
    final IAudioService audioService = getIt<IAudioService>();
    final IVibrationService _vibrationService = getIt<IVibrationService>();

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
          onChanged: batchBloc
                      .configurations.result?.result?.manualProductSelection ==
                  false
              ? null
              : batchBloc.locationIsOk && !batchBloc.productIsOk
                  ? (String? newValue) async {
                      if (newValue == currentProduct.productId.toString()) {
                        batchBloc.add(
                            ValidateFieldsEvent(field: "product", isOk: true));
                        batchBloc.add(ChangeProductIsOkEvent(
                          true,
                          currentProduct.idProduct ?? 0,
                          batchBloc.batchWithProducts.batch?.id ?? 0,
                          0,
                          currentProduct.idMove ?? 0,
                          batchBloc.typePicking,
                        ));
                      } else {
                        _vibrationService.vibrate();
                        audioService.playErrorSound();
                        batchBloc.add(
                            ValidateFieldsEvent(field: "product", isOk: false));
                      }
                    }
                  : null,
        ),
      ),
    );
  }
}
