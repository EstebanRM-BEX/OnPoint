import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/presentation/bloc/detail/expedicion_detail_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/scan/expedicion_scan_bloc.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_deshacer_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_item_suelto_row_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_paquete_expandible_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

/// Tab "Listo": paquetes e items sueltos ya validados. Los paquetes se
/// pueden expandir para ver sus productos (los sueltos no tienen hijos, se
/// muestran igual que en "Por hacer"). Cada card tiene un ícono para
/// deshacer la validación y que vuelva a "Por hacer".
class ExpedicionDetailTabListo extends StatefulWidget {
  final ExpedicionDetail detail;

  const ExpedicionDetailTabListo({super.key, required this.detail});

  @override
  State<ExpedicionDetailTabListo> createState() =>
      _ExpedicionDetailTabListoState();
}

class _ExpedicionDetailTabListoState extends State<ExpedicionDetailTabListo> {
  int? _expandedPackingId;

  ExpedicionDetail get detail => widget.detail;

  void _refreshDetail(BuildContext context) {
    final expeditionId = detail.pedido.expeditionId;
    if (expeditionId == null) return;
    context
        .read<ExpedicionDetailBloc>()
        .add(LoadExpedicionDetailEvent(expeditionId));
  }

  void _handleDeshacerPaquete(BuildContext context, PaqueteExpedicion p) {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogDeshacerExpedicionWidget(
        message:
            '¿Está seguro de deshacer la validación del paquete "${p.packageName ?? "sin nombre"}" con sus ${p.items.length} producto(s)? Volverá a "Por hacer".',
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context
              .read<ExpedicionScanBloc>()
              .add(DeshacerExpedicionScanEvent(paquete: p));
        },
      ),
    );
  }

  void _handleDeshacerItemSuelto(BuildContext context, ItemSueltoExpedicion i) {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogDeshacerExpedicionWidget(
        message:
            '¿Está seguro de deshacer la validación del producto "${i.productName ?? "sin nombre"}" con cantidad ${i.quantity ?? 0} ${i.uom ?? ""}? Volverá a "Por hacer".',
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context
              .read<ExpedicionScanBloc>()
              .add(DeshacerExpedicionScanEvent(itemSuelto: i));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpedicionScanBloc, ExpedicionScanState>(
      listener: (context, state) {
        if (state is ExpedicionScanUndoing) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DialogLoading(
                message: 'Deshaciendo validación...'),
          );
        }
        if (state is ExpedicionScanUndone) {
          Navigator.pop(context); // cierra el diálogo de carga
          _refreshDetail(context);
        }
        if (state is ExpedicionScanError) {
          Navigator.pop(context); // cierra el diálogo de carga
          Get.snackbar(
            'Error',
            state.message,
            backgroundColor: white,
            colorText: red,
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      child: Builder(builder: (context) {
        final paquetes = detail.paquetesListos;
        final itemsSueltos = detail.itemsSueltosListos;

        if (paquetes.isEmpty && itemsSueltos.isEmpty) {
          return const Center(
            child: Text('No hay productos listos',
                style: TextStyle(color: grey, fontSize: 14)),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (paquetes.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text('Paquetes',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ...paquetes.map((p) => ExpedicionPaqueteExpandibleWidget(
                    paquete: p,
                    isExpanded: p.packingId != null &&
                        p.packingId == _expandedPackingId,
                    onTap: () => setState(() {
                      _expandedPackingId = p.packingId == _expandedPackingId
                          ? null
                          : p.packingId;
                    }),
                    onUndo: () => _handleDeshacerPaquete(context, p),
                  )),
            ],
            if (itemsSueltos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text('Productos sueltos',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ...itemsSueltos.map((i) => ExpedicionItemSueltoRowWidget(
                    item: i,
                    onUndo: () => _handleDeshacerItemSuelto(context, i),
                  )),
            ],
          ],
        );
      }),
    );
  }
}
