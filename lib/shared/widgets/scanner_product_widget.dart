import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';

class ProductScannerWidget extends StatefulWidget {
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
  final List<dynamic> listOfBarcodes;
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
  State<ProductScannerWidget> createState() => _ProductScannerWidgetState();
}

class _ProductScannerWidgetState extends State<ProductScannerWidget> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onZebraChanged(String value, BuildContext context) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (value.trim().isNotEmpty) {
        widget.onValidateProduct(value);
      }
    });
  }

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
              color: widget.productIsOk ? green : yellow,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: widget.isProductOk
              ? widget.productIsOk
                  ? Colors.green[100]
                  : Colors.grey[300]
              : Colors.red[200],
          elevation: 5,
          child: Container(
            width: widget.size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.productDropdown,
                TextFormField(
                  showCursor: false,
                  enabled: widget.locationIsOk &&
                      !widget.productIsOk &&
                      !widget.quantityIsOk &&
                      !widget.locationDestIsOk,
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: TextInputType.none,
                  enableInteractiveSelection: false,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.transparent),
                  onChanged: (value) {
                    // Usa el debounce para evitar múltiples disparos por carácter
                    _onZebraChanged(value, context);
                  },
                  onFieldSubmitted: (value) {
                    // Disparo inmediato en Enter: cancela el debounce pendiente
                    _debounce?.cancel();
                    if (value.trim().isNotEmpty) {
                      widget.onValidateProduct(value);
                    }
                    // Limpiar el controller después del submit
                    widget.controller.clear();
                  },
                  decoration: InputDecoration(
                    suffixIcon: GestureDetector(
                      onTap: () {
                        if (widget.onViewImgProduct != null) {
                          widget.onViewImgProduct!();
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
                    hintText: widget.currentProductId,
                    hintMaxLines: 2,
                    hintStyle: const TextStyle(fontSize: 12, color: black),
                    disabledBorder: InputBorder.none,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
                      (widget.barcode == null ||
                              widget.barcode!.isEmpty ||
                              widget.barcode == "false")
                          ? "Sin codigo de barras"
                          : widget.barcode!,
                      style: TextStyle(
                          fontSize: 12,
                          color: (widget.barcode == null ||
                                  widget.barcode!.isEmpty ||
                                  widget.barcode == "false")
                              ? red
                              : black),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (widget.lotId != "") ...[
                      Text('Lote/serie:',
                          style:
                              TextStyle(fontSize: 13, color: primaryColorApp)),
                      const SizedBox(width: 5),
                      Text(
                          widget.lotId == "" || widget.lotId == null
                              ? "Sin lote"
                              : widget.lotId ?? "",
                          style: TextStyle(
                              fontSize: 13,
                              color: widget.lotId == "" || widget.lotId == null
                                  ? red
                                  : black)),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onBarcodesDialogTap,
                      child: Visibility(
                        visible: widget.listOfBarcodes.isNotEmpty,
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
                if (widget.origin != null && widget.origin!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.file_open_sharp,
                          color: primaryColorApp, size: 15),
                      const SizedBox(width: 5),
                      const Text("Doc. origen: ",
                          style: TextStyle(fontSize: 12, color: grey)),
                      Text(widget.origin!,
                          style:
                              TextStyle(fontSize: 12, color: primaryColorApp)),
                    ],
                  ),
                widget.expiryWidget,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
