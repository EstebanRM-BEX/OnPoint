import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Franja inferior de cantidad con el diseño del módulo anterior: "Recoger:
/// N und", lector con el conteo escaneado, lápiz para digitar (con permiso),
/// campo manual y "APLICAR CANTIDAD".
class CantidadScanCard extends StatelessWidget {
  /// El paso de cantidad está activo (producto confirmado).
  final bool activo;

  /// El último escaneo de cantidad falló (tarjeta roja).
  final bool conError;
  final double cantidad;
  final double total;
  final String unidades;
  final bool editando;
  final bool puedeEditar;
  final bool ocupado;
  final TextEditingController scanController;
  final FocusNode scanFocus;
  final ValueChanged<String> onEscaneo;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAlternarEdicion;
  final VoidCallback onAplicar;

  const CantidadScanCard({
    super.key,
    required this.activo,
    required this.cantidad,
    required this.total,
    required this.unidades,
    required this.editando,
    required this.puedeEditar,
    required this.ocupado,
    required this.scanController,
    required this.scanFocus,
    required this.onEscaneo,
    required this.controller,
    required this.focusNode,
    required this.onAlternarEdicion,
    required this.onAplicar,
    this.conError = false,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final fmt = PackFormatos.cantidad;
    return SizedBox(
      width: ancho,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              color: conError
                  ? Colors.red[200]
                  : (activo ? white : Colors.grey[300]),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Text(
                      'Recoger:',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        fmt(total),
                        style: TextStyle(color: primaryColorApp, fontSize: 14),
                      ),
                    ),
                    Text(
                      unidades,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    const Spacer(),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: BarcodeScannerField(
                                controller: scanController,
                                focusNode: scanFocus,
                                autofocus: false,
                                clearOnScan: true,
                                refocusOnScan: true,
                                onBarcodeScanned: (v, _) => onEscaneo(v),
                              ),
                            ),
                            IgnorePointer(
                              child: Text(
                                fmt(cantidad),
                                style: const TextStyle(
                                  color: black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: puedeEditar && activo
                          ? onAlternarEdicion
                          : null,
                      icon: Icon(
                        Icons.edit_note_rounded,
                        color: primaryColorApp,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (editando)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: SizedBox(
                height: 40,
                child: TextFormField(
                  focusNode: focusNode,
                  autofocus: true,
                  controller: controller,
                  showCursor: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onFieldSubmitted: (_) => onAplicar(),
                  decoration: InputDecorations.authInputDecoration(
                    hintText: 'Cantidad',
                    labelText: 'Cantidad',
                    suffixIconButton: IconButton(
                      onPressed: () {
                        controller.clear();
                        onAlternarEdicion();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: activo && !ocupado ? onAplicar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: Size(ancho * 0.93, 35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'APLICAR CANTIDAD',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
