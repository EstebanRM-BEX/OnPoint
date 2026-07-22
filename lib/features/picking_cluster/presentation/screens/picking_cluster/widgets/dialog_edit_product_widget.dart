import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/shared/widgets/edit_product_quantity_dialog.dart';

/// Wrapper que conecta el diálogo genérico [EditProductQuantityDialog] con
/// [ClusterPickingBloc]. La UI y las reglas de novedad/exceso viven en el
/// widget compartido; aquí solo se traduce hacia/desde este bloc.
class DialogEditProductWidget extends StatelessWidget {
  final BatchProduct productsBatch;

  const DialogEditProductWidget({
    super.key,
    required this.productsBatch,
  });

  @override
  Widget build(BuildContext context) {
    final batchBloc = context.read<ClusterPickingBloc>();
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
      onConfirm: (cantidad, novedad) async {
        final cantidadTotalRequest = quantitySeparated + cantidad;

        if (novedad != null && cantidad < quantityRemaining) {
          batchBloc.add(UpdateNovedadProductEvent(novedad, productsBatch));
        }

        batchBloc.quantitySeparate(
          productsBatch.idProduct ?? 0,
          productsBatch.batchId ?? 0,
          productsBatch.idMove ?? 0,
          cantidadTotalRequest,
        );

        batchBloc.add(
          SendProductEditOdooEvent(productsBatch, cantidadTotalRequest),
        );
      },
    );
  }
}
