import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class ProductScannerAll extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final bool isProductOk;
  final dynamic currentProduct;
  final Function(String) onValidateProduct;
  final Function(String) onKeyScanned;
  final Widget? productDropdown;
  final bool? isCreateTransfer;

  const ProductScannerAll({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.locationIsOk,
    required this.productIsOk,
    required this.quantityIsOk,
    required this.isProductOk,
    this.currentProduct,
    required this.onValidateProduct,
    required this.onKeyScanned,
    required this.productDropdown,
    this.isCreateTransfer = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusColor = productIsOk ? green : yellow;
    final cardColor = isProductOk
        ? productIsOk
            ? Colors.green[100]
            : Colors.grey[300]
        : Colors.red[200];

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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: context.read<UserBloc>().fabricante.contains("Zebra")
                ? _buildZebraLayout(context)
                : _buildNonZebraLayout(context),
          ),
        ),
      ],
    );
  }

  Widget _buildZebraLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Column(
        children: [
          if (productDropdown != null) productDropdown!,
          Container(
            height: 20,
            margin: const EdgeInsets.only(bottom: 5, top: 5),
            child: TextFormField(
              autofocus: true,
              showCursor: false,
              controller: controller,
              enabled: locationIsOk && !productIsOk && !quantityIsOk,
              focusNode: focusNode,
              onChanged: onValidateProduct,
              decoration: InputDecoration(
                hintText: 
                // isCreateTransfer == true
                //     ? currentProduct?.name == "" || currentProduct?.name == null
                //         ? 'Esperando escaneo'
                //         : currentProduct?.name
                //     : 
                    currentProduct?.productName == "" ||
                            currentProduct?.productName == null
                        ? 'Esperando escaneo'
                        : currentProduct?.productName,
                disabledBorder: InputBorder.none,
                hintStyle: const TextStyle(fontSize: 12, color: black),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonZebraLayout(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            onValidateProduct(controller.text);
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
        child: productDropdown ?? const SizedBox(),
      ),
    );
  }
}
