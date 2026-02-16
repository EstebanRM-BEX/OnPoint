import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class ProductScannerWidget extends StatelessWidget {
  final bool isProductOk;
  final bool productIsOk;
  final bool locationIsOk;
  final bool quantityIsOk;
  final bool locationDestIsOk;
  final String currentProductId;
  final String? barcode;
  final String? lotId;
  final String? origin;
  final String? expireDate;
  final Size size;
  final Function(String) onValidateProduct;
  final VoidCallback? onViewImgProduct;
  final Function(String keyLabel)? onKeyScanned;
  final FocusNode focusNode;
  final TextEditingController controller;
  final Widget productDropdown;
  final Widget expiryWidget;
  final List<Barcodes> listOfBarcodes;
  final VoidCallback onBarcodesDialogTap;
  final String category;
  final bool isViewLote;

  const ProductScannerWidget({
    super.key,
    required this.isProductOk,
    required this.productIsOk,
    required this.locationIsOk,
    required this.quantityIsOk,
    required this.locationDestIsOk,
    required this.currentProductId,
    required this.barcode,
    required this.lotId,
    required this.origin,
    required this.expireDate,
    required this.size,
    required this.onValidateProduct,
    this.onViewImgProduct,
    this.onKeyScanned,
    required this.focusNode,
    required this.controller,
    required this.productDropdown,
    required this.expiryWidget,
    required this.listOfBarcodes,
    required this.onBarcodesDialogTap,
    this.category = "",
    this.isViewLote = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: productIsOk ? green : yellow,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: isProductOk
              ? productIsOk
                  ? Colors.green[100]
                  : Colors.grey[300]
              : Colors.red[200],
          elevation: 5,
          child: Container(
            width: size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: !context.read<UserBloc>().fabricante.contains("Zebra")
                ? Focus(
                    focusNode: focusNode,
                    onKey: (node, event) {
                      if (event is RawKeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.enter) {
                          onValidateProduct(controller.text);
                          return KeyEventResult.handled;
                        } else {
                          if (onKeyScanned != null) {
                            onKeyScanned!(event.data.keyLabel);
                          }
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        productDropdown,
                        Row(
                          children: [
                            Flexible(
                              child: Text(currentProductId,
                                  style: TextStyle(fontSize: 12, color: black)),
                            ),
                            const SizedBox(width: 2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  if (onViewImgProduct != null) {
                                    onViewImgProduct!();
                                  }
                                },
                                child: Card(
                                  elevation: 2,
                                  color: white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.image,
                                      color: primaryColorApp,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
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
                            const SizedBox(width: 10),
                            Text(
                              (barcode == null ||
                                      barcode!.isEmpty ||
                                      barcode == "false")
                                  ? "Sin codigo de barras"
                                  : barcode!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: (barcode == null ||
                                          barcode!.isEmpty ||
                                          barcode == "false")
                                      ? Colors.red
                                      : black),
                            ),
                          ],
                        ),
                        if (category != "")
                          Row(
                            children: [
                              Text('Categoria:',
                                  style: TextStyle(
                                      fontSize: 13, color: primaryColorApp)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(category,
                                    style: const TextStyle(
                                        fontSize: 13, color: black)),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            if (lotId != "") ...[
                              Text('Lote/serie:',
                                  style: TextStyle(
                                      fontSize: 13, color: primaryColorApp)),
                              const SizedBox(width: 5),
                              Text(
                                  lotId == "" || lotId == null
                                      ? "Sin lote"
                                      : lotId ?? "",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: lotId == "" || lotId == null
                                          ? red
                                          : black)),
                            ],
                            const Spacer(),
                            GestureDetector(
                              onTap: onBarcodesDialogTap,
                              child: Visibility(
                                visible: listOfBarcodes.isNotEmpty,
                                child: SizedBox(
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
                              ),
                            ),
                          ],
                        ),
                       if (origin != null && origin!.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.file_open_sharp,
                                  color: primaryColorApp, size: 15),
                              const SizedBox(width: 5),
                              const Text("Doc. origen: ",
                                  style: TextStyle(fontSize: 12, color: grey)),
                              Text(origin!,
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColorApp)),
                            ],
                          ),
                        expiryWidget,
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      productDropdown,
                      TextFormField(
                        showCursor: false,
                        enabled: locationIsOk &&
                            !productIsOk &&
                            !quantityIsOk &&
                            !locationDestIsOk,
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (value) {
                          onValidateProduct(value);
                        },
                        decoration: InputDecoration(
                          suffixIcon: GestureDetector(
                            onTap: () {
                              if (onViewImgProduct != null) {
                                onViewImgProduct!();
                              }
                            },
                            child: Card(
                              elevation: 2,
                              color: white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.image,
                                  color: primaryColorApp,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          hintText: currentProductId,
                          hintMaxLines: 2,
                          disabledBorder: InputBorder.none,
                          hintStyle:
                              const TextStyle(fontSize: 12, color: black),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
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
                          const SizedBox(width: 10),
                          Text(
                            (barcode == null ||
                                    barcode!.isEmpty ||
                                    barcode == "false")
                                ? "Sin codigo de barras"
                                : barcode!,
                            style: TextStyle(
                                fontSize: 12,
                                color: (barcode == null ||
                                        barcode!.isEmpty ||
                                        barcode == "false")
                                    ? red
                                    : black),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (lotId != "") ...[
                            Text('Lote/serie:',
                                style: TextStyle(
                                    fontSize: 13, color: primaryColorApp)),
                            const SizedBox(width: 5),
                            Text(
                                lotId == "" || lotId == null
                                    ? "Sin lote"
                                    : lotId ?? "",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: lotId == "" || lotId == null
                                        ? red
                                        : black)),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: onBarcodesDialogTap,
                            child: Visibility(
                              visible: listOfBarcodes.isNotEmpty,
                              child: SizedBox(
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
                            ),
                          ),
                        ],
                      ),
                      if (origin != null && origin!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.file_open_sharp,
                                color: primaryColorApp, size: 15),
                            const SizedBox(width: 5),
                            const Text("Doc. origen: ",
                                style: TextStyle(fontSize: 12, color: grey)),
                            Text(origin!,
                                style: TextStyle(
                                    fontSize: 12, color: primaryColorApp)),
                          ],
                        ),
                      expiryWidget,
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
