import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';

/// Expone el [InventarioBloc] a una pantalla del módulo y lo cierra al salir
/// del módulo si no hay nada en curso.
///
/// Con una ubicación, producto o lote elegido el bloc se conserva
/// (`InventarioBloc.resumeOrCreate`) para retomar donde quedó; sin eso se
/// libera, así no queda vivo en el Home con sus listas y controllers.
///
/// La instancia vive en el State: el builder de la ruta puede re-ejecutarse.
class InventarioScope extends StatefulWidget {
  const InventarioScope({super.key, required this.bloc, required this.child});

  /// Bloc que llegó por argumento de ruta; si es null se retoma/crea el borrador.
  final InventarioBloc? bloc;
  final Widget child;

  @override
  State<InventarioScope> createState() => _InventarioScopeState();
}

class _InventarioScopeState extends State<InventarioScope> {
  late final InventarioBloc _bloc =
      widget.bloc ?? InventarioBloc.resumeOrCreate();

  @override
  void initState() {
    super.initState();
    _bloc.attachScope();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _reloadAfterTransition(),
    );
  }

  /// Espera a que termine la animación de la ruta antes de cargar las listas,
  /// para que la pantalla aparezca de inmediato en lugar de quedarse en blanco.
  void _reloadAfterTransition() {
    if (!mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _bloc.reloadIfPending();
      return;
    }
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(listener);
      if (mounted) _bloc.reloadIfPending();
    }

    animation.addStatusListener(listener);
  }

  @override
  void dispose() {
    _bloc.detachScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InventarioBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
