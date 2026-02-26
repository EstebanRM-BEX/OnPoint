import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';

class LoteScannerWidget extends StatefulWidget {
  final bool isLoteOk;
  final bool loteIsOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final bool viewQuantity;
  final dynamic currentProduct;
  final dynamic currentProductLote;
  final Function(String) onValidateLote;
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
    required this.focusNode,
    required this.controller,
    required this.routeName,
  }) : super(key: key);

  @override
  State<LoteScannerWidget> createState() => _LoteScannerWidgetState();
}

class _LoteScannerWidgetState extends State<LoteScannerWidget> {
  Timer? _debounce;

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
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.trim().isNotEmpty) {
        widget.onValidateLote(value);
        widget.controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusColor = widget.loteIsOk ? green : yellow;
    final cardColor = widget.isLoteOk
        ? widget.loteIsOk
            ? Colors.green[100]
            : Colors.grey[300]
        : Colors.red[200];
    final expirationDate =
        widget.currentProductLote?.expirationDate?.toString() ?? "";

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
                    _buildZebraInput(),
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
              widget.routeName,
              arguments: [widget.currentProduct],
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      child: SizedBox(
        height: 20,
        child: TextFormField(
          autofocus: true,
          showCursor: false,
          controller: widget.controller,
          enabled: widget.locationIsOk &&
              widget.productIsOk &&
              !widget.loteIsOk &&
              !widget.quantityIsOk &&
              !widget.viewQuantity,
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
              widget.onValidateLote(value);
            }
            // Limpiar el controller después del submit
            widget.controller.clear();
          },
          decoration: InputDecoration(
            hintText: widget.currentProductLote?.name ?? 'Esperando escaneo',
            disabledBorder: InputBorder.none,
            hintStyle: const TextStyle(fontSize: 12, color: black),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
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
