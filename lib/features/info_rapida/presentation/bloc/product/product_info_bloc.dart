import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/actualizar_producto_usecase.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';

part 'product_info_event.dart';
part 'product_info_state.dart';

@injectable
class ProductInfoBloc extends Bloc<ProductInfoEvent, ProductInfoState> {
  final ActualizarProductoUseCase actualizarProducto;
  final GetUrlImagenProducto getUrlImagenProducto;

  ProductInfoBloc({
    required this.actualizarProducto,
    required this.getUrlImagenProducto,
  }) : super(const ProductInfoState()) {
    on<ProductInfoInicializado>(_onInicializado);
    on<BuscarUbicacionesProductoEvent>(
      _onBuscarUbicaciones,
      transformer: restartable(),
    );
    on<OrdenarUbicacionesProductoEvent>(_onOrdenarUbicaciones);
    on<ToggleModoEdicionProductoEvent>(_onToggleModoEdicion);
    on<CargarImagenProductoEvent>(
      _onCargarImagen,
      transformer: restartable(),
    );
    on<GuardarEdicionProductoEvent>(
      _onGuardarEdicion,
      transformer: droppable(),
    );
    on<LimpiarMensajeProductoEvent>(_onLimpiarMensaje);
  }

  void _onInicializado(
    ProductInfoInicializado event,
    Emitter<ProductInfoState> emit,
  ) {
    final ordenados = _filtrarYOrdenar(
      event.producto.ubicaciones,
      query: '',
      criterio: state.criterioOrden,
      ascendente: state.ordenAscendente,
    );

    emit(state.copyWith(
      status: ProductInfoStatus.ready,
      producto: () => event.producto,
      ubicacionesFiltradas: ordenados,
      queryFiltro: '',
      isEditing: false,
      isSaving: false,
      mensajeError: () => null,
      mensajeExito: () => null,
      failure: () => null,
    ));
  }

  void _onBuscarUbicaciones(
    BuscarUbicacionesProductoEvent event,
    Emitter<ProductInfoState> emit,
  ) {
    final producto = state.producto;
    if (producto == null) return;

    final filtrados = _filtrarYOrdenar(
      producto.ubicaciones,
      query: event.query,
      criterio: state.criterioOrden,
      ascendente: state.ordenAscendente,
    );

    emit(state.copyWith(
      ubicacionesFiltradas: filtrados,
      queryFiltro: event.query,
    ));
  }

  void _onOrdenarUbicaciones(
    OrdenarUbicacionesProductoEvent event,
    Emitter<ProductInfoState> emit,
  ) {
    final producto = state.producto;
    if (producto == null) return;

    final ordenados = _filtrarYOrdenar(
      producto.ubicaciones,
      query: state.queryFiltro,
      criterio: event.criterio,
      ascendente: event.ascendente,
    );

    emit(state.copyWith(
      ubicacionesFiltradas: ordenados,
      criterioOrden: event.criterio,
      ordenAscendente: event.ascendente,
    ));
  }

  void _onToggleModoEdicion(
    ToggleModoEdicionProductoEvent event,
    Emitter<ProductInfoState> emit,
  ) {
    emit(state.copyWith(
      isEditing: event.isEditing,
      mensajeError: () => null,
      mensajeExito: () => null,
    ));
  }

  Future<void> _onCargarImagen(
    CargarImagenProductoEvent event,
    Emitter<ProductInfoState> emit,
  ) async {
    final producto = state.producto;
    if (producto == null) return;

    emit(state.copyWith(isLoadingImage: true));

    final result = await getUrlImagenProducto(
      GetUrlImagenProductoParams(productId: producto.id),
    );

    result.match(
      (failure) {
        emit(state.copyWith(
          isLoadingImage: false,
          imageUrl: () => null,
        ));
      },
      (url) {
        emit(state.copyWith(
          isLoadingImage: false,
          imageUrl: () => url,
        ));
      },
    );
  }

  Future<void> _onGuardarEdicion(
    GuardarEdicionProductoEvent event,
    Emitter<ProductInfoState> emit,
  ) async {
    final producto = state.producto;
    if (producto == null) return;

    emit(state.copyWith(
      isSaving: true,
      mensajeError: () => null,
      mensajeExito: () => null,
      failure: () => null,
    ));

    final params = ActualizarProductoParams(
      productId: producto.id,
      name: event.nombre.trim(),
      barcode: event.barcode.trim(),
      defaultCode: event.defaultCode.trim(),
      listPrice: event.listPrice.trim(),
      weight: event.weight.trim(),
      volume: event.volume.trim(),
    );

    final result = await actualizarProducto(params);

    result.match(
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          mensajeError: () => failure.message,
          failure: () => failure,
        ));
      },
      (productoActualizado) {
        final nuevasUbicaciones = _filtrarYOrdenar(
          productoActualizado.ubicaciones,
          query: state.queryFiltro,
          criterio: state.criterioOrden,
          ascendente: state.ordenAscendente,
        );

        emit(state.copyWith(
          isSaving: false,
          isEditing: false,
          producto: () => productoActualizado,
          ubicacionesFiltradas: nuevasUbicaciones,
          mensajeExito: () => 'Producto actualizado exitosamente',
          mensajeError: () => null,
          failure: () => null,
        ));
      },
    );
  }

  void _onLimpiarMensaje(
    LimpiarMensajeProductoEvent event,
    Emitter<ProductInfoState> emit,
  ) {
    emit(state.copyWith(
      mensajeExito: () => null,
      mensajeError: () => null,
      failure: () => null,
    ));
  }

  List<UbicacionProducto> _filtrarYOrdenar(
    List<UbicacionProducto> items, {
    required String query,
    required String criterio,
    required bool ascendente,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    var filtrados = items;
    if (cleanQuery.isNotEmpty) {
      filtrados = items.where((u) {
        final matchesNombre = u.ubicacion.toLowerCase().contains(cleanQuery);
        final matchesBarcode = u.codigoBarras.toLowerCase().contains(cleanQuery);
        final matchesLote = (u.lote ?? '').toLowerCase().contains(cleanQuery);
        return matchesNombre || matchesBarcode || matchesLote;
      }).toList();
    }

    final ordenados = List<UbicacionProducto>.from(filtrados);
    ordenados.sort((a, b) {
      int comparison = 0;
      switch (criterio) {
        case 'location':
          comparison = a.ubicacion.toLowerCase().compareTo(b.ubicacion.toLowerCase());
        case 'lote':
          comparison = (a.lote ?? '').toLowerCase().compareTo((b.lote ?? '').toLowerCase());
        case 'date': // fecha de caducidad
          comparison =
              (a.fechaCaducidad ?? '').compareTo(b.fechaCaducidad ?? '');
        case 'entrada':
          comparison = (a.fechaEntrada ?? '').compareTo(b.fechaEntrada ?? '');
        case 'cantidad':
          comparison = a.cantidad.compareTo(b.cantidad);
        default:
          comparison = a.ubicacion.toLowerCase().compareTo(b.ubicacion.toLowerCase());
      }
      return ascendente ? comparison : -comparison;
    });

    return ordenados;
  }
}
