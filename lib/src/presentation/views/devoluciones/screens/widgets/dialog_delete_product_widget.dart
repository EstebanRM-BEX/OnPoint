
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

class DialogDeletedProduct extends StatelessWidget {
  const DialogDeletedProduct({
    super.key,
    required this.product,
  });

  final ProductDevolucion product;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        title: Center(
            child: Text(
          'Confirmar eliminación',
          style: TextStyle(
              color: primaryColorApp, fontSize: 16),
        )),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este producto de la devolución?',
            style: TextStyle(fontSize: 14, color: black)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              context.read<DevolucionesBloc>().add(RemoveProduct(product));
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
