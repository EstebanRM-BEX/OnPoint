import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';

class LocationDropdownConteoWidget extends StatefulWidget {
  final String? selectedLocation;
  final List<String> positionsOrigen;
  final String currentLocationId;
  final ConteoBloc conteoBloc;
  final CountedLine currentProduct;
  final bool isPDA;

  const LocationDropdownConteoWidget({
    super.key,
    required this.selectedLocation,
    required this.positionsOrigen,
    required this.currentLocationId,
    required this.conteoBloc,
    required this.currentProduct,
    required this.isPDA,
  });

  @override
  State<LocationDropdownConteoWidget> createState() =>
      _LocationDropdownWidgetState();
}

class _LocationDropdownWidgetState extends State<LocationDropdownConteoWidget> {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();
  @override
  Widget build(BuildContext context) {
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
          onChanged: widget.conteoBloc
                      .configurations.result?.result?.locationManualInventory ==
                  false
              ? null
              : widget.conteoBloc.locationIsOk
                  ? null
                  : (String? newValue) {
                      final expected =
                          widget.currentProduct.locationName.toString();
                      if (newValue == expected) {
                        widget.conteoBloc.add(
                            ValidateFieldsEvent(field: "location", isOk: true));
                        widget.conteoBloc.add(ChangeLocationIsOkEvent(
                          false,
                          ResultUbicaciones(),
                          widget.currentProduct.productId ?? 0,
                          widget.currentProduct.orderId ?? 0,
                          widget.currentProduct.idMove ?? 0,
                        ));
                        widget.conteoBloc.oldLocation = expected;
                      } else {
                        widget.conteoBloc.add(ValidateFieldsEvent(
                            field: "location", isOk: false));

                        _vibrationService.vibrate();
                        _audioService.playErrorSound();
                        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        //   duration: const Duration(milliseconds: 1000),
                        //   content: const Text('Ubicación errónea'),
                        //   backgroundColor: Colors.red[200],
                        // ));
                      }
                    },
        ),
        if (widget.currentProduct.locationBarcode == null ||
            widget.currentProduct.locationBarcode!.isEmpty)
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
