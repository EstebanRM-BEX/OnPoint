import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/packing_operacion_listener.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/decision_parcial_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/temperatura_pack_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/cantidad_scan_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/producto_dropdown_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/scan_pack_header.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/ubicacion_dropdown_pack.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/scanner_location_widget.dart';
import 'package:wms_app/shared/widgets/scanner_product_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';

/// Escaneo de una línea ("CERTIFICACION") con el diseño del módulo
/// anterior: tarjeta de ubicación, tarjeta de producto y franja de cantidad.
/// Al terminar vuelve al detalle (o pide antes la temperatura).
class PackingScanPage extends StatelessWidget {
  final ProductoPacking producto;

  /// Viene de escanear el producto en "Por hacer": arranca en la cantidad.
  final bool productoEscaneado;

  const PackingScanPage({
    super.key,
    required this.producto,
    this.productoEscaneado = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PackingScanBloc>()
        ..add(ScanPackIniciado(producto, productoEscaneado: productoEscaneado)),
      child: const _ScanView(),
    );
  }
}

class _ScanView extends StatefulWidget {
  const _ScanView();

  @override
  State<_ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<_ScanView> {
  final _ubicacionController = TextEditingController();
  final _ubicacionFocus = FocusNode();
  final _productoController = TextEditingController();
  final _productoFocus = FocusNode();
  final _cantidadScanController = TextEditingController();
  final _cantidadScanFocus = FocusNode();
  final _cantidadController = TextEditingController();
  final _cantidadFocus = FocusNode();

  PackingScanBloc get _bloc => context.read<PackingScanBloc>();

  @override
  void initState() {
    super.initState();
    _enfocarPaso();
  }

  @override
  void dispose() {
    _ubicacionController.dispose();
    _ubicacionFocus.dispose();
    _productoController.dispose();
    _productoFocus.dispose();
    _cantidadScanController.dispose();
    _cantidadScanFocus.dispose();
    _cantidadController.dispose();
    _cantidadFocus.dispose();
    super.dispose();
  }

  /// Foco al campo de escaneo del paso actual. Solo al cambiar de paso o al
  /// cerrar la edición manual: nunca en cada rebuild (robaba el foco).
  void _enfocarPaso() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final s = _bloc.state;
    if (s.editandoCantidad) return;
    switch (s.paso) {
      case PasoScanPack.ubicacion:
        _ubicacionFocus.requestFocus();
      case PasoScanPack.producto:
        _productoFocus.requestFocus();
      case PasoScanPack.cantidad:
        _cantidadScanFocus.requestFocus();
      case PasoScanPack.terminado:
        break;
    }
  });

  void _leer(String valor) => _bloc.add(ScanPackLeido(valor));

  /// Vuelve al detalle cerrando antes cualquier diálogo que quede encima
  /// (p. ej. el de temperatura).
  void _cerrar() {
    final ruta = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    if (ruta != null && !ruta.isCurrent) {
      navigator.popUntil((r) => r == ruta);
    }
    navigator.pop(true);
  }

  void _aplicar() {
    final s = _bloc.state;
    if (s.editandoCantidad) {
      final v = double.tryParse(
        _cantidadController.text.trim().replaceAll(',', '.'),
      );
      if (v == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1000),
            content: const Text('Cantidad inválida'),
            backgroundColor: Colors.red[200],
          ),
        );
        return;
      }
      _bloc.add(CantidadPackAplicada(v));
    } else {
      _bloc.add(const CantidadPackAplicada());
    }
    FocusScope.of(context).unfocus();
  }

  Future<void> _verImagenProducto(int idProduct) async {
    final r = await getIt<GetUrlImagenProducto>()(
      GetUrlImagenProductoParams(productId: idProduct),
    );
    if (!mounted) return;
    r.fold(
      (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imagen no disponible'))),
      (url) => showImageDialog(context, url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<PackingScanBloc, PackingScanState>(
          listenWhen: (a, b) =>
              a.cantidadEnDecision == null && b.cantidadEnDecision != null,
          listener: (context, _) async {
            await showDecisionParcialDialog(context, _bloc);
            _enfocarPaso();
          },
        ),
        BlocListener<PackingScanBloc, PackingScanState>(
          listenWhen: (a, b) => !a.requiereTemperatura && b.requiereTemperatura,
          listener: (context, _) => showTemperaturaPackDialog(context, _bloc),
        ),
        BlocListener<PackingScanBloc, PackingScanState>(
          listenWhen: (a, b) =>
              a.paso != b.paso || a.editandoCantidad != b.editandoCantidad,
          listener: (_, s) {
            if (s.editandoCantidad) {
              _cantidadController.text = s.cantidad > 0
                  ? s.cantidad.toString()
                  : '';
            }
            _enfocarPaso();
          },
        ),
      ],
      child: PackingOperacionListener<PackingScanBloc, PackingScanState>(
        operacion: (s) => s.operacion,
        // Separar es local y rápido: el "Enviando producto..." se ve un
        // instante antes de cerrar.
        conDuracionMinima: const {'separar', 'dividir'},
        // Se cierra recién con el diálogo de carga cerrado y solo si todo
        // salió bien (separado/dividido y, si aplica, temperatura enviada).
        onExito: (context, state, _) {
          if (state.finalizado) _cerrar();
        },
        exitosSilenciosos: const {
          'separar',
          'imagenNovedad',
          'leerTemperatura',
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop(false);
          },
          child: BlocBuilder<PackingScanBloc, PackingScanState>(
            builder: (context, s) {
              final p = s.producto;
              if (p == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final ubicacionOk = s.paso.index > PasoScanPack.ubicacion.index;
              final productoOk = s.paso.index > PasoScanPack.producto.index;
              return Scaffold(
                backgroundColor: Colors.white,
                body: Column(
                  children: [
                    ScanPackHeader(
                      onBack: () => Navigator.of(context).pop(false),
                      onImprimir: () => ModalPrintersList.show(
                        context,
                        resIds: [p.idMove],
                        companyId: 1,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            LocationScannerWidget(
                              isLocationOk: s.errorEn != PasoScanPack.ubicacion,
                              locationIsOk: ubicacionOk,
                              productIsOk: productoOk,
                              quantityIsOk: productoOk,
                              locationDestIsOk: false,
                              currentLocationId: p.locationName,
                              onValidateLocation: _leer,
                              focusNode: _ubicacionFocus,
                              controller: _ubicacionController,
                              locationDropdown: UbicacionDropdownPack(
                                producto: p,
                                confirmada: ubicacionOk,
                                onConfirmar: s.config.locationPackManual
                                    ? () => _bloc.add(
                                        const UbicacionPackConfirmadaManual(),
                                      )
                                    : null,
                              ),
                            ),
                            ProductScannerWidget(
                              isProductOk: s.errorEn != PasoScanPack.producto,
                              productIsOk: productoOk,
                              locationIsOk: ubicacionOk,
                              quantityIsOk: productoOk,
                              locationDestIsOk: false,
                              currentProductId: p.productName,
                              barcode: p.barcode,
                              lotId: p.loteName,
                              origin: '',
                              expireDate: p.expireDate,
                              size: size,
                              onValidateProduct: _leer,
                              focusNode: _productoFocus,
                              controller: _productoController,
                              productDropdown: ProductoDropdownPack(
                                producto: p,
                                onConfirmar:
                                    s.config.manualProductSelectionPack &&
                                        s.paso == PasoScanPack.producto
                                    ? () => _bloc.add(
                                        const ProductoPackConfirmadoManual(),
                                      )
                                    : null,
                              ),
                              expiryWidget: ExpirationBadgeWidget(
                                expirationDate: p.expireDate,
                              ),
                              listOfBarcodes: s.barcodes,
                              onBarcodesDialogTap: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    DialogBarcodes(listOfBarcodes: s.barcodes),
                              ),
                              onViewImgProduct: () =>
                                  _verImagenProducto(p.idProduct),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CantidadScanCard(
                      activo: s.paso == PasoScanPack.cantidad,
                      conError: s.errorEn == PasoScanPack.cantidad,
                      cantidad: s.cantidad,
                      total: p.quantity,
                      unidades: p.unidades,
                      editando: s.editandoCantidad,
                      puedeEditar: s.config.manualQuantityPack,
                      ocupado: s.ocupado,
                      scanController: _cantidadScanController,
                      scanFocus: _cantidadScanFocus,
                      onEscaneo: _leer,
                      controller: _cantidadController,
                      focusNode: _cantidadFocus,
                      onAlternarEdicion: () =>
                          _bloc.add(const EdicionCantidadPackAlternada()),
                      onAplicar: _aplicar,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
