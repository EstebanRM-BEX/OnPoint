// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/bloc/inventario_bloc.dart';

class DialogInventario extends StatelessWidget {
  const DialogInventario({
    super.key,
    required this.contextHome,
  });

  final BuildContext contextHome;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SELECCION DE INVENTARIO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColorApp,
                  fontSize: 20,
                )),
            const SizedBox(height: 10),
            Center(
              child: Text(
                  'Seleccione una de las siguientes opciones para realizar el proceso de inventario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: black,
                    fontSize: 12,
                  )),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () async {
                  //obtenemos las ubicaciones
                  context.read<InventarioBloc>().add(GetLocationsEvent());
                  //obtenemos los productos
                  context.read<InventarioBloc>().add(GetProductsForDB());
                  //obtenemos todos los demas codigos de barras
                  context
                      .read<InventarioBloc>()
                      .add(FetchAllBarcodesInventarioEvent());
                  //cargamos la configuracion
                  context
                      .read<InventarioBloc>()
                      .add(LoadConfigurationsUserInventory());
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    'inventario',
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('INVENTARIO RAPIDO',
                    style: TextStyle(
                      color: white,
                      fontSize: 14,
                    ))),
            ElevatedButton(
                onPressed: () {
                  context.read<ConteoBloc>().add(GetLocationsConteoEvent());
                  context.read<ConteoBloc>().add(GetProductsFromDBEvent());
                  context.read<ConteoBloc>().add(GetConteosFromDBEvent());
                  context
                      .read<ConteoBloc>()
                      .add(LoadConfigurationsUserConteo());

                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    'conteo',
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('CONTEO FISICO',
                    style: TextStyle(
                      color: white,
                      fontSize: 14,
                    ))),
            ElevatedButton(
                onPressed: () {
                  //cerramos el dialogo
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  minimumSize: const Size(200, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('CANCELAR',
                    style: TextStyle(
                      color: white,
                      fontSize: 14,
                    ))),
          ],
        )),
      ),
    );
  }
}
