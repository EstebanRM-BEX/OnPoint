import 'package:flutter/material.dart';

/// Reconstruye todo el árbol de la app desde cero.
///
/// Al cambiar la key del subárbol, Flutter descarta los widgets actuales y
/// crea unos nuevos. Como los `BlocProvider` del root se recrean, todos los
/// blocs se cierran (dispose) y se instancian limpios. Esto es lo que evita
/// que quede estado de una sesión en la siguiente.
///
/// Requisito: los blocs registrados en `getIt` deben ser `@injectable`
/// (factory) y no singletons, o `getIt<T>()` devolvería la instancia vieja
/// ya cerrada.
class AppRestart extends StatefulWidget {
  AppRestart({required this.child}) : super(key: globalKey);

  final Widget child;

  static final GlobalKey<_AppRestartState> globalKey =
      GlobalKey<_AppRestartState>();

  /// Recrea el árbol. Seguro de llamar sin `BuildContext`.
  static void restart() => globalKey.currentState?._restart();

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();
  bool _mountChild = true;

  /// El reinicio ocurre en dos frames a propósito.
  ///
  /// La app usa un `navigatorKey` global. Si montáramos el árbol nuevo en el
  /// mismo frame en que se desmonta el viejo, ambos `Navigator` reclamarían
  /// esa misma GlobalKey a la vez y Flutter lanzaría "Multiple widgets used
  /// the same GlobalKey", dejando la UI congelada. Vaciando el subárbol
  /// primero, el Navigator viejo libera la key antes de que nazca el nuevo.
  void _restart() {
    if (!mounted) return;
    setState(() => _mountChild = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _key = UniqueKey();
        _mountChild = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_mountChild) {
      // Frame puente: sin Navigator, sin blocs. `Directionality` y `ColoredBox`
      // porque aquí arriba todavía no existe ningún MaterialApp.
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(color: Colors.white),
      );
    }

    return KeyedSubtree(key: _key, child: widget.child);
  }
}
