import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/presentation/bloc/scan/expedicion_scan_bloc.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_validar_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_scan_item_suelto_card_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_scan_item_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_scan_paquete_card_widget.dart';

/// Screen de detalle de un paquete (items_pack_pendientes) o de un producto
/// suelto (items_pendientes), con la acción "Validar expedición". Por ahora
/// la validación es solo visual — sin llamada a backend.
class ScanProductExpeditionScreen extends StatelessWidget {
  final PaqueteExpedicion? paquete;
  final ItemSueltoExpedicion? itemSuelto;

  const ScanProductExpeditionScreen({super.key, this.paquete, this.itemSuelto});

  void _handleValidar(BuildContext context) {
    final message = paquete != null
        ? '¿Está seguro de validar el paquete "${paquete!.packageName ?? "sin nombre"}" con sus ${paquete!.items.length} producto(s)?'
        : '¿Está seguro de validar el producto "${itemSuelto?.productName ?? "sin nombre"}" con cantidad ${itemSuelto?.quantity ?? 0} ${itemSuelto?.uom ?? ""}?';

    showDialog(
      context: context,
      builder: (dialogContext) => DialogValidarExpedicionWidget(
        message: message,
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context.read<ExpedicionScanBloc>().add(const ValidarExpedicionScanEvent());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpedicionScanBloc, ExpedicionScanState>(
      listener: (context, state) {
        if (state is ExpedicionScanValidated) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: primaryColorApp,
        appBar: AppBar(
          backgroundColor: primaryColorApp,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text('EXPEDICIÓN',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
          ),
        ),
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (paquete != null) ...[
                        ExpedicionScanPaqueteCardWidget(paquete: paquete!),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Text(
                            'Productos',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        ...paquete!.items
                            .map((i) => ExpedicionScanItemWidget(item: i)),
                      ] else if (itemSuelto != null)
                        ExpedicionScanItemSueltoCardWidget(item: itemSuelto!),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: () => _handleValidar(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'VALIDAR EXPEDICIÓN',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
