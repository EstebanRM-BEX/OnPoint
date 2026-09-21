import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';

class DialogDevoluciones extends StatelessWidget {
  const DialogDevoluciones({super.key, required this.contextHome});

  final BuildContext contextHome;

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.keyboard_return,
      title: 'Selección de Devolución',
      message:
          'Seleccione una de las siguientes opciones para realizar el '
          'proceso de devolución',
      options: [
        SelectionOption(
          title: 'Por Batch',
          tag: 'Multi-orden',
          description: 'Devoluciones agrupadas por lote',
          icon: Icons.layers_outlined,
          onTap: () {
            final bloc = context.read<RecepcionBatchBloc>();
            bloc.add(GetLocationsDestReceptionBatchEvent()); // ubicaciones
            bloc.add(LoadAllNovedadesReceptionEvent()); // novedades
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, 'list-recepction-batch');
          },
        ),
        SelectionOption(
          title: 'Individual',
          description: 'Una devolución a la vez',
          icon: Icons.receipt_long_outlined,
          onTap: () {
            final bloc = context.read<RecepcionBloc>();
            bloc.add(GetLocationsDestEvent()); // ubicaciones
            bloc.add(LoadAllNovedadesOrderEvent()); // novedades
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, 'list-devoluciones');
          },
        ),
        SelectionOption(
          title: 'Crear Nueva',
          description: 'Registrar una devolución nueva',
          icon: Icons.add_circle_outline,
          onTap: () {
            context.read<DevolucionesBloc>().add(InitializeDevolucionesData());
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, 'devoluciones-create');
          },
        ),
      ],
    );
  }
}
