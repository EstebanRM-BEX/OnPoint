part of 'packing_scan_bloc.dart';

sealed class PackingScanEvent extends Equatable {
  const PackingScanEvent();

  @override
  List<Object?> get props => [];
}

class ScanPackIniciado extends PackingScanEvent {
  final ProductoPacking producto;

  /// El producto se escaneó desde "Por hacer": ubicación y producto quedan
  /// confirmados y se arranca en la cantidad.
  final bool productoEscaneado;
  const ScanPackIniciado(this.producto, {this.productoEscaneado = false});

  @override
  List<Object?> get props => [producto, productoEscaneado];
}

/// Lectura del escáner; se interpreta según el paso actual.
class ScanPackLeido extends PackingScanEvent {
  final String valor;
  const ScanPackLeido(this.valor);

  @override
  List<Object?> get props => [valor];
}

class UbicacionPackConfirmadaManual extends PackingScanEvent {
  const UbicacionPackConfirmadaManual();
}

class ProductoPackConfirmadoManual extends PackingScanEvent {
  const ProductoPackConfirmadoManual();
}

class EdicionCantidadPackAlternada extends PackingScanEvent {
  const EdicionCantidadPackAlternada();
}

/// "Aplicar cantidad". Sin [cantidad] usa lo escaneado hasta ahora.
class CantidadPackAplicada extends PackingScanEvent {
  final double? cantidad;
  const CantidadPackAplicada([this.cantidad]);

  @override
  List<Object?> get props => [cantidad];
}

/// Cantidad menor aceptada con novedad (el resto queda para backorder).
class SeparacionParcialPackAceptada extends PackingScanEvent {
  final String novedad;

  /// Foto de evidencia: se sube primero y, si falla, no se separa.
  final String? imagePath;
  const SeparacionParcialPackAceptada(this.novedad, {this.imagePath});

  @override
  List<Object?> get props => [novedad, imagePath];
}

/// Cantidad menor separada y el resto como línea nueva en "Por hacer".
class DivisionPackSolicitada extends PackingScanEvent {
  const DivisionPackSolicitada();
}

class DecisionParcialPackCancelada extends PackingScanEvent {
  const DecisionParcialPackCancelada();
}

class TemperaturaPackLeida extends PackingScanEvent {
  final String imagePath;
  const TemperaturaPackLeida(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

/// Sin [imagePath], temperatura digitada a mano.
class TemperaturaPackEnviada extends PackingScanEvent {
  final double temperatura;
  final String? imagePath;
  const TemperaturaPackEnviada(this.temperatura, {this.imagePath});

  @override
  List<Object?> get props => [temperatura, imagePath];
}

class ImagenNovedadPackEnviada extends PackingScanEvent {
  final String imagePath;
  const ImagenNovedadPackEnviada(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

/// Limpia el estado de error visual en las tarjetas (vuelven a su color normal).
class ErrorScanPackLimpiado extends PackingScanEvent {
  const ErrorScanPackLimpiado();
}
