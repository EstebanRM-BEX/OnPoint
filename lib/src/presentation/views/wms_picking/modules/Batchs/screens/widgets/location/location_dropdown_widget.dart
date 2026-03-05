import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';

class LocationDropdownWidget extends StatefulWidget {
  final String? selectedLocation;
  final List<String> positionsOrigen;
  final String currentLocationId;
  final BatchBloc batchBloc;
  final ProductsBatch currentProduct;
  final bool isPDA;

  const LocationDropdownWidget({
    super.key,
    required this.selectedLocation,
    required this.positionsOrigen,
    required this.currentLocationId,
    required this.batchBloc,
    required this.currentProduct,
    required this.isPDA,
  });

  @override
  State<LocationDropdownWidget> createState() => _LocationDropdownWidgetState();
}

class _LocationDropdownWidgetState extends State<LocationDropdownWidget> {
  @override
  Widget build(BuildContext context) {
    final IAudioService _audioService = getIt<IAudioService>();
    final IVibrationService _vibrationService = getIt<IVibrationService>();

    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(10),
          focusColor: Colors.white,
          isExpanded: true,
          hint: Text(
            'Ubicación de origen',
            style: TextStyle(fontSize: 14, color: primaryColorApp),
          ),
          icon: Image.asset(
            "assets/icons/ubicacion.png",
            color: primaryColorApp,
            width: 20,
          ),
          value: widget.selectedLocation,
          items: widget.positionsOrigen.map((location) {
            final isSelected = location == widget.currentLocationId;
            return DropdownMenuItem<String>(
              value: location,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected ? Colors.green[100] : Colors.white,
                ),
                width: screenWidth * 0.9,
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: black, fontSize: 14),
                  ),
                ),
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return widget.positionsOrigen.map((location) {
              final isSelected = location == widget.currentLocationId;
              return Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[100] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 45,
                child: Text(
                  location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: black, fontSize: 14),
                ),
              );
            }).toList();
          },
          onChanged: widget.batchBloc
                      .configurations.result?.result?.locationPickingManual ==
                  false
              ? null
              :  widget.batchBloc.locationIsOk
                  ? null
                  : (String? newValue) async {
                      final expected =
                          widget.currentProduct.locationId.toString();
                      if (newValue == expected) {
                         widget.batchBloc.add(
                            ValidateFieldsEvent(field: "location", isOk: true));
                         widget.batchBloc.add(ChangeLocationIsOkEvent(
                          widget.currentProduct.idProduct ?? 0,
                          widget.batchBloc.batchWithProducts.batch?.id ?? 0,
                          widget.currentProduct.idMove ?? 0,
                          widget.batchBloc.typePicking
                        ));
                        widget.batchBloc.oldLocation = expected;
                      } else {
                         _vibrationService.vibrate();
                         _audioService.playErrorSound();
                        widget.batchBloc.add(ValidateFieldsEvent(
                            field: "location", isOk: false));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: const Text('Ubicación errónea'),
                          backgroundColor: Colors.red[200],
                        ));
                      }
                    },
        ),
        if (widget.currentProduct.barcodeLocation == null ||
            widget.currentProduct.barcodeLocation!.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              "Sin código de barras",
              style: TextStyle(fontSize: 14, color: red),
            ),
          ),
        if (widget.isPDA)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.currentLocationId,
              style: const TextStyle(fontSize: 14, color: black),
            ),
          ),
      ],
    );
  }
}
