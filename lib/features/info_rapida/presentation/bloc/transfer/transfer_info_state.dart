part of 'transfer_info_bloc.dart';

enum TransferInfoStatus { initial, ready, loading, success, failure }

class TransferInfoState extends Equatable {
  final TransferInfoStatus status;
  final int idAlmacen;
  final int idMove;
  final int idProducto;
  final String nombreProducto;
  final int idLote;
  final String nombreLote;
  final int idUbicacionOrigen;
  final String nombreUbicacionOrigen;
  final double cantidadDisponible;
  final int? idPropietario;
  final String? propietario;
  final bool? manejoPropietario;

  final UbicacionCatalogo? ubicacionDestino;
  final bool ubicacionDestinoValida;
  final double cantidadATransferir;
  final bool cantidadValida;
  final String observacion;
  final String? dateStart;
  final String? dateEnd;

  final List<UbicacionCatalogo> ubicacionesDestino;
  final List<UbicacionCatalogo> ubicacionesDestinoFiltradas;
  final String queryUbicacionDestino;
  final String? almacenDestinoFiltro;
  final List<String> almacenesDisponibles;

  final TransferenciaIndividualResult? resultadoTransferencia;
  final String? mensajeError;
  final Failure? failure;

  const TransferInfoState({
    this.status = TransferInfoStatus.initial,
    this.idAlmacen = 0,
    this.idMove = 0,
    this.idProducto = 0,
    this.nombreProducto = '',
    this.idLote = 0,
    this.nombreLote = '',
    this.idUbicacionOrigen = 0,
    this.nombreUbicacionOrigen = '',
    this.cantidadDisponible = 0.0,
    this.idPropietario,
    this.propietario,
    this.manejoPropietario,
    this.ubicacionDestino,
    this.ubicacionDestinoValida = false,
    this.cantidadATransferir = 0.0,
    this.cantidadValida = false,
    this.observacion = '',
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

  bool get isLoading => status == TransferInfoStatus.loading;
  bool get isSuccess => status == TransferInfoStatus.success;

  bool get puedeTransferir =>
      ubicacionDestinoValida &&
      ubicacionDestino != null &&
      cantidadValida &&
      cantidadATransferir > 0 &&
      status != TransferInfoStatus.loading;

  TransferInfoState copyWith({
    TransferInfoStatus? status,
    int? idAlmacen,
    int? idMove,
    int? idProducto,
    String? nombreProducto,
    int? idLote,
    String? nombreLote,
    int? idUbicacionOrigen,
    String? nombreUbicacionOrigen,
    double? cantidadDisponible,
    int? Function()? idPropietario,
    String? Function()? propietario,
    bool? Function()? manejoPropietario,
    UbicacionCatalogo? Function()? ubicacionDestino,
    bool? ubicacionDestinoValida,
    double? cantidadATransferir,
    bool? cantidadValida,
    String? observacion,
    String? dateStart,
    String? dateEnd,
    List<UbicacionCatalogo>? ubicacionesDestino,
    List<UbicacionCatalogo>? ubicacionesDestinoFiltradas,
    String? queryUbicacionDestino,
    String? Function()? almacenDestinoFiltro,
    List<String>? almacenesDisponibles,
    TransferenciaIndividualResult? Function()? resultadoTransferencia,
    String? Function()? mensajeError,
    Failure? Function()? failure,
  }) {
    return TransferInfoState(
      status: status ?? this.status,
      idAlmacen: idAlmacen ?? this.idAlmacen,
      idMove: idMove ?? this.idMove,
      idProducto: idProducto ?? this.idProducto,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      idLote: idLote ?? this.idLote,
      nombreLote: nombreLote ?? this.nombreLote,
      idUbicacionOrigen: idUbicacionOrigen ?? this.idUbicacionOrigen,
      nombreUbicacionOrigen:
          nombreUbicacionOrigen ?? this.nombreUbicacionOrigen,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      idPropietario:
          idPropietario != null ? idPropietario() : this.idPropietario,
      propietario: propietario != null ? propietario() : this.propietario,
      manejoPropietario: manejoPropietario != null
          ? manejoPropietario()
          : this.manejoPropietario,
      ubicacionDestino: ubicacionDestino != null
          ? ubicacionDestino()
          : this.ubicacionDestino,
      ubicacionDestinoValida:
          ubicacionDestinoValida ?? this.ubicacionDestinoValida,
      cantidadATransferir: cantidadATransferir ?? this.cantidadATransferir,
      cantidadValida: cantidadValida ?? this.cantidadValida,
      observacion: observacion ?? this.observacion,
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
        idMove,
        idProducto,
        nombreProducto,
        idLote,
        nombreLote,
        idUbicacionOrigen,
        nombreUbicacionOrigen,
        cantidadDisponible,
        idPropietario,
        propietario,
        manejoPropietario,
        ubicacionDestino,
        ubicacionDestinoValida,
        cantidadATransferir,
        cantidadValida,
        observacion,
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
