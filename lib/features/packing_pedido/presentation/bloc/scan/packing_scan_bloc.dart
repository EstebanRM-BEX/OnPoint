import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/actualizar_cantidad_separada_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/dividir_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/enviar_imagen_novedad_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/enviar_temperatura_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_barcodes_producto_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_config_packing_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_novedades_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/leer_temperatura_ia_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/marcar_producto_ok_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/marcar_ubicacion_ok_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/separar_producto_usecase.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

part 'packing_scan_event.dart';
part 'packing_scan_state.dart';

/// Escaneo de una línea: ubicación → producto → cantidad, y luego separar
/// (completa o parcial con novedad) o dividir. Si el producto maneja
/// temperatura, al terminar queda pendiente registrarla.
@injectable
class PackingScanBloc extends Bloc<PackingScanEvent, PackingScanState> {
  final GetBarcodesProductoPackUseCase getBarcodes;
  final GetConfigPackingUseCase getConfig;
  final GetNovedadesPackUseCase getNovedades;
  final MarcarUbicacionOkUseCase marcarUbicacionOk;
  final MarcarProductoOkUseCase marcarProductoOk;
  final ActualizarCantidadSeparadaUseCase actualizarCantidad;
  final SepararProductoUseCase separarProducto;
  final DividirProductoUseCase dividirProducto;
  final LeerTemperaturaIaUseCase leerTemperatura;
  final EnviarTemperaturaPackUseCase enviarTemperatura;
  final EnviarImagenNovedadPackUseCase enviarImagenNovedad;

  PackingScanBloc(
    this.getBarcodes,
    this.getConfig,
    this.getNovedades,
    this.marcarUbicacionOk,
    this.marcarProductoOk,
    this.actualizarCantidad,
    this.separarProducto,
    this.dividirProducto,
    this.leerTemperatura,
    this.enviarTemperatura,
    this.enviarImagenNovedad,
  ) : super(const PackingScanState()) {
    on<ScanPackIniciado>(_onIniciado, transformer: restartable());
    // Los escaneos llegan en ráfaga desde el lector: en orden, uno a la vez.
    on<ScanPackLeido>(_onLeido, transformer: sequential());
    on<UbicacionPackConfirmadaManual>(
      _onUbicacionManual,
      transformer: droppable(),
    );
    on<ProductoPackConfirmadoManual>(
      _onProductoManual,
      transformer: droppable(),
    );
    on<EdicionCantidadPackAlternada>(_onEdicionAlternada);
    on<CantidadPackAplicada>(_onCantidadAplicada, transformer: droppable());
    on<SeparacionParcialPackAceptada>(
      _onParcialAceptada,
      transformer: droppable(),
    );
    on<DivisionPackSolicitada>(_onDivision, transformer: droppable());
    on<DecisionParcialPackCancelada>(_onDecisionCancelada);
    on<TemperaturaPackLeida>(_onTemperaturaLeida, transformer: droppable());
    on<TemperaturaPackEnviada>(_onTemperaturaEnviada, transformer: droppable());
    on<ImagenNovedadPackEnviada>(_onImagenNovedad, transformer: droppable());
  }

  // ── Inicio ────────────────────────────────────────────────────────────────

  Future<void> _onIniciado(
    ScanPackIniciado event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = event.producto;
    emit(
      PackingScanState(
        producto: p,
        paso: _pasoDe(p),
        cantidad: p.quantitySeparate,
        status: ScanPackStatus.listo,
      ),
    );

    final config = await getConfig(NoParams());
    final barcodes = await getBarcodes(
      GetBarcodesProductoPackParams(producto: p),
    );
    final novedades = await getNovedades(NoParams());
    emit(
      state.copyWith(
        config: config.getOrElse((_) => state.config),
        barcodes: barcodes.getOrElse((_) => const []),
        novedades: novedades.getOrElse((_) => const []),
      ),
    );

    if (event.productoEscaneado) {
      if (state.paso == PasoScanPack.ubicacion) {
        await _confirmarUbicacion(emit, state.producto!);
      }
      if (state.paso == PasoScanPack.producto) {
        await _confirmarProducto(emit, state.producto!);
      }
    }
  }

  static PasoScanPack _pasoDe(ProductoPacking p) {
    if (!p.isPorHacer) return PasoScanPack.terminado;
    if (!p.locationOk) return PasoScanPack.ubicacion;
    if (!p.productOk) return PasoScanPack.producto;
    return PasoScanPack.cantidad;
  }

  // ── Escaneo ───────────────────────────────────────────────────────────────

  Future<void> _onLeido(
    ScanPackLeido event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    final valor = event.valor.trim().toLowerCase();
    if (p == null || valor.isEmpty || state.ocupado) return;

    switch (state.paso) {
      case PasoScanPack.ubicacion:
        if (valor != p.barcodeLocation.toLowerCase()) {
          return _errorEscaneo(emit, 'Ubicación incorrecta');
        }
        await _confirmarUbicacion(emit, p);
      case PasoScanPack.producto:
        if (!_esDelProducto(valor, p)) {
          return _errorEscaneo(emit, 'Producto incorrecto');
        }
        await _confirmarProducto(emit, p);
      case PasoScanPack.cantidad:
        await _sumarEscaneo(emit, p, valor);
      case PasoScanPack.terminado:
        return;
    }
  }

  bool _esDelProducto(String valor, ProductoPacking p) =>
      valor == p.barcode.toLowerCase() ||
      state.barcodes.any((b) => b.barcode.toLowerCase() == valor);

  /// Producto escaneado en el paso de cantidad: +1 con su barcode, o la
  /// cantidad del empaque con un barcode de caja. Nunca pasa del total.
  Future<void> _sumarEscaneo(
    Emitter<PackingScanState> emit,
    ProductoPacking p,
    String valor,
  ) async {
    double? incremento;
    if (valor == p.barcode.toLowerCase()) {
      incremento = 1;
    } else {
      for (final b in state.barcodes) {
        if (b.barcode.toLowerCase() == valor) {
          incremento = b.cantidad;
          break;
        }
      }
    }
    if (incremento == null) {
      return _errorEscaneo(emit, 'Producto incorrecto');
    }
    if (!PackingRules.puedeSumarEscaneo(
      p,
      actual: state.cantidad,
      incremento: incremento,
    )) {
      return _errorEscaneo(
        emit,
        'La cantidad no puede ser mayor a ${_fmt(p.quantity)}',
      );
    }

    final total = state.cantidad + incremento;
    final r = await actualizarCantidad(
      ActualizarCantidadSeparadaParams(producto: p, cantidad: total),
    );
    await r.fold(
      (f) async =>
          emit(state.copyWith(operacion: state.operacion.fallo('escaneo', f))),
      (actualizado) async {
        emit(state.copyWith(producto: actualizado, cantidad: total));
        // Completa por escaneo: se separa sola.
        if (PackingRules.evaluarCantidad(actualizado, total) ==
            ValidacionCantidad.completa) {
          await _separar(emit, actualizado, total, null);
        }
      },
    );
  }

  void _errorEscaneo(Emitter<PackingScanState> emit, String mensaje) => emit(
    state.copyWith(operacion: state.operacion.error('escaneo', mensaje)),
  );

  Future<void> _confirmarUbicacion(
    Emitter<PackingScanState> emit,
    ProductoPacking p,
  ) async {
    final r = await marcarUbicacionOk(MarcarUbicacionOkParams(producto: p));
    r.fold(
      (f) => emit(
        state.copyWith(operacion: state.operacion.fallo('ubicacion', f)),
      ),
      (act) => emit(state.copyWith(producto: act, paso: PasoScanPack.producto)),
    );
  }

  Future<void> _confirmarProducto(
    Emitter<PackingScanState> emit,
    ProductoPacking p,
  ) async {
    final r = await marcarProductoOk(MarcarProductoOkParams(producto: p));
    r.fold(
      (f) =>
          emit(state.copyWith(operacion: state.operacion.fallo('producto', f))),
      (act) => emit(
        state.copyWith(producto: act, paso: PasoScanPack.cantidad, cantidad: 0),
      ),
    );
  }

  Future<void> _onUbicacionManual(
    UbicacionPackConfirmadaManual event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    if (p == null || state.paso != PasoScanPack.ubicacion) return;
    if (!state.config.locationPackManual) {
      return _errorEscaneo(
        emit,
        'No tiene permiso para confirmar la ubicación a mano',
      );
    }
    await _confirmarUbicacion(emit, p);
  }

  Future<void> _onProductoManual(
    ProductoPackConfirmadoManual event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    if (p == null || state.paso != PasoScanPack.producto) return;
    if (!state.config.manualProductSelectionPack) {
      return _errorEscaneo(
        emit,
        'No tiene permiso para confirmar el producto a mano',
      );
    }
    await _confirmarProducto(emit, p);
  }

  // ── Cantidad manual ───────────────────────────────────────────────────────

  void _onEdicionAlternada(
    EdicionCantidadPackAlternada event,
    Emitter<PackingScanState> emit,
  ) {
    if (state.paso != PasoScanPack.cantidad) return;
    if (!state.config.manualQuantityPack) {
      return _errorEscaneo(emit, 'No tiene permiso para digitar la cantidad');
    }
    emit(state.copyWith(editandoCantidad: !state.editandoCantidad));
  }

  /// "Aplicar cantidad": completa → separa; parcial → pide decisión
  /// (aceptar con novedad o dividir); cero o de más → error.
  Future<void> _onCantidadAplicada(
    CantidadPackAplicada event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    if (p == null || state.paso != PasoScanPack.cantidad || state.ocupado) {
      return;
    }
    final cantidad = event.cantidad ?? state.cantidad;

    switch (PackingRules.evaluarCantidad(p, cantidad)) {
      case ValidacionCantidad.invalida:
        return _errorEscaneo(emit, 'La cantidad debe ser mayor a cero');
      case ValidacionCantidad.excede:
        return _errorEscaneo(
          emit,
          'La cantidad no puede ser mayor a ${_fmt(p.quantity)}',
        );
      case ValidacionCantidad.completa:
        await _separar(emit, p, cantidad, null);
      case ValidacionCantidad.parcial:
        emit(
          state.copyWith(cantidadEnDecision: cantidad, editandoCantidad: false),
        );
    }
  }

  void _onDecisionCancelada(
    DecisionParcialPackCancelada event,
    Emitter<PackingScanState> emit,
  ) => emit(state.copyWith(limpiarDecision: true));

  Future<void> _onParcialAceptada(
    SeparacionParcialPackAceptada event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    final cantidad = state.cantidadEnDecision;
    if (p == null || cantidad == null) return;
    await _separar(emit, p, cantidad, event.novedad);
  }

  Future<void> _onDivision(
    DivisionPackSolicitada event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    final cantidad = state.cantidadEnDecision;
    if (p == null || cantidad == null) return;

    emit(
      state.copyWith(
        status: ScanPackStatus.procesando,
        limpiarDecision: true,
        operacion: state.operacion.procesar(
          'dividir',
          'Dividiendo producto...',
        ),
      ),
    );
    final r = await dividirProducto(
      DividirProductoParams(producto: p, cantidad: cantidad),
    );
    r.fold(
      (f) => emit(
        state.copyWith(
          status: ScanPackStatus.listo,
          operacion: state.operacion.fallo('dividir', f),
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: ScanPackStatus.listo,
          paso: PasoScanPack.terminado,
          resultado: ResultadoScanPack.dividido,
          requiereTemperatura: p.manejaTemperatura,
          operacion: state.operacion.exito(
            'dividir',
            'Se separaron ${_fmt(cantidad)}; quedan '
                '${_fmt(p.quantity - cantidad)} por hacer',
          ),
        ),
      ),
    );
  }

  Future<void> _separar(
    Emitter<PackingScanState> emit,
    ProductoPacking p,
    double cantidad,
    String? novedad,
  ) async {
    emit(
      state.copyWith(
        status: ScanPackStatus.procesando,
        limpiarDecision: true,
        editandoCantidad: false,
        operacion: state.operacion.procesar('separar', 'Separando producto...'),
      ),
    );
    final r = await separarProducto(
      SepararProductoParams(producto: p, cantidad: cantidad, novedad: novedad),
    );
    r.fold(
      (f) => emit(
        state.copyWith(
          status: ScanPackStatus.listo,
          operacion: state.operacion.fallo('separar', f),
        ),
      ),
      (act) => emit(
        state.copyWith(
          status: ScanPackStatus.listo,
          producto: act,
          cantidad: cantidad,
          paso: PasoScanPack.terminado,
          resultado: ResultadoScanPack.separado,
          requiereTemperatura: act.manejaTemperatura,
          operacion: state.operacion.exito('separar'),
        ),
      ),
    );
  }

  // ── Temperatura y novedad ─────────────────────────────────────────────────

  Future<void> _onTemperaturaLeida(
    TemperaturaPackLeida event,
    Emitter<PackingScanState> emit,
  ) async {
    emit(
      state.copyWith(
        operacion: state.operacion.procesar(
          'leerTemperatura',
          'Leyendo temperatura...',
        ),
      ),
    );
    final r = await leerTemperatura(
      LeerTemperaturaIaParams(imagePath: event.imagePath),
    );
    r.fold(
      (f) => emit(
        state.copyWith(operacion: state.operacion.fallo('leerTemperatura', f)),
      ),
      (t) => emit(
        state.copyWith(
          temperaturaIa: t,
          imagenTemperatura: event.imagePath,
          operacion: state.operacion.exito('leerTemperatura'),
        ),
      ),
    );
  }

  Future<void> _onTemperaturaEnviada(
    TemperaturaPackEnviada event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    if (p == null) return;
    emit(
      state.copyWith(
        operacion: state.operacion.procesar(
          'temperatura',
          'Enviando temperatura...',
        ),
      ),
    );
    final r = await enviarTemperatura(
      EnviarTemperaturaPackParams(
        producto: p,
        temperatura: event.temperatura,
        imagePath: event.imagePath,
      ),
    );
    r.fold(
      (f) => emit(
        state.copyWith(operacion: state.operacion.fallo('temperatura', f)),
      ),
      (act) => emit(
        state.copyWith(
          producto: act,
          requiereTemperatura: false,
          operacion: state.operacion.exito(
            'temperatura',
            'Temperatura enviada correctamente',
          ),
        ),
      ),
    );
  }

  Future<void> _onImagenNovedad(
    ImagenNovedadPackEnviada event,
    Emitter<PackingScanState> emit,
  ) async {
    final p = state.producto;
    if (p == null) return;
    emit(
      state.copyWith(
        operacion: state.operacion.procesar(
          'imagenNovedad',
          'Enviando imagen...',
        ),
      ),
    );
    final r = await enviarImagenNovedad(
      EnviarImagenNovedadPackParams(producto: p, imagePath: event.imagePath),
    );
    r.fold(
      (f) => emit(
        state.copyWith(operacion: state.operacion.fallo('imagenNovedad', f)),
      ),
      (act) => emit(
        state.copyWith(
          producto: act,
          operacion: state.operacion.exito('imagenNovedad'),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
