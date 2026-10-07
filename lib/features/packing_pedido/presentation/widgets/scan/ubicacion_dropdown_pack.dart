import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// Contenido de la tarjeta de ubicación (mismo diseño que el módulo
/// anterior): dropdown "Ubicación de origen" para confirmar a mano (solo con
/// permiso y mientras no esté confirmada), aviso si la ubicación no tiene
/// código de barras y el nombre de la ubicación.
class UbicacionDropdownPack extends StatelessWidget {
  final ProductoPacking producto;
  final bool confirmada;

  /// null = sin permiso para confirmar a mano.
  final VoidCallback? onConfirmar;

  const UbicacionDropdownPack({
    super.key,
    required this.producto,
    required this.confirmada,
    this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final ubicacion = producto.locationName;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            underline: Container(height: 0),
            borderRadius: BorderRadius.circular(10),
            focusColor: Colors.white,
            isExpanded: true,
            hint: Text(
              'Ubicación de origen',
              style: TextStyle(fontSize: 14, color: primaryColorApp),
            ),
            icon: Image.asset(
              'assets/icons/ubicacion.png',
              color: primaryColorApp,
              width: 20,
            ),
            value: null,
            items: [
              DropdownMenuItem<String>(
                value: ubicacion,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.green[100],
                  ),
                  width: MediaQuery.sizeOf(context).width * 0.9,
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ubicacion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: black, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: onConfirmar == null || confirmada
                ? null
                : (_) => onConfirmar!(),
          ),
          if (producto.barcodeLocation.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sin codigo de barras',
                style: TextStyle(fontSize: 14, color: red),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ubicacion,
              style: const TextStyle(fontSize: 14, color: black),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
