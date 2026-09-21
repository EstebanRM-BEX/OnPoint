import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';

class DialogInventario extends StatelessWidget {
  const DialogInventario({super.key, required this.contextHome});

  final BuildContext contextHome;

  void _goToInventarioRapido(BuildContext context) {
    final bloc = context.read<InventarioBloc>();
    bloc.add(GetLocationsEvent()); // ubicaciones
    bloc.add(GetProductsForDB()); // productos
    bloc.add(FetchAllBarcodesInventarioEvent()); // demás códigos de barras
    bloc.add(LoadConfigurationsUserInventory()); // configuración

    Navigator.pop(context);
    // Se valida con productosCount (ya cargado desde BD en el initState del
    // home) y no con la lista en memoria, que GetProductsForDB aún no pobló.
    if (bloc.productosCount == 0) {
      Get.snackbar(
        '360 Software Informa',
        'No hay productos cargados, por favor descargue los productos desde '
            'la configuración',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: const Icon(Icons.error, color: Colors.red),
      );
      return;
    }
    Navigator.pushReplacementNamed(context, 'inventario');
  }

  void _goToConteo(BuildContext context) {
    final bloc = context.read<ConteoBloc>();
    bloc.add(GetLocationsConteoEvent()); // ubicaciones
    bloc.add(GetProductsFromDBEvent()); // productos
    bloc.add(GetConteosFromDBEvent()); // conteos
    bloc.add(LoadConfigurationsUserConteo()); // configuración
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, 'conteo');
  }

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.shelves,
      title: 'Selección de Inventario',
      message:
          'Seleccione una de las siguientes opciones para realizar el '
          'proceso de inventario',
      options: [
        SelectionOption(
          title: 'Inventario Rápido',
          description: 'Ajuste inmediato por ubicación',
          icon: Icons.bolt_outlined,
          onTap: () => _goToInventarioRapido(context),
        ),
        SelectionOption(
          title: 'Conteo Físico',
          description: 'Conteos planificados asignados',
          icon: Icons.fact_check_outlined,
          onTap: () => _goToConteo(context),
        ),
      ],
    );
  }
}
