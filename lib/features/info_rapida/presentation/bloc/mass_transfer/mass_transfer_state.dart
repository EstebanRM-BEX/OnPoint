part of 'mass_transfer_bloc.dart';

enum MassTransferStatus { initial, ready, loading, success, failure }

/// Línea de producto seleccionada para la transferencia masiva, con su cantidad
/// disponible y la cantidad a transferir editable.
class ItemTransferenciaLinea extends Equatable {
  final ProductoUbicacion producto;
  final double cantidadATransferir;
  final bool cantidadValida;

  const ItemTransferenciaLinea({
    required this.producto,
    required this.cantidadATransferir,
    this.cantidadValida = true,
  });

  ItemTransferenciaLinea copyWith({
    ProductoUbicacion? producto,
    double? cantidadATransferir,
    bool? cantidadValida,
  }) {
    return ItemTransferenciaLinea(
      producto: producto ?? this.producto,
      cantidadATransferir: cantidadATransferir ?? this.cantidadATransferir,
      cantidadValida: cantidadValida ?? this.cantidadValida,
    );
  }

  @override
  List<Object?> get props => [producto, cantidadATransferir, cantidadValida];
}

class MassTransferState extends Equatable {
  final MassTransferStatus status;
  final int idAlmacen;
  final int idUbicacionOrigen;
  final String nombreUbicacionOrigen;
  final List<ItemTransferenciaLinea> items;

  final UbicacionCatalogo? ubicacionDestino;
  final bool ubicacionDestinoValida;
  final String? dateStart;
  final String? dateEnd;

  final List<UbicacionCatalogo> ubicacionesDestino;
  final List<UbicacionCatalogo> ubicacionesDestinoFiltradas;
  final String queryUbicacionDestino;
  final String? almacenDestinoFiltro;
  final List<String> almacenesDisponibles;

  final TransferenciaMasivaResult? resultadoTransferencia;
  final String? mensajeError;
  final Failure? failure;

  const MassTransferState({
    this.status = MassTransferStatus.initial,
    this.idAlmacen = 0,
    this.idUbicacionOrigen = 0,
    this.nombreUbicacionOrigen = '',
    this.items = const [],
    this.ubicacionDestino,
    this.ubicacionDestinoValida = false,
    this.dateStart,
    this.dateEnd,
    this.ubicacionesDestino = const [],
    this.ubicacionesDestinoFiltradas = const [],
    this.queryUbicacionDestino = '',
    this.almacenDestinoFiltro,
    this.almacenesDisponibles = const [],
    this.resultadoTransferencia,
    this.mensajeError,
    this.failure,
  });

  bool get isLoading => status == MassTransferStatus.loading;
  bool get isSuccess => status == MassTransferStatus.success;

  bool get todosItemsValidos =>
      items.isNotEmpty &&
      items.every((i) => i.cantidadValida && i.cantidadATransferir > 0);

  bool get puedeTransferir =>
      ubicacionDestinoValida &&
      ubicacionDestino != null &&
      todosItemsValidos &&
      status != MassTransferStatus.loading;

  int get totalItems => items.length;

  /// Retorna la clave del propietario compartido de los ítems actuales, o null si ninguno.
  String? get propietarioKeyComun {
    if (items.isEmpty) return null;
    final first = items.first.producto;
    return PropietarioRules.normalizeKey(
      tieneManejoPropietario: first.manejoPropietario,
      propietario: first.propietario,
    );
  }

  MassTransferState copyWith({
    MassTransferStatus? status,
    int? idAlmacen,
    int? idUbicacionOrigen,
    String? nombreUbicacionOrigen,
    List<ItemTransferenciaLinea>? items,
    UbicacionCatalogo? Function()? ubicacionDestino,
    bool? ubicacionDestinoValida,
    String? dateStart,
    String? dateEnd,
    List<UbicacionCatalogo>? ubicacionesDestino,
    List<UbicacionCatalogo>? ubicacionesDestinoFiltradas,
    String? queryUbicacionDestino,
    String? Function()? almacenDestinoFiltro,
    List<String>? almacenesDisponibles,
    TransferenciaMasivaResult? Function()? resultadoTransferencia,
    String? Function()? mensajeError,
    Failure? Function()? failure,
  }) {
    return MassTransferState(
      status: status ?? this.status,
      idAlmacen: idAlmacen ?? this.idAlmacen,
      idUbicacionOrigen: idUbicacionOrigen ?? this.idUbicacionOrigen,
      nombreUbicacionOrigen:
          nombreUbicacionOrigen ?? this.nombreUbicacionOrigen,
      items: items ?? this.items,
      ubicacionDestino: ubicacionDestino != null
          ? ubicacionDestino()
          : this.ubicacionDestino,
      ubicacionDestinoValida:
          ubicacionDestinoValida ?? this.ubicacionDestinoValida,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      ubicacionesDestino: ubicacionesDestino ?? this.ubicacionesDestino,
      ubicacionesDestinoFiltradas:
          ubicacionesDestinoFiltradas ?? this.ubicacionesDestinoFiltradas,
      queryUbicacionDestino:
          queryUbicacionDestino ?? this.queryUbicacionDestino,
      almacenDestinoFiltro: almacenDestinoFiltro != null
          ? almacenDestinoFiltro()
          : this.almacenDestinoFiltro,
      almacenesDisponibles:
          almacenesDisponibles ?? this.almacenesDisponibles,
      resultadoTransferencia: resultadoTransferencia != null
          ? resultadoTransferencia()
          : this.resultadoTransferencia,
      mensajeError: mensajeError != null ? mensajeError() : this.mensajeError,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
        status,
        idAlmacen,
        idUbicacionOrigen,
        nombreUbicacionOrigen,
        items,
        ubicacionDestino,
        ubicacionDestinoValida,
        dateStart,
        dateEnd,
        ubicacionesDestino,
        ubicacionesDestinoFiltradas,
        queryUbicacionDestino,
        almacenDestinoFiltro,
        almacenesDisponibles,
        resultadoTransferencia,
        mensajeError,
        failure,
      ];
}
