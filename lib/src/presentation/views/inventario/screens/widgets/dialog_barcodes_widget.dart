import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';

class DialogBarcodesInventario extends StatelessWidget {
  const DialogBarcodesInventario({
    super.key,
    required this.listOfBarcodes,
  });

  final List<BarcodeInventario> listOfBarcodes;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 5,
        sigmaY: 5,
      ),
      child: AlertDialog(
        backgroundColor: white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            'Codigo de barras por paquete',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryColorApp,
              fontSize: 16,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Envolvemos el ListView.builder con un Container para darle un tamaño fijo
              SizedBox(
                height: 300, // Puedes ajustar la altura
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: listOfBarcodes.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      color: white,
                      child: ListTile(
                        leading: SizedBox(
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
                        title: Text(
                          listOfBarcodes[index].barcode ?? "",
                          style:
                              TextStyle(color: primaryColorApp, fontSize: 12),
                        ),
                        subtitle: Text(
                          'Cantidad: ${listOfBarcodes[index].cantidad}',
                          style: const TextStyle(color: black, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: white),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
