import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class ProductScannerAll extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final bool isProductOk;
  final dynamic currentProduct;
  final Function(String) onValidateProduct;
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
    required this.productDropdown,
    this.isCreateTransfer = false,
  });

  @override
  State<ProductScannerAll> createState() => _ProductScannerAllState();
}

class _ProductScannerAllState extends State<ProductScannerAll> {
  Timer? _debounce;
  late String _cachedLocationId;

  @override
  void initState() {
    super.initState();
    // Cachear el ID del producto para evitar parpadeo durante el escaneo
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onZebraChanged(String value, BuildContext context) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusColor = widget.productIsOk ? green : yellow;
    final cardColor = widget.isProductOk
        ? widget.productIsOk
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
              child: _buildZebraLayout(context)),
        ),
      ],
    );
  }

  Widget _buildZebraLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Column(
        children: [
          if (widget.productDropdown != null) widget.productDropdown!,
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 5, top: 5),
            child: TextFormField(
              autofocus: true,
              showCursor: false,
              controller: widget.controller,
              enabled: widget.locationIsOk &&
                  !widget.productIsOk &&
                  !widget.quantityIsOk,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.none,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.transparent),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
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
                disabledBorder: InputBorder.none,
                hintStyle: const TextStyle(fontSize: 1, color: black),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
