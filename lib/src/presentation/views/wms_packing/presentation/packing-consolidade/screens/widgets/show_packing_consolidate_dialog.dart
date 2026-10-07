import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';

/// `showDialog` que re-expone el [PackingConsolidateBloc] de la pantalla.
///
/// El bloc vive escopeado a las rutas del flujo y los diálogos se montan en una
/// ruta hermana (no descendiente), así que sin esto
/// `context.read<PackingConsolidateBloc>()` dentro del diálogo no lo encuentra.
Future<T?> showPackingConsolidateDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final bloc = context.read<PackingConsolidateBloc>();
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: Builder(builder: builder),
    ),
  );
}
