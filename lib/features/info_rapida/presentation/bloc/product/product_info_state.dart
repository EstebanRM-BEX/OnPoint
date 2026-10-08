part of 'product_info_bloc.dart';

enum ProductInfoStatus { initial, ready, failure }

class ProductInfoState extends Equatable {
  final ProductInfoStatus status;
  final ProductoInfo? producto;
  final List<UbicacionProducto> ubicacionesFiltradas;
  final String queryFiltro;
  final String criterioOrden; // 'location', 'lote', 'date', 'entrada', 'cantidad'
  final bool ordenAscendente;
  final bool isEditing;
  final bool isSaving;
  final bool isLoadingImage;
  final String? imageUrl;
  final String? mensajeExito;
  final String? mensajeError;
  final Failure? failure;

  const ProductInfoState({
    this.status = ProductInfoStatus.initial,
    this.producto,
    this.ubicacionesFiltradas = const [],
    this.queryFiltro = '',
    this.criterioOrden = 'location',
    this.ordenAscendente = true,
    this.isEditing = false,
    this.isSaving = false,
    this.isLoadingImage = false,
    this.imageUrl,
    this.mensajeExito,
    this.mensajeError,
    this.failure,
  });

  bool get isReady => status == ProductInfoStatus.ready && producto != null;
  int get totalUbicaciones => producto?.ubicaciones.length ?? 0;
  double get totalStock =>
      producto?.ubicaciones.fold<double>(0.0, (acc, u) => acc + u.cantidad) ??
      (producto?.cantidadDisponible ?? 0.0);

  ProductInfoState copyWith({
    ProductInfoStatus? status,
    ProductoInfo? Function()? producto,
    List<UbicacionProducto>? ubicacionesFiltradas,
    String? queryFiltro,
    String? criterioOrden,
    bool? ordenAscendente,
    bool? isEditing,
    bool? isSaving,
    bool? isLoadingImage,
    String? Function()? imageUrl,
    String? Function()? mensajeExito,
    String? Function()? mensajeError,
    Failure? Function()? failure,
  }) {
    return ProductInfoState(
      status: status ?? this.status,
      producto: producto != null ? producto() : this.producto,
      ubicacionesFiltradas: ubicacionesFiltradas ?? this.ubicacionesFiltradas,
      queryFiltro: queryFiltro ?? this.queryFiltro,
      criterioOrden: criterioOrden ?? this.criterioOrden,
      ordenAscendente: ordenAscendente ?? this.ordenAscendente,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      isLoadingImage: isLoadingImage ?? this.isLoadingImage,
      imageUrl: imageUrl != null ? imageUrl() : this.imageUrl,
      mensajeExito: mensajeExito != null ? mensajeExito() : this.mensajeExito,
      mensajeError: mensajeError != null ? mensajeError() : this.mensajeError,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
        status,
        producto,
        ubicacionesFiltradas,
        queryFiltro,
        criterioOrden,
        ordenAscendente,
        isEditing,
        isSaving,
        isLoadingImage,
        imageUrl,
        mensajeExito,
        mensajeError,
        failure,
      ];
}
