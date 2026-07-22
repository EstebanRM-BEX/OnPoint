import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/shared/widgets/edit_product_quantity_dialog.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';

/// Wrapper que conecta el diálogo genérico [EditProductQuantityDialog] con
/// [PickingPickBloc]. La UI y las reglas de novedad/exceso viven en el
/// widget compartido; aquí solo se traduce hacia/desde este bloc y la BD.
class DialogEditProductPickWidget extends StatefulWidget {
  final ProductsBatch productsBatch;

  const DialogEditProductPickWidget({
    super.key,
    required this.productsBatch,
  });

  @override
  State<DialogEditProductPickWidget> createState() =>
      _DialogEditProductPickWidgetState();
}

class _DialogEditProductPickWidgetState
    extends State<DialogEditProductPickWidget> {
  @override
  void didChangeDependencies() {
    // Único punto donde PickingPickBloc carga la lista de novedades.
    context.read<PickingPickBloc>().add(LoadAllNovedadesPickEvent());
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PickingPickBloc>();
    final quantityRequested = (widget.productsBatch.quantity ?? 0).toDouble();
    final quantitySeparated =
        (widget.productsBatch.quantitySeparate ?? 0.0).toDouble();
    final quantityRemaining = quantityRequested - quantitySeparated;

    // BlocBuilder para reconstruir cuando lleguen las novedades cargadas
    // arriba (NovedadesLoadedState); el estado interno del diálogo
    // (cantidad tecleada, novedad seleccionada) se conserva entre rebuilds.
    return BlocBuilder<PickingPickBloc, PickingPickState>(
      builder: (context, state) {
        return EditProductQuantityDialog(
          productId: '${widget.productsBatch.productId}',
          quantityRequested: quantityRequested,
          quantitySeparated: quantitySeparated,
          novedades: bloc.novedades,
          initialNovedad:
              (widget.productsBatch.observation?.isNotEmpty ?? false)
                  ? widget.productsBatch.observation
                  : null,
          onConfirm: (cantidad, novedad) async {
            final cantidadRequest = quantitySeparated + cantidad;

            if (novedad != null && cantidad < quantityRemaining) {
              // Usa el repositorio de tbl_pick_products (no el genérico
              // DataBaseSqlite.updateNovedad, que escribe en tblbatch_products
              // y no tiene efecto sobre los productos de este módulo).
              await bloc.db.pickProductsRepository.updateNovedad(
                widget.productsBatch.batchId ?? 0,
                widget.productsBatch.idProduct ?? 0,
                novedad,
                widget.productsBatch.idMove ?? 0,
              );
            }

            bloc.add(ChangeQuantitySeparate(
              cantidadRequest,
              widget.productsBatch.idProduct ?? 0,
              widget.productsBatch.idMove ?? 0,
            ));

            bloc.add(SendProductEditOdooEvent(
              widget.productsBatch,
              cantidadRequest,
            ));
          },
        );
      },
    );
  }
}
