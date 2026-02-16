// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';

class DialogDevoluciones extends StatelessWidget {
  const DialogDevoluciones({
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
            Text('SELECCION DE DEVOLUCION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColorApp,
                  fontSize: 16,
                )),
            const SizedBox(height: 10),
            Center(
              child: Text(
                  'Seleccione una de las siguientes opciones para realizar el proceso de devolucion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: black,
                    fontSize: 12,
                  )),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  //pedir ubicaciones
                  context
                      .read<RecepcionBatchBloc>()
                      .add(GetLocationsDestReceptionBatchEvent());
                  //pedir las novedades
                  context
                      .read<RecepcionBatchBloc>()
                      .add(LoadAllNovedadesReceptionEvent());
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    'list-recepction-batch',
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('POR BATCH',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
            ElevatedButton(
                onPressed: () {
                  //pedir ubicaciones
                  context.read<RecepcionBloc>().add(GetLocationsDestEvent());
                  //pedir las novedades
                  context
                      .read<RecepcionBloc>()
                      .add(LoadAllNovedadesOrderEvent());
                  //cerramos el dialogo
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    'list-devoluciones',
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('INDIVIDUAL',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
            ElevatedButton(
                onPressed: () {
                  context
                      .read<DevolucionesBloc>()
                      .add(LoadConfigurationsUser());
                  context.read<DevolucionesBloc>().add(GetProductsList());
                  context.read<DevolucionesBloc>().add(LoadLocationsEvent());
                  context.read<DevolucionesBloc>().add(LoadTercerosEvent());
                  context
                      .read<DevolucionesBloc>()
                      .add(FetchAllBarcodesInventarioEvent());
                  //cerramos el dialogo
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    'devoluciones-create',
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('CREAR NUEVA',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
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
                      fontSize: 12,
                    ))),
          ],
        )),
      ),
    );
  }
}
