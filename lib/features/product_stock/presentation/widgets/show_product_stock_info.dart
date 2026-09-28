import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wms_app/features/product_stock/domain/usecases/get_product_stock_info.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

import 'product_stock_info_dialog.dart';

bool _inFlight = false;

/// Consulta `/api/product/stock_info` y muestra el resultado.
///
/// Punto de entrada único para toda la app: abre el diálogo de carga, llama
/// al endpoint y muestra [ProductStockInfoDialog] o el error real con
/// [showScrollableErrorDialog]. Ignora toques repetidos mientras hay una
/// consulta en curso.
Future<void> showProductStockInfo(BuildContext context, int productId) async {
  if (_inFlight) return;
  _inFlight = true;

  final dialogMounted = Completer<BuildContext>();
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      if (!dialogMounted.isCompleted) dialogMounted.complete(dialogContext);
      return const DialogLoading(message: 'Consultando ubicaciones...');
    },
  ));

  try {
    final result = await getIt<GetProductStockInfo>()(productId)
        .whenComplete(() async {
      // Cerrar el loading solo cuando ya montó (evita pop de otra ruta).
      final loadingContext = await dialogMounted.future;
      if (loadingContext.mounted) Navigator.of(loadingContext).pop();
    });

    await result.fold(
      (failure) => showScrollableErrorDialog(failure.message),
      (info) {
        if (!context.mounted) return Future.value();
        return showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ProductStockInfoDialog(info: info),
        );
      },
    );
  } finally {
    _inFlight = false;
  }
}
