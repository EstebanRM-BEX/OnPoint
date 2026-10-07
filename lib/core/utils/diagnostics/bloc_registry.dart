import 'package:flutter_bloc/flutter_bloc.dart';

/// Ficha de un Bloc/Cubit observado.
class BlocInfo {
  BlocInfo(this.name, this.createdAt);

  final String name;
  final DateTime createdAt;
  DateTime? closedAt;
  String lastState = '-';
  String lastEvent = '-';
  int changes = 0;

  bool get isClosed => closedAt != null;
}

/// Lleva qué Blocs/Cubits están vivos o cerrados (`onCreate`/`onClose`).
/// Solo guarda nombres de tipo, nunca `toString()` del estado: en estados con
/// listas de miles de productos sería costoso y retendría memoria.
class AppBlocObserver extends BlocObserver {
  AppBlocObserver._();
  static final AppBlocObserver instance = AppBlocObserver._();

  /// Cerrados que se conservan para el reporte (los vivos no se recortan).
  static const _maxClosed = 40;

  final Map<BlocBase, BlocInfo> _infos = {};

  /// Vivos primero, luego los cerrados más recientes.
  ///
  /// Un tipo de bloc aparece como "cerrado" una sola vez, por mucho que se haya
  /// abierto y cerrado: se muestra únicamente su último cierre, y solo si no
  /// hay una instancia viva de ese mismo tipo. Los vivos no se agrupan (dos
  /// instancias vivas del mismo tipo son justo lo que hay que ver).
  List<BlocInfo> get all {
    final list = _infos.values.toList();
    final aliveNames = {
      for (final i in list)
        if (!i.isClosed) i.name,
    };
    list.removeWhere((i) => i.isClosed && aliveNames.contains(i.name));
    list.sort((a, b) {
      if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  int get aliveCount => _infos.values.where((i) => !i.isClosed).length;
  int get closedCount => _infos.values.where((i) => i.isClosed).length;

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _infos[bloc] = BlocInfo(bloc.runtimeType.toString(), DateTime.now());
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _infos[bloc]?.lastEvent = event.runtimeType.toString();
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    final info = _infos[bloc];
    if (info == null) return;
    info.changes++;
    info.lastState = change.nextState.runtimeType.toString();
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    final info = _infos[bloc];
    if (info == null) return;
    info.closedAt = DateTime.now();
    // Se conserva solo el último cierre de cada tipo: los anteriores no se
    // muestran ni ocupan memoria.
    _infos.removeWhere(
      (key, other) =>
          !identical(key, bloc) && other.isClosed && other.name == info.name,
    );
    _trimClosed();
  }

  void _trimClosed() {
    final closed = _infos.entries.where((e) => e.value.isClosed).toList()
      ..sort((a, b) => a.value.closedAt!.compareTo(b.value.closedAt!));
    for (var i = 0; i < closed.length - _maxClosed; i++) {
      _infos.remove(closed[i].key);
    }
  }
}
