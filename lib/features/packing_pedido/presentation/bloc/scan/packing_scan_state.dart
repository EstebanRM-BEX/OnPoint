part of 'packing_scan_bloc.dart';

enum PasoScanPack { ubicacion, producto, cantidad, terminado }

enum ScanPackStatus { inicial, listo, procesando }

enum ResultadoScanPack { ninguno, separado, dividido }

class PackingScanState extends Equatable {
  final ScanPackStatus status;
  final ProductoPacking? producto;
  final PasoScanPack paso;

  /// Cantidad separada hasta ahora.
  final double cantidad;
  final bool editandoCantidad;

  /// Cantidad menor a la de la línea esperando que el operario elija entre
  /// aceptar con novedad o dividir.
  final double? cantidadEnDecision;

  final ResultadoScanPack resultado;

  /// Separado/dividido un producto con temperatura: falta registrarla.
  final bool requiereTemperatura;
  final TemperaturaIa? temperaturaIa;
  final String? imagenTemperatura;

  final ConfigPackingUsuario config;
  final List<BarcodeProductoPacking> barcodes;
  final List<Novedad> novedades;
  final PackingOperacion operacion;

  const PackingScanState({
    this.status = ScanPackStatus.inicial,
    this.producto,
    this.paso = PasoScanPack.ubicacion,
    this.cantidad = 0,
    this.editandoCantidad = false,
    this.cantidadEnDecision,
    this.resultado = ResultadoScanPack.ninguno,
    this.requiereTemperatura = false,
    this.temperaturaIa,
    this.imagenTemperatura,
    this.config = const ConfigPackingUsuario(),
    this.barcodes = const [],
    this.novedades = const [],
    this.operacion = PackingOperacion.ninguna,
  });

  bool get ocupado => status == ScanPackStatus.procesando;

  /// La línea quedó separada/dividida y no falta la temperatura: la UI
  /// puede volver al detalle.
  bool get finalizado =>
      resultado != ResultadoScanPack.ninguno && !requiereTemperatura;

  PackingScanState copyWith({
    ScanPackStatus? status,
    ProductoPacking? producto,
    PasoScanPack? paso,
    double? cantidad,
    bool? editandoCantidad,
    double? cantidadEnDecision,
    bool limpiarDecision = false,
    ResultadoScanPack? resultado,
    bool? requiereTemperatura,
    TemperaturaIa? temperaturaIa,
    String? imagenTemperatura,
    ConfigPackingUsuario? config,
    List<BarcodeProductoPacking>? barcodes,
    List<Novedad>? novedades,
    PackingOperacion? operacion,
  }) {
    return PackingScanState(
      status: status ?? this.status,
      producto: producto ?? this.producto,
      paso: paso ?? this.paso,
      cantidad: cantidad ?? this.cantidad,
      editandoCantidad: editandoCantidad ?? this.editandoCantidad,
      cantidadEnDecision: limpiarDecision
          ? null
          : (cantidadEnDecision ?? this.cantidadEnDecision),
      resultado: resultado ?? this.resultado,
      requiereTemperatura: requiereTemperatura ?? this.requiereTemperatura,
      temperaturaIa: temperaturaIa ?? this.temperaturaIa,
      imagenTemperatura: imagenTemperatura ?? this.imagenTemperatura,
      config: config ?? this.config,
      barcodes: barcodes ?? this.barcodes,
      novedades: novedades ?? this.novedades,
      operacion: operacion ?? this.operacion,
    );
  }

  @override
  List<Object?> get props => [
    status,
    producto,
    paso,
    cantidad,
    editandoCantidad,
    cantidadEnDecision,
    resultado,
    requiereTemperatura,
    temperaturaIa,
    imagenTemperatura,
    config,
    barcodes,
    novedades,
    operacion,
  ];
}
