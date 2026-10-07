import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';

/// Expone el [PackingConsolidateBloc] del flujo a una pantalla y lo cierra al
/// salir del flujo.
///
/// Todas las pantallas comparten la misma instancia
/// (`PackingConsolidateBloc.resumeOrCreate`): la navegación interna es por
/// `pushReplacementNamed`, así que cada una se registra al montarse y la última
/// en descartarse cierra el bloc. La instancia vive en el State: el builder de
/// la ruta puede re-ejecutarse.
class PackingConsolidateScope extends StatefulWidget {
  const PackingConsolidateScope({super.key, required this.child});

  final Widget child;

  @override
  State<PackingConsolidateScope> createState() =>
      _PackingConsolidateScopeState();
}

class _PackingConsolidateScopeState extends State<PackingConsolidateScope> {
  late final PackingConsolidateBloc _bloc =
      PackingConsolidateBloc.resumeOrCreate();

  @override
  void initState() {
    super.initState();
    _bloc.attachScope();
  }

  @override
  void dispose() {
    _bloc.detachScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PackingConsolidateBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
