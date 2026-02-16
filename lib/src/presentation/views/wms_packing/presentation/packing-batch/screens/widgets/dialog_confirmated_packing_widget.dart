import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';

class DialogConfirmatedPacking extends StatefulWidget {
  const DialogConfirmatedPacking({
    super.key,
    required this.productos,
    required this.isCertificate,
    required this.isSticker,
    required this.onToggleSticker,
    required this.onConfirm,
  });

  final List<ProductoPedido> productos;
  final bool isCertificate;
  final bool isSticker;
  final void Function(bool newValue) onToggleSticker;
  final VoidCallback onConfirm;

  @override
  State<DialogConfirmatedPacking> createState() =>
      _DialogConfirmatedPackingState();
}

class _DialogConfirmatedPackingState extends State<DialogConfirmatedPacking> {
  late bool localSticker; // Estado interno del checkbox

  @override
  void initState() {
    super.initState();
    localSticker = widget.isSticker; // inicializamos con el valor que nos pasan
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 100,
                width: 200,
                child: SvgPicture.asset(
                  "assets/images/icono.svg",
                  height: 150,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '¿Está seguro de empacar los productos seleccionados?',
                  style: TextStyle(color: primaryColorApp, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Total de productos: ${widget.productos.length}',
                  style: const TextStyle(color: black, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        content: widget.isCertificate
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Incluir sticker de certificación',
                    style: TextStyle(color: black, fontSize: 14),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: localSticker,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              localSticker = value;
                            });
                            widget.onToggleSticker(value);
                          }
                        },
                      ),
                      Icon(Icons.print, color: primaryColorApp),
                    ],
                  ),
                ],
              )
            : const Text(
                "Está realizando una separación sin certificado, tampoco se incluirá el sticker de certificación.",
                style: TextStyle(color: black, fontSize: 14),
                textAlign: TextAlign.center,
              ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
