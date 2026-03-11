import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';

import '../../../bloc/cluster_picking/cluster_picking_bloc.dart';

class PedidoDropdownWidget extends StatefulWidget {
  final String? selectedLocation;
  final List<String> positionsOrigen;
  final String currentLocationId;
  final BatchProduct currentProduct;
  final bool isPDA;

  const PedidoDropdownWidget({
    super.key,
    required this.selectedLocation,
    required this.positionsOrigen,
    required this.currentLocationId,
    required this.currentProduct,
    required this.isPDA,
  });

  @override
  State<PedidoDropdownWidget> createState() => _PedidoDropdownWidgetState();
}

class _PedidoDropdownWidgetState extends State<PedidoDropdownWidget> {
  @override
  Widget build(BuildContext context) {
    final IAudioService _audioService = getIt<IAudioService>();
    final IVibrationService _vibrationService = getIt<IVibrationService>();
    final ClusterPickingBloc bloc = context.read<ClusterPickingBloc>();

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
            itemHeight: 55,
            //tamaño del dropdown

            hint: Text(
              'Pedido',
              style: TextStyle(fontSize: 14, color: primaryColorApp),
            ),
            icon: Image.asset(
              "assets/icons/producto.png",
              color: primaryColorApp,
              width: 20,
            ),
            value: (widget.selectedLocation != null &&
                    widget.positionsOrigen.contains(widget.selectedLocation))
                ? widget.selectedLocation
                : null,
            items: widget.positionsOrigen.toSet().toList().map((location) {
              final isSelected = location == widget.currentLocationId;
              return DropdownMenuItem<String>(
                value: location,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected ? Colors.green[100] : Colors.white,
                  ),
                  width: screenWidth * 0.9,
                  height: 55,
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
              return widget.positionsOrigen.toSet().toList().map((location) {
                final isSelected = location == widget.currentLocationId;
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[100] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 55,
                  child: Text(
                    location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: black, fontSize: 14),
                  ),
                );
              }).toList();
            },
            onChanged: (!bloc.locationIsOk ||
                    !bloc.productIsOk ||
                    bloc.pedidoValidateIsOk)
                ? null
                : (String? newValue) async {
                    final expected = widget.currentProduct.origin.toString();
                    if (newValue == expected) {
                      bloc.add(
                          ValidateFieldsEvent(field: "pedido", isOk: true));
                      bloc.add(ValidatePedidoEvent(
                          widget.currentProduct.idProduct ?? 0,
                          bloc.currentBatch?.id ?? 0,
                          widget.currentProduct.idMove ?? 0,
                          'cluster'));
                      bloc.oldPedido = expected;
                    } else {
                      _vibrationService.vibrate();
                      _audioService.playErrorSound();
                      bloc.add(
                          ValidateFieldsEvent(field: "pedido", isOk: false));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: const Duration(milliseconds: 1000),
                        content: const Text('Pedido erróneo'),
                        backgroundColor: Colors.red[200],
                      ));
                    }
                  },
          ),
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
