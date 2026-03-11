import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';

class ProductDropdownWidget extends StatelessWidget {
  final String? selectedProduct;
  final List<String> listOfProductsName;
  final String currentProductId;
  final BatchProduct currentProduct;
  final ClusterPickingBloc bloc;

  const ProductDropdownWidget({
    super.key,
    required this.selectedProduct,
    required this.listOfProductsName,
    required this.currentProductId,
    required this.currentProduct,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final IAudioService audioService = getIt<IAudioService>();
    final IVibrationService _vibrationService = getIt<IVibrationService>();

    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 25,
          padding: const EdgeInsets.symmetric(vertical: 2),
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
              return DropdownMenuItem<String>(
                value: product,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: currentProduct.productId.toString() == product
                        ? Colors.green[100]
                        : Colors.white,
                  ),
                  width: screenWidth * 0.9,
                  height: 45,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
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
                final isSelected = selectedProduct == product;
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
            onChanged: bloc.configurations.result?.result
                        ?.manualProductSelection ==
                    false
                ? null
                : (bloc.locationIsOk && !bloc.productIsOk)
                    ? (String? newValue) async {
                        if (newValue == currentProduct.productId.toString()) {
                          bloc.add(ValidateFieldsEvent(
                              field: "product", isOk: true));

                          bloc.add(ChangeProductIsOkEvent(
                            true,
                            currentProduct.idProduct ?? 0,
                            bloc.currentBatch?.id ?? 0,
                            1,
                            currentProduct.idMove ?? 0,
                            "cluster",
                          ));
                        } else {
                          _vibrationService.vibrate();
                          audioService.playErrorSound();
                          bloc.add(ValidateFieldsEvent(
                              field: "product", isOk: false));
                        }
                      }
                    : null,
          ),
        ),
      ],
    );
  }
}
