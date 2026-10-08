import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/product/product_info_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/scan/info_rapida_scan_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/transfer_info_page.dart';
import 'package:wms_app/features/info_rapida/presentation/utils/info_rapida_format.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/location_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/product_detail_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_consulta_listener.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_snackbar.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/ubicaciones_sort_menu.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/dialogs/product_image_dialog.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Detalle de un producto: datos editables, imagen y ubicaciones donde está,
/// desde las que se inicia la transferencia individual.
class ProductInfoPage extends StatelessWidget {
  final ProductoInfo producto;
  final ConfigInfoRapidaUsuario config;

  const ProductInfoPage({
    super.key,
    required this.producto,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ProductInfoBloc>()..add(ProductInfoInicializado(producto)),
        ),
        // Solo para refrescar el producto tras una transferencia.
        BlocProvider(create: (_) => getIt<InfoRapidaScanBloc>()),
      ],
      child: _ProductInfoView(producto: producto, config: config),
    );
  }
}

class _ProductInfoView extends StatefulWidget {
  final ProductoInfo producto;
  final ConfigInfoRapidaUsuario config;

  const _ProductInfoView({required this.producto, required this.config});

  @override
  State<_ProductInfoView> createState() => _ProductInfoViewState();
}

class _ProductInfoViewState extends State<_ProductInfoView>
    with LoadingDialogMixin {
  final _nameController = TextEditingController();
  final _referenceController = TextEditingController();
  final _priceController = TextEditingController();
  final _pesoController = TextEditingController();
  final _volumenController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _searchController = TextEditingController();
  // El FocusNode del buscador vive en el State (en el legacy vivía en el
  // bloc porque la pantalla era StatelessWidget).
  final _searchFocusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _cargarCampos(widget.producto);
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _referenceController,
      _priceController,
      _pesoController,
      _volumenController,
      _barcodeController,
      _searchController,
    ]) {
      c.dispose();
    }
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _cargarCampos(ProductoInfo p) {
    String num(double? v) => v == null ? '' : formatCantidad(v);
    _nameController.text = p.nombre;
    _referenceController.text = p.referencia;
    _priceController.text = num(p.precio);
    _pesoController.text = num(p.peso);
    _volumenController.text = num(p.volumen);
    _barcodeController.text = p.codigoBarras;
  }

  void _toggleEdicion(ProductInfoState state) {
    final editar = !state.isEditing;
    if (!editar && state.producto != null) _cargarCampos(state.producto!);
    context.read<ProductInfoBloc>().add(ToggleModoEdicionProductoEvent(editar));
  }

  void _guardar() {
    final campos = [
      _nameController,
      _barcodeController,
      _referenceController,
      _priceController,
      _pesoController,
      _volumenController,
    ];
    if (campos.any((c) => c.text.isEmpty)) {
      InfoRapidaSnackbar.error('Por favor, complete todos los campos');
      return;
    }
    context.read<ProductInfoBloc>().add(
      GuardarEdicionProductoEvent(
        nombre: _nameController.text,
        barcode: _barcodeController.text,
        defaultCode: _referenceController.text,
        listPrice: _priceController.text,
        weight: _pesoController.text,
        volume: _volumenController.text,
      ),
    );
  }

  Future<void> _transferir(ProductoInfo producto, UbicacionProducto u) async {
    final resultado = await Navigator.of(context)
        .push<TransferenciaIndividualResult>(
          MaterialPageRoute(
            builder: (_) => TransferInfoPage(producto: producto, ubicacion: u),
          ),
        );
    if (!mounted || resultado == null) return;
    // Refresca existencias del producto sin ensuciar "Últimas consultas".
    context.read<InfoRapidaScanBloc>().add(
      ConsultarPorIdEvent(
        id: producto.id,
        isProduct: true,
        guardarEnRecientes: false,
      ),
    );
  }

  void _onProductState(BuildContext context, ProductInfoState state) {
    if (state.isSaving) {
      showLoadingDialog('Actualizando producto...');
    } else {
      hideLoadingDialog();
    }

    final bloc = context.read<ProductInfoBloc>();
    if (state.mensajeExito != null) {
      InfoRapidaSnackbar.success(state.mensajeExito!);
      bloc.add(const LimpiarMensajeProductoEvent());
    } else if (state.mensajeError != null) {
      InfoRapidaSnackbar.error(state.mensajeError!);
      bloc.add(const LimpiarMensajeProductoEvent());
    }
  }

  void _onImagenState(BuildContext context, ProductInfoState state) {
    if (state.isLoadingImage) {
      showLoadingDialog('Cargando imagen...');
      return;
    }
    hideLoadingDialog();
    final url = state.imageUrl;
    if (url == null || url.isEmpty) {
      showScrollableErrorDialog('No se pudo obtener la imagen del producto');
    } else {
      showProductImageDialog(context, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfoRapidaConsultaListener(
      config: widget.config,
      onResultado: (info) {
        if (info is ProductoInfo) {
          context.read<ProductInfoBloc>().add(ProductInfoInicializado(info));
        }
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProductInfoBloc, ProductInfoState>(
            listenWhen: (previous, current) =>
                previous.producto != current.producto &&
                current.producto != null,
            listener: (_, state) => _cargarCampos(state.producto!),
          ),
          BlocListener<ProductInfoBloc, ProductInfoState>(
            listenWhen: (previous, current) =>
                previous.isSaving != current.isSaving ||
                previous.mensajeExito != current.mensajeExito ||
                previous.mensajeError != current.mensajeError,
            listener: _onProductState,
          ),
          BlocListener<ProductInfoBloc, ProductInfoState>(
            listenWhen: (previous, current) =>
                previous.isLoadingImage != current.isLoadingImage,
            listener: _onImagenState,
          ),
        ],
        child: BlocBuilder<ProductInfoBloc, ProductInfoState>(
          builder: (context, state) => _buildScaffold(context, state),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, ProductInfoState state) {
    final bloc = context.read<ProductInfoBloc>();
    final producto = state.producto ?? widget.producto;
    final ubicaciones = state.ubicacionesFiltradas;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            InfoRapidaHeader(
              onBack: () => Navigator.pop(context),
              trailing: widget.config.updateItemInventory
                  ? HeaderCircleButton(
                      icon: state.isEditing ? Icons.close : Icons.edit,
                      onTap: () => _toggleEdicion(state),
                    )
                  : null,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.45,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                child: ProductDetailCard(
                  product: producto,
                  isEditMode: state.isEditing,
                  isExpanded: _isExpanded,
                  nameController: _nameController,
                  referenceController: _referenceController,
                  priceController: _priceController,
                  pesoController: _pesoController,
                  volumenController: _volumenController,
                  barcodeController: _barcodeController,
                  onViewImage: () =>
                      bloc.add(const CargarImagenProductoEvent()),
                  onToggleExpanded: () =>
                      setState(() => _isExpanded = !_isExpanded),
                  onSubmitUpdate: _guardar,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Ubicaciones',
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColorApp.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${ubicaciones.length} activas',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColorApp,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Ordenar',
                    style: TextStyle(
                      color: primaryColorApp,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  UbicacionesSortMenu(
                    onSelected: (criterio, ascendente) => bloc.add(
                      OrdenarUbicacionesProductoEvent(
                        criterio: criterio,
                        ascendente: ascendente,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: DynamicSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Buscar ubicación (ej. CVC, 50-P01)...',
                persistentKeyboard: true,
                onSearchChanged: (value) =>
                    bloc.add(BuscarUbicacionesProductoEvent(value)),
                onSearchCleared: () {
                  _searchController.clear();
                  bloc.add(const BuscarUbicacionesProductoEvent(''));
                },
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  cacheExtent: 500,
                  itemCount: ubicaciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final ubicacion = ubicaciones[index];
                    return LocationCard(
                      ubicacion: ubicacion,
                      onTransfer: () => _transferir(producto, ubicacion),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
