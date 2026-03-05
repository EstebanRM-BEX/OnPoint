import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';

class ProductPickDropdownWidget extends StatelessWidget {
  final String? selectedProduct;
  final List<String> listOfProductsName;
  final String currentProductId;
  final ProductsBatch currentProduct;

  final bool isPDA;

  const ProductPickDropdownWidget({
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
              items: listOfProductsName.map((String product) {
                return DropdownMenuItem<String>(
                  value: product,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: currentProductId == product
                          ? Colors.green[100]
                          : Colors.white,
                    ),
                    width: MediaQuery.of(context).size.width * 0.9,
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
              onChanged: context.read<PickingPickBloc>().configurations.result?.result
                          ?.manualProductSelection ==
                      false
                  ? null
                  : context.read<PickingPickBloc>().locationIsOk && !context.read<PickingPickBloc>().productIsOk
                      ? (String? newValue) {
                          if (newValue == currentProduct.productId.toString()) {
                            context.read<PickingPickBloc>().add(ValidateFieldsEvent(
                                field: "product", isOk: true));

                            context.read<PickingPickBloc>().add(ChangeProductIsOkEvent(
                                true,
                                currentProduct.idProduct ?? 0,
                                context.read<PickingPickBloc>().pickWithProducts.pick?.id ?? 0,
                                0,
                                currentProduct.idMove ?? 0));
                          } else {
                            _vibrationService.vibrate();
                            _audioService.playErrorSound();
                            context.read<PickingPickBloc>().add(ValidateFieldsEvent(
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

            // Lote/Numero de serie
            if (isPDA)
              if (currentProductId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lote/Numero de serie',
                          style:
                              TextStyle(fontSize: 14, color: primaryColorApp),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currentProduct.lotId ?? '',
                          style: const TextStyle(fontSize: 14, color: black),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
