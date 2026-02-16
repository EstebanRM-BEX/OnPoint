import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class LoteScannerWidget extends StatelessWidget {
  final bool isLoteOk;
  final bool loteIsOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final bool viewQuantity;
  final dynamic currentProduct;
  final dynamic currentProductLote;
  final Function(String) onValidateLote;
  final Function(String keyLabel) onKeyScanned;
  final FocusNode focusNode;
  final TextEditingController controller;
  final String routeName;

  const LoteScannerWidget({
    Key? key,
    required this.isLoteOk,
    required this.loteIsOk,
    required this.locationIsOk,
    required this.productIsOk,
    required this.quantityIsOk,
    required this.viewQuantity,
    required this.currentProduct,
    required this.currentProductLote,
    required this.onValidateLote,
    required this.onKeyScanned,
    required this.focusNode,
    required this.controller,
    required this.routeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusColor = loteIsOk ? green : yellow;
    final cardColor = isLoteOk
        ? loteIsOk
            ? Colors.green[100]
            : Colors.grey[300]
        : Colors.red[200];
    final expirationDate = currentProductLote?.expirationDate?.toString() ?? "";

    // La visibilidad del widget debe ser gestionada por el padre, por lo que la eliminamos de aquí
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: cardColor,
          elevation: 5,
          child: Container(
            width: size.width * 0.85,
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    context.read<UserBloc>().fabricante.contains("Zebra")
                        ? _buildZebraInput()
                        : _buildNonZebraInput(),
                    _buildExpirationDate(expirationDate),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'Lote del producto',
          style: TextStyle(fontSize: 14, color: primaryColorApp),
        ),
        const Spacer(),
        SizedBox(
          height: 20,
          width: 20,
          child: SvgPicture.asset(
            color: primaryColorApp,
            "assets/icons/barcode.svg",
            height: 20,
            width: 20,
            fit: BoxFit.cover,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              routeName,
              arguments: [currentProduct],
            );
          },
          icon: Icon(
            Icons.arrow_forward_ios,
            color: primaryColorApp,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildZebraInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Container(
        height: 20,
        margin: const EdgeInsets.only(bottom: 5, top: 5),
        child: TextFormField(
          autofocus: true,
          showCursor: false,
          controller: controller,
          enabled: locationIsOk &&
              productIsOk &&
              !loteIsOk &&
              !quantityIsOk &&
              !viewQuantity,
          focusNode: focusNode,
          onChanged: onValidateLote,
          decoration: InputDecoration(
            hintText: currentProductLote?.name ?? 'Esperando escaneo',
            disabledBorder: InputBorder.none,
            hintStyle: const TextStyle(fontSize: 12, color: black),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildNonZebraInput() {
    return Focus(
      focusNode: focusNode,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            onValidateLote(controller.text);
            return KeyEventResult.handled;
          } else {
            onKeyScanned(event.data.keyLabel);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                'Lote: ',
                style: TextStyle(fontSize: 14, color: black),
              ),
              Text(
                currentProductLote?.name ?? "Esperando escaneo",
                style: TextStyle(fontSize: 14, color: black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpirationDate(String expirationDate) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            'Fecha caducidad: ',
            style: TextStyle(fontSize: 14, color: black),
          ),
          Text(
            expirationDate.isEmpty ? "Sin fecha" : expirationDate,
            style: TextStyle(
              fontSize: 14,
              color: expirationDate.isEmpty ? red : black,
            ),
          ),
        ],
      ),
    );
  }
}
