import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/shared/widgets/edit_product_quantity_dialog.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';

/// Wrapper que conecta el diálogo genérico [EditProductQuantityDialog] con
/// [BatchBloc]. La UI y las reglas de novedad viven en el widget
/// compartido; aquí solo se traduce hacia/desde este bloc y la BD, y se
/// aplica la regla de exceso propia de Batchs (permite exceso en productos
/// tipo 'components' si el usuario tiene el permiso correspondiente).
class DialogEditProductWidget extends StatelessWidget {
  final ProductsBatch productsBatch;

  const DialogEditProductWidget({
    super.key,
    required this.productsBatch,
  });

  @override
  Widget build(BuildContext context) {
    final batchBloc = context.read<BatchBloc>();
    final typePicking = batchBloc.typePicking;
    final bool allowExcess = batchBloc
            .configurations.result?.result?.allowMoveExcessProduction ==
        true;

    final quantityRequested = (productsBatch.quantity ?? 0).toDouble();
    final quantitySeparated =
        (productsBatch.quantitySeparate ?? 0.0).toDouble();
    final quantityRemaining = quantityRequested - quantitySeparated;

    return EditProductQuantityDialog(
      productId: '${productsBatch.productId}',
      quantityRequested: quantityRequested,
      quantitySeparated: quantitySeparated,
      novedades: batchBloc.novedades,
      initialNovedad: (productsBatch.observation?.isNotEmpty ?? false)
          ? productsBatch.observation
          : null,
      isExcessError: (cantidad, remaining) {
        if (typePicking == 'components') {
          // Componentes: es error SOLO si no tiene el permiso.
          return !allowExcess;
        }
        // Batch: siempre es error si se pasa.
        return true;
      },
      onConfirm: (cantidad, novedad) async {
        final cantidadTotalRequest = quantitySeparated + cantidad;

        if (novedad != null && cantidad < quantityRemaining) {
          final db = DataBaseSqlite();
          await db.updateNovedad(
            productsBatch.batchId ?? 0,
            productsBatch.idProduct ?? 0,
            novedad,
            productsBatch.idMove ?? 0,
            typePicking,
          );
        }

        batchBloc.add(ChangeQuantitySeparate(
          cantidadTotalRequest,
          productsBatch.idProduct ?? 0,
          productsBatch.idMove ?? 0,
          typePicking,
        ));

        batchBloc.add(SendProductEditOdooEvent(
          productsBatch,
          cantidadTotalRequest,
          typePicking,
        ));
      },
    );
  }
}
