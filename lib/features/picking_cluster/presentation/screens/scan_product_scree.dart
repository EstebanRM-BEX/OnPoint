// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/lote_producto.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/pedido_dropdown_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/popunButton_widget.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/shared/widgets/lote_scanner_widget.dart';
import 'package:wms_app/shared/widgets/scanner_location_widget.dart';
import 'package:wms_app/shared/widgets/scanner_dynamic_widget.dart';
import 'package:wms_app/shared/widgets/scanner_product_widget.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/dropdowbutton_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/lote_producto/lote_producto_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/progressIndicatos_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/quantity/scanner_quantity_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';

import 'picking_cluster/widgets/dialog_picking_incompleted_widget.dart';
import 'picking_cluster/widgets/location_dropdown_widget.dart';
import 'picking_cluster/widgets/product_dropdown_widget.dart';

class ScanProductCluster extends StatefulWidget {
  const ScanProductCluster({super.key});

  @override
  State<ScanProductCluster> createState() => _ScanProductClusterState();
}

class _ScanProductClusterState extends State<ScanProductCluster>
    with WidgetsBindingObserver {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  //focus
  FocusNode focusNode1 = FocusNode(); // ubicacion  de origen
  FocusNode focusNode2 = FocusNode(); // producto
  FocusNode focusNode3 = FocusNode(); // cantidad
  FocusNode focusNode4 = FocusNode(); // cantidad por pda
  FocusNode focusNode6 = FocusNode(); // lote
  FocusNode focusNode7 = FocusNode(); //Submuelle

  //controller
  final TextEditingController _controllerLocation = TextEditingController();
  final TextEditingController _controllerProduct = TextEditingController();
  final TextEditingController _controllerLote = TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final TextEditingController _controllerCantidad = TextEditingController();
  final TextEditingController _controllerPedido = TextEditingController();

  String? selectedMuelle;

  @override
  void initState() {
    super.initState();
    // Añadimos el observer para escuchar el ciclo de vida de la app.
    WidgetsBinding.instance.addObserver(this);
    validate();
  }

  void validate() {
    // Esperamos a que el widget termine de construirse antes de ejecutar navegación o diálogos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Es buena práctica verificar si el widget sigue montado
      if (!mounted) return;

      final bloc = context.read<ClusterPickingBloc>();

      // validamos si todos los productos fueron procesados
      final products = bloc.filteredProducts
          .where((element) => element.isSeparate == 0)
          .toList();

      if (products.isEmpty) {
        // También validamos que currentProduct no sea null antes de usar !
        if (bloc.currentProduct != null) {
          validatePicking(
            bloc,
            context,
            bloc.currentProduct!,
          );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDependencies();
  }

  void _unfocusAll({required FocusNode except}) {
    for (final node in [
      focusNode1,
      focusNode2,
      focusNode3,
      focusNode4,
      focusNode6,
      focusNode7,
    ]) {
      if (node != except) node.unfocus();
    }
  }

  void _requestOnly(FocusNode node, String tag) {
    debugPrint("🎯 Enfocando: $tag");
    FocusScope.of(context).requestFocus(node);
    _unfocusAll(except: node);
  }

  void _handleDependencies() {
    final bloc = context.read<ClusterPickingBloc>();

    final hasLote = bloc.currentProduct?.productTracking == "lot";

    if (!bloc.locationIsOk &&
        !bloc.productIsOk &&
        !bloc.quantityIsOk &&
        !bloc.locationDestIsOk) {
      _requestOnly(focusNode1, 'location');
      return;
    }

    if (bloc.locationIsOk &&
        !bloc.productIsOk &&
        !bloc.quantityIsOk &&
        !bloc.locationDestIsOk) {
      _requestOnly(focusNode2, 'product');
      return;
    }

    if (hasLote) {
      if (bloc.locationIsOk &&
          bloc.productIsOk &&
          !bloc.pedidoValidateIsOk &&
          !bloc.loteIsOk &&
          !bloc.quantityIsOk &&
          !bloc.viewQuantity) {
        _requestOnly(focusNode6, 'lote');
        return;
      }
    }

    if (bloc.locationIsOk &&
        bloc.productIsOk &&
        !bloc.pedidoValidateIsOk &&
        !bloc.quantityIsOk &&
        !bloc.locationsDestIsok &&
        !bloc.viewQuantity) {
      _requestOnly(focusNode7, 'pedido');
      return;
    }
    if (bloc.locationIsOk &&
        bloc.productIsOk &&
        bloc.quantityIsOk &&
        bloc.pedidoValidateIsOk &&
        !bloc.locationsDestIsok &&
        !bloc.viewQuantity) {
      _requestOnly(focusNode3, 'quantity');
      return;
    }
  }

  @override
  void dispose() {
    focusNode1.dispose(); //
    focusNode2.dispose(); //
    focusNode3.dispose(); //
    focusNode4.dispose(); //
    focusNode6.dispose(); //
    focusNode7.dispose(); //
    super.dispose();
  }

  void validateLocation(String value) async {
    final bloc = context.read<ClusterPickingBloc>();
    final scan = value.trim().toLowerCase();
    final product = bloc.currentProduct;

    debugPrint("scan location: $scan");

    _controllerLocation.clear();

    if (scan == product?.barcodeLocation?.toLowerCase()) {
      bloc.add(ValidateFieldsEvent(field: "location", isOk: true));
      bloc.add(ChangeLocationIsOkEvent(product?.idProduct ?? 0,
          bloc.currentBatch?.id ?? 0, product?.idMove ?? 0, 'cluster'));
      bloc.oldLocation = product?.locationId.toString() ?? '';
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      bloc.add(ValidateFieldsEvent(field: "location", isOk: false));
    }
    Future.microtask(() => focusNode1.requestFocus());
  }

  void validateProduct(String value) async {
    if (!mounted) return;

    final bloc = context.read<ClusterPickingBloc>();
    final scan = value.trim().toLowerCase();
    final product = bloc.currentProduct;

    debugPrint('scan product: $scan');
    _controllerProduct.clear();

    if (scan == product?.barcode?.toLowerCase()) {
      bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
      bloc.add(ChangeProductIsOkEvent(true, product?.idProduct ?? 0,
          bloc.currentBatch?.id ?? 0, 0, product?.idMove ?? 0, 'cluster'));
    } else {
      final isOk = await validateScannedBarcode(scan, product!, bloc, true);
      if (!isOk) {
        _vibrationService.vibrate();
        _audioService.playErrorSound();
        bloc.add(ValidateFieldsEvent(field: "product", isOk: false));
      }
    }

    Future.microtask(() => focusNode2.requestFocus());
  }

  Future<bool> validateScannedBarcode(
      String scannedBarcode,
      BatchProduct currentProduct,
      ClusterPickingBloc batchBloc,
      bool isProduct) async {
    // Buscar el barcode que coincida con el valor escaneado
    BatchBarcode? matchedBarcode = context
        .read<ClusterPickingBloc>()
        .listOfBarcodes
        .firstWhere(
            (barcode) => barcode.barcode?.toLowerCase() == scannedBarcode,
            orElse: () => const BatchBarcode());
    if (matchedBarcode.barcode != null) {
      if (isProduct) {
        batchBloc.add(ValidateFieldsEvent(field: "product", isOk: true));

        batchBloc.add(ChangeQuantitySeparate(0, currentProduct.idProduct ?? 0,
            currentProduct.idMove ?? 0, 'cluster'));

        batchBloc.add(ChangeProductIsOkEvent(
            true,
            currentProduct.idProduct ?? 0,
            batchBloc.currentBatch?.id ?? 0,
            0,
            currentProduct.idMove ?? 0,
            'cluster'));

        batchBloc.add(ChangeIsOkQuantity(
            true,
            currentProduct.idProduct ?? 0,
            batchBloc.currentBatch?.id ?? 0,
            currentProduct.idMove ?? 0,
            'cluster'));

        return true;
      } else {
        //valisamos si la suma de la cantidad del paquete es correcta con lo que se pide
        if (matchedBarcode.cantidad + batchBloc.quantitySelected >
            currentProduct.quantity!) {
          _vibrationService.vibrate();
          _audioService.playErrorSound();
          return false;
        }

        batchBloc.add(AddQuantitySeparate(
            currentProduct.idProduct ?? 0,
            currentProduct.idMove ?? 0,
            matchedBarcode.cantidad,
            false,
            'cluster'));
      }
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      return false;
    }
    _vibrationService.vibrate();
    _audioService.playErrorSound();
    return false;
  }

  void validateLote(String value) {
    final bloc = context.read<ClusterPickingBloc>();
    final scan = value.trim().toLowerCase();
    debugPrint('scan lote: $scan');
    _controllerLote.clear();
    //tengo una lista de lotes el cual quiero validar si el scan es igual a alguno de los lotes
    LoteProducto? matchedLote = bloc.listLotesProduct.firstWhere(
        (lotes) => lotes.name?.toLowerCase() == scan.trim(),
        orElse: () =>
            LoteProducto() // Si no se encuentra ningún match, devuelve null
        );
    if (matchedLote.name != null) {
      debugPrint('lote encontrado: ${matchedLote.name}');

      if (matchedLote.id == bloc.currentProduct?.loteId) {
        Navigator.pop(context); // Cierra modal
        bloc.add(ValidateFieldsEvent(field: "lote", isOk: true));
        bloc.add(SelectLoteEventCluster(matchedLote));
      } else {
        //mostrar dialgo de confirmacion para seleccionar otro lote
        showDialog(
          context: context,
          builder: (context) => DialogValidateLot(
            bloc: bloc,
            selectedLote: matchedLote,
            onLoteSelectedWithValidate: (lote) {
              bloc.add(SelectLoteEventCluster(lote));
            },
          ),
        );
      }
      Future.microtask(() => focusNode6.requestFocus());
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      debugPrint('lote no encontrado');
      bloc.add(ValidateFieldsEvent(field: "lote", isOk: false));
      Future.microtask(() => focusNode6.requestFocus());
    }
  }

  void validateQuantity(String value) async {
    if (!mounted) return;

    debugPrint("Validando cantidad: $value");
    final bloc = context.read<ClusterPickingBloc>();
    final scan = value.trim().toLowerCase();
    final product = bloc.currentProduct;

    _controllerCantidad.clear();

    if (bloc.quantitySelected == product?.quantity) return;

    if (scan == product?.barcode?.toLowerCase()) {
      bloc.add(AddQuantitySeparate(
        product?.idProduct ?? 0,
        product?.idMove ?? 0,
        1,
        false,
        'cluster',
      ));
    } else {
      await validateScannedBarcode(scan, product!, bloc, false);
    }

    Future.microtask(() => focusNode3.requestFocus());
  }

  void validatePedido(String value) async {
    if (!mounted) return;

    final bloc = context.read<ClusterPickingBloc>();
    final scan = value.trim().toLowerCase();
    final product = bloc.currentProduct;

    _controllerPedido.clear();

    final currentPedido = product?.origin?.trim().toLowerCase();

    if (scan == currentPedido) {
      bloc.add(ValidatePedidoEvent(product?.idProduct ?? 0,
          bloc.currentBatch?.id ?? 0, product?.idMove ?? 0, 'cluster'));
      bloc.add(ValidateFieldsEvent(field: "pedido", isOk: true));
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();

      bloc.add(ValidateFieldsEvent(field: "pedido", isOk: false));
    }

    Future.microtask(() => focusNode7.requestFocus());
  }

  void validatePicking(ClusterPickingBloc batchBloc, BuildContext context,
      BatchProduct currentProduct) {
    // -------------------------------------------------------------
    // ⚡️ CAMBIO PRINCIPAL AQUÍ
    // Usamos la función booleana que valida producto por producto
    // en lugar de confiar en el porcentaje global.
    // -------------------------------------------------------------

    final bool estaCompleto = batchBloc.isPickingCompleto();

    // if (unidadesSeparadas == "100.0" || unidadesSeparadas >= 100.0) <-- VIEJO
    if (estaCompleto) {
      // <-- NUEVO Y SEGURO

      var productsToSend = batchBloc.filteredProducts
          .where((element) => element.isSendOdoo == 0)
          .toList();

      // Si hay productos pendientes de enviar a Odoo, mostramos un modal
      if (productsToSend.isNotEmpty) {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Center(
              child: Text("360 Software Informa",
                  style: TextStyle(color: yellow, fontSize: 16)),
            ),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Tienes productos que no han sido enviados al WMS. revisa la lista de productos y envíalos antes de continuar.",
                    style: TextStyle(color: black, fontSize: 14)),
                const SizedBox(height: 15),
                ElevatedButton(
                    onPressed: () {
                      batchBloc.isSearch = false;
                      Navigator.pushReplacementNamed(
                        context,
                        'detail-cluster',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: Text('Ver productos',
                        style: TextStyle(color: primaryColorApp, fontSize: 12)))
              ],
            ),
          ),
        );
      } else {
        // batchBloc.add(EndTimePick(
        //     batchBloc.batchWithProducts.batch?.id ?? 0, DateTime.now()));

        // batchBloc.add(PickingOkEvent(batchBloc.batchWithProducts.batch?.id ?? 0,
        //     currentProduct.idProduct ?? 0, batchBloc.typePicking));

        batchBloc.index = 0;
        batchBloc.isSearch = true;
        Navigator.pushReplacementNamed(
          context,
          'validate-cluster',
        );
        //navegamos a validar el pedido
      }
    } else {
      final double porcentajeVisual =
          double.tryParse(batchBloc.calcularProgresoReal()) ?? 0.0;
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (contextDialog) {
            return DialogPickingIncompleted(
                currentProduct: batchBloc.currentProduct!,
                cantidad: porcentajeVisual,
                batchBloc: batchBloc,
                onAccepted: () {
                  if (Navigator.canPop(contextDialog)) {
                    Navigator.pop(contextDialog);
                  }

                  batchBloc.isSearch = false;
                  //   batchBloc.add(LoadProductEditEvent(batchBloc.typePicking));
                  Navigator.pushReplacementNamed(
                    context,
                    'detail-cluster',
                  );
                });
          });
    }
  }

  void _validatebuttonquantity() {
    final batchBloc = context.read<ClusterPickingBloc>();
    final currentProduct = batchBloc.currentProduct;

    String input = _controllerCantidad.text.trim();

    // 1. Preparación y Validación básica
    if (input.isEmpty) {
      input = batchBloc.quantitySelected.toString();
    }
    input = input.replaceAll(',', '.');

    final isValid = RegExp(r'^\d+([.,]?\d+)?$').hasMatch(input);

    if (!isValid) {
      _showFormatError();
      return;
    }

    double? cantidad = double.tryParse(input);
    if (cantidad == null) {
      _showFormatError();
      return;
    }

    void procesarTransaccion() {
      batchBloc.add(ChangeQuantitySeparate(
          cantidad, // Usamos la variable validada
          currentProduct?.idProduct ?? 0,
          currentProduct?.idMove ?? 0,
          'cluster'));
      _nextProduct(currentProduct!, batchBloc);
      _controllerCantidad.clear();
    }

    final double cantidadSolicitada =
        (currentProduct?.quantity ?? 0).toDouble();
    final bool esExceso = cantidad > cantidadSolicitada;
    final bool esExacto = cantidad == cantidadSolicitada;

    // 1. Si es exacto, pasa directo.
    if (esExacto) {
      procesarTransaccion();
      return;
    }
    FocusScope.of(context).unfocus();
    // 2. Manejo de EXCESOS (Cantidad Mayor)
    if (esExceso) {
      _showBusinessError('Cantidad errónea');
      return;
    }

    // 3. Manejo de MENOR CANTIDAD (O cualquier otro caso no cubierto arriba)
    // Aquí sí mostramos el diálogo de advertencia (ej. cuando la cantidad es menor)
    showDialog(
      context: context,
      builder: (context) {
        return DialogAdvetenciaCantidadScreen(
          productQuantity: batchBloc.currentProduct!.quantity ?? 0,
          cantidad: cantidad,
          novedades: batchBloc.novedades,
          batchId: batchBloc.currentBatch?.id ?? 0,
          onAccepted: (String selectedNovedad) async {
            batchBloc.add(
                UpdateNovedadProductEvent(selectedNovedad, currentProduct!));
            procesarTransaccion();
          },
        );
      },
    );
  }

  void _showBusinessError(String message) {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 1000),
      content: Text(message),
      backgroundColor: Colors.red[200],
    ));
  }

  void _showFormatError() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    Get.snackbar(
      'Error',
      'Cantidad inválida',
      backgroundColor: white,
      colorText: primaryColorApp,
      duration: const Duration(milliseconds: 1000),
      icon: const Icon(Icons.error, color: Colors.amber),
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // Aquí se ejecutan las acciones solo si la pantalla aún está montada
        showDialog(
          context: context,
          builder: (context) {
            return const DialogLoading(
              message: "Espere un momento...",
            );
          },
        );
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: white,
        body: MultiBlocListener(
          listeners: [
            BlocListener<ClusterPickingBloc, ClusterPickingState>(
              listener: (context, state) {
                debugPrint("✅STATE: $state");

                if (state is PickingClustersLoading) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const DialogLoading(message: "Cargando Clústers..."),
                  );
                }

                if (state is PickingClustersLoaded) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Cierra el loader
                  }
                  Navigator.pushReplacementNamed(context, 'picking-cluster');
                }

                if (state is PickingClustersError) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Cierra el loader
                  }
                  Get.snackbar(
                    '360 Software Informa',
                    state.message,
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: const Icon(Icons.error, color: Colors.red),
                    showProgressIndicator: true,
                    duration: const Duration(seconds: 5),
                  );
                  Navigator.pushReplacementNamed(context, 'picking-cluster');
                }

                if (state is SendToOdooStateSuccess) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Cierra el loader
                  }
                }

                if (state is LoadValidatePedidoState) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Cierra el loader
                  }
                  //mostramos dialogo para
                  validatePicking(context.read<ClusterPickingBloc>(), context,
                      context.read<ClusterPickingBloc>().currentProduct!);
                }

                if (state is CurrentProductChangedStateLoading) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const DialogLoading(message: "Enviando producto..."),
                  );
                }

                if (state is CurrentProductChangedStateError) {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Cierra el loader
                  }
                  showScrollableErrorDialog(state.msg);
                }

                if (state is BatchProductsError) {
                  Get.snackbar(
                    '360 Software Informa',
                    state.message,
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: const Icon(Icons.error, color: Colors.red),
                    showProgressIndicator: true,
                    duration: const Duration(seconds: 2),
                  );
                }

                //*estado cando la ubicacion de origen es cambiada
                if (state is ChangeLocationIsOkState) {
                  //cambiamos el foco
                  Future.delayed(const Duration(seconds: 1), () {
                    FocusScope.of(context).requestFocus(focusNode2);
                  });
                  _handleDependencies();
                }

                if (state is ViewProductImageSuccess) {
                  showImageDialog(context, state.imageUrl);
                } else if (state is ViewProductImageFailure) {
                  showScrollableErrorDialog(state.error);
                }

                //*estado cuando el producto es leido ok
                if (state is ChangeProductIsOkState) {
                  //pasamos al foco de lote
                  Future.delayed(const Duration(seconds: 1), () {
                    if (!mounted) return;
                    if (context
                            .read<ClusterPickingBloc>()
                            .currentProduct
                            ?.productTracking ==
                        "lot") {
                      FocusScope.of(context).requestFocus(focusNode6);
                    } else {
                      FocusScope.of(context).requestFocus(focusNode7);
                    }
                  });
                  _handleDependencies();
                }

                if (state is ValidatePedidoStateSuccess) {
                  Future.delayed(const Duration(seconds: 1), () {
                    FocusScope.of(context).requestFocus(focusNode3);
                  });
                  _handleDependencies();
                }

                // * validamos en todo cambio de estado de cantidad separada
                if (state is ChangeQuantitySeparateStateSuccess) {
                  if (state.quantity ==
                      context
                          .read<ClusterPickingBloc>()
                          .currentProduct
                          ?.quantity) {
                    _nextProduct(
                        context.read<ClusterPickingBloc>().currentProduct!,
                        context.read<ClusterPickingBloc>());
                  }
                }
              },
            ),
            BlocListener<LoteProductoBloc, LoteProductoState>(
              listener: (context, state) {
                if (state is LoteProductoLoading) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return const DialogLoading(message: "Procesando Lote...");
                    },
                  );
                } else if (state is LoteProductoError) {
                  Navigator.pop(context); // Cerrar loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 4),
                      content: Text(state.message),
                      backgroundColor: Colors.red[200],
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<ClusterPickingBloc, ClusterPickingState>(
            builder: (context, state) {
              final bloc = context.read<ClusterPickingBloc>();
              int totalTasks =
                  context.read<ClusterPickingBloc>().filteredProducts.length;

              double progress = totalTasks > 0
                  ? context
                          .read<ClusterPickingBloc>()
                          .filteredProducts
                          .where((e) {
                        return e.isSeparate == 1;
                      }).length /
                      totalTasks
                  : 0.0;
              return Column(
                children: [
                  //todo: barra info
                  BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                    builder: (context, status) {
                      return Container(
                        width: size.width,
                        color: primaryColorApp,
                        child: Column(
                          children: [
                            const WarningWidgetCubit(),
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _controllerQuantity.clear();
                                      bloc.add(ClearFieldsEvent());
                                      bloc.add(LoadLocalPickingClustersEvent());
                                    },
                                    icon: const Icon(Icons.arrow_back,
                                        color: Colors.white, size: 20),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      bloc.currentBatch?.name ?? '',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  const Spacer(),
                                  PopupMenuButtonWidget(
                                      currentProduct: bloc.currentProduct!),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                              child: ProgressIndicatorWidget(
                                progress: progress,
                                completed: bloc.filteredProducts.where((e) {
                                  return e.isSeparate == 1;
                                }).length,
                                total: bloc.products.length,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(top: 2),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            //todo : ubicacion de origen

                            LocationScannerWidget(
                              isLocationOk: bloc.isLocationOk,
                              locationIsOk: bloc.locationIsOk,
                              productIsOk: bloc.productIsOk,
                              quantityIsOk: bloc.quantityIsOk,
                              locationDestIsOk: bloc.locationDestIsOk,
                              currentLocationId:
                                  bloc.currentProduct?.locationId?.toString() ??
                                      '',
                              onValidateLocation: (value) {
                                validateLocation(value);
                              },
                              onKeyScanned: (keyLabel) {},
                              focusNode: focusNode1,
                              controller: _controllerLocation,
                              locationDropdown: LocationDropdownWidget(
                                selectedLocation: "",
                                positionsOrigen:
                                    bloc.currentProduct?.locationId != null
                                        ? [bloc.currentProduct?.locationId]
                                        : [],
                                currentLocationId: bloc
                                        .currentProduct?.locationId
                                        ?.toString() ??
                                    '',
                                currentProduct: bloc.currentProduct!,
                                isPDA: true,
                              ),
                            ),

                            // todo: Producto

                            ProductScannerWidget(
                              isProductOk: bloc.isProductOk,
                              productIsOk: bloc.productIsOk,
                              locationIsOk: bloc.locationIsOk,
                              isViewLote: false,
                              quantityIsOk: bloc.quantityIsOk,
                              locationDestIsOk: bloc.locationDestIsOk,
                              currentProductId:
                                  bloc.currentProduct?.productId?.toString() ??
                                      '',
                              barcode: bloc.currentProduct?.barcode ?? '',
                              lotId: bloc.currentProduct?.lotId ?? '',
                              origin: bloc.currentProduct?.origin ?? '',
                              expireDate: bloc.currentProduct?.expireDate ?? '',
                              size: size,
                              onValidateProduct: (value) {
                                validateProduct(value);
                              },
                              onKeyScanned: (keyLabel) {},
                              focusNode: focusNode2,
                              controller: _controllerProduct,
                              productDropdown: ProductDropdownWidget(
                                selectedProduct:
                                    selectedMuelle, // o selectedProduct
                                listOfProductsName: [
                                  bloc.currentProduct?.productId?.toString() ??
                                      ''
                                ],
                                currentProductId:
                                    bloc.currentProduct?.productId.toString() ??
                                        '',
                                currentProduct: bloc.currentProduct!,
                                bloc: bloc,
                              ),
                              expiryWidget: Container(),
                              listOfBarcodes: bloc.listOfBarcodes,
                              onBarcodesDialogTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return DialogBarcodes(
                                        listOfBarcodes: bloc.listOfBarcodes);
                                  },
                                );
                              },
                              onViewImgProduct: () {
                                bloc.add(ViewProductImageEvent(
                                    bloc.currentProduct?.idProduct ?? 0));
                              },
                            ),

                            //todo: lotes

                            Visibility(
                              visible:
                                  bloc.currentProduct?.productTracking == "lot",
                              child: GestureDetector(
                                onTap: bloc.locationIsOk && bloc.productIsOk
                                    ? () {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.selectLoteCluster,
                                          arguments: [
                                            bloc.listLotesProduct, // [0] lotes
                                            bloc.currentProduct
                                                ?.loteId, // [3] suggestedLoteId
                                          ],
                                        );
                                      }
                                    : null,
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: bloc.loteIsOk ? green : yellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Card(
                                      color: bloc.isLoteOk
                                          ? bloc.loteIsOk
                                              ? Colors.green[100]
                                              : Colors.grey[300]
                                          : Colors.red[200],
                                      elevation: 5,
                                      child: Container(
                                          width: size.width * 0.85,
                                          padding: const EdgeInsets.only(
                                              left: 10, right: 10, bottom: 5),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 30,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Lote del producto',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              primaryColorApp),
                                                    ),
                                                    const Spacer(),
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: SvgPicture.asset(
                                                        color: primaryColorApp,
                                                        "assets/icons/barcode.svg",
                                                        height: 20,
                                                        width: 20,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 5),
                                                    height: 20,
                                                    child: LoteScannerWidget(
                                                      controller:
                                                          _controllerLote,
                                                      focusNode: focusNode6,
                                                      enabled: bloc
                                                              .productIsOk && //true
                                                          !bloc
                                                              .loteIsOk && //false
                                                          !bloc
                                                              .quantityIsOk && //false
                                                          !bloc.viewQuantity,
                                                      hintText: bloc.lotesProductCurrent
                                                                      .name ==
                                                                  "" ||
                                                              bloc.lotesProductCurrent
                                                                      .name ==
                                                                  null
                                                          ? 'Esperando escaneo'
                                                          : bloc.lotesProductCurrent
                                                                  .name ??
                                                              "",
                                                      onValidateLote:
                                                          validateLote,
                                                    ),
                                                  ),
                                                  ExpirationBadgeWidget(
                                                    expirationDate: bloc
                                                        .lotesProductCurrent
                                                        .expirationDate,
                                                  ),
                                                ],
                                              )
                                            ],
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            DynamicScannerWidget(
                              isLocationOk: bloc.isLocationOk,
                              locationIsOk: bloc.locationIsOk,
                              productIsOk: bloc.productIsOk,
                              pedidoValidateIsOk: bloc.pedidoValidateIsOk,
                              isPedidoValidateOk: bloc.isPedidoValidateOk,
                              quantityIsOk: bloc.quantityIsOk,
                              locationDestIsOk: bloc.locationDestIsOk,
                              currentLocationId:
                                  bloc.currentProduct?.pedido?.toString() ??
                                      'Sin Pedido',
                              onValidateLocation: (value) {
                                validatePedido(value);
                              },
                              onKeyScanned: (keyLabel) {},
                              focusNode: focusNode7,
                              controller: _controllerPedido,
                              locationDropdown: PedidoDropdownWidget(
                                selectedLocation: "",
                                positionsOrigen:
                                    bloc.currentProduct?.origin != null
                                        ? [
                                            bloc.currentProduct?.origin
                                                    .toString() ??
                                                ""
                                          ]
                                        : [],
                                currentLocationId:
                                    bloc.currentProduct?.origin?.toString() ??
                                        "",
                                currentProduct: bloc.currentProduct!,
                                isPDA: true,
                              ),
                            ),
                            //Todo: MUELLE fijo

                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Card(
                                  color: Colors.green[100],
                                  elevation: 5,
                                  child: Container(
                                      // color: Colors.amber,
                                      width: size.width * 0.85,
                                      padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                          top: 2,
                                          bottom: 2),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Ubicación destino',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              const Spacer(),
                                              SvgPicture.asset(
                                                color: primaryColorApp,
                                                "assets/icons/packing.svg",
                                                height: 20,
                                                width: 20,
                                                fit: BoxFit.cover,
                                              ),
                                            ],
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Text(
                                                  bloc.currentProduct
                                                          ?.locationDestId ??
                                                      '',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      color: black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  //todo: cantidad
                  QuantityScannerWidget(
                    size: size,
                    isQuantityOk: bloc.isQuantityOk,
                    quantityIsOk: bloc.quantityIsOk,
                    locationIsOk: bloc.locationIsOk,
                    productIsOk: bloc.productIsOk,
                    locationDestIsOk: bloc.locationDestIsOk,
                    totalQuantity: bloc.currentProduct?.quantity,
                    quantitySelected: bloc.quantitySelected,
                    unidades: bloc.currentProduct?.unidades ?? "",
                    controller: _controllerQuantity,
                    manualController: _controllerCantidad,
                    scannerFocusNode: focusNode3,
                    manualFocusNode: focusNode4,
                    viewQuantity: bloc.viewQuantity,
                    onIconButtonPressed: () {
                      bloc.add(ShowQuantityEvent(!bloc.viewQuantity));
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(focusNode3);
                      });
                    },
                    onToggleViewQuantity: () {
                      bloc.add(ShowQuantityEvent(!bloc.viewQuantity));
                      _controllerCantidad.clear();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(focusNode3);
                      });
                    },
                    onValidateButton: () {
                      FocusScope.of(context).unfocus();
                      _validatebuttonquantity();
                    },
                    onValidateScannerInput: (value) {
                      validateQuantity(value);
                    },
                    onManualQuantityChanged: (value) {
                      if (value.isNotEmpty) {
                        try {
                          bloc.quantitySelected = double.parse(value);
                        } catch (e) {
                          debugPrint('❌ Error al convertir a número: $e');
                        }
                      } else {
                        bloc.quantitySelected = 0;
                      }
                    },
                    onManualQuantitySubmitted: (value) {
                      if (value.isNotEmpty) {
                        final intValue = int.parse(value);
                        if (intValue > (bloc.currentProduct?.quantity ?? 0)) {
                          bloc.add(ValidateFieldsEvent(
                              field: "quantity", isOk: false));
                          _controllerCantidad.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 1),
                              content: const Text('Cantidad incorrecta'),
                              backgroundColor: Colors.red[200],
                            ),
                          );
                        } else {
                          if (intValue == bloc.currentProduct?.quantity) {
                            bloc.add(ChangeQuantitySeparate(
                                intValue,
                                bloc.currentProduct?.idProduct ?? 0,
                                bloc.currentProduct?.idMove ?? 0,
                                'cluster'));
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return DialogAdvetenciaCantidadScreen(
                                  productQuantity:
                                      bloc.currentProduct?.quantity ?? 0,
                                  cantidad: bloc.quantitySelected,
                                  batchId: bloc.currentBatch?.id ?? 0,
                                  novedades: [],
                                  onAccepted: (String selectedNovedad) async {
                                    bloc.add(ChangeQuantitySeparate(
                                        intValue,
                                        bloc.currentProduct?.idProduct ?? 0,
                                        bloc.currentProduct?.idMove ?? 0,
                                        'cluster'));
                                    bloc.add(UpdateNovedadProductEvent(
                                        selectedNovedad, bloc.currentProduct!));

                                    _nextProduct(bloc.currentProduct!, bloc);
                                  },
                                );
                              },
                            );
                          }
                        }
                      }
                      bloc.add(ShowQuantityEvent(false));
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _nextProduct(
      BatchProduct currentProduct, ClusterPickingBloc batchBloc) async {
    // Si el proceso ya está en ejecución, no hacemos nada
    if (batchBloc.isProcessing) return;

    // Establecemos la bandera de forma síncrona para bloquear de inmediato
    batchBloc.isProcessing = true;
    batchBloc.add(SetIsProcessingEvent(true));

    try {
      // DataBaseSqlite db = DataBaseSqlite();
      final batch = batchBloc.currentBatch;

      // Si no hay batch, termina la ejecución
      if (batch == null) return;

      debugPrint("currentProduct ${currentProduct.productId}");

      // Función para actualizar la base de datos en varios campos a la vez
      Future<void> updateDatabaseFields() async {
        batchBloc.add(SeparateProductEvent(
          currentProduct.idProduct ?? 0,
          batch.id ?? 0,
          currentProduct.idMove ?? 0,
          'cluster',
        ));
      }

      // Función para gestionar la transición al siguiente producto
      Future<void> moveToNextProduct() async {
        // Si estamos en la última posición
        final separated =
            batchBloc.filteredProducts.where((e) => e.isSeparate == 0).toList();

        if (batchBloc.index + 1 == separated.length) {
          debugPrint("Último elemento alcanzado");
          batchBloc.add(ChangeCurrentProduct(
            currentProduct: currentProduct,
            type: 'cluster',
          ));

          // Cambiar el estado de cantidad
          batchBloc.add(ChangeIsOkQuantity(
            false,
            currentProduct.idProduct ?? 0,
            batch.id ?? 0,
            currentProduct.idMove ?? 0,
            'cluster',
          ));

          batchBloc.updateStateQuantity(currentProduct.idProduct ?? 0,
              batch.id ?? 0, currentProduct.idMove ?? 0, 0);
        } else {
          debugPrint("No estamos en la última posición");
          // Si no estamos en la última posición, cambiamos el producto actual
          batchBloc.add(ChangeCurrentProduct(
            currentProduct: currentProduct,
            type: 'cluster',
          ));

          // Validamos el campo "quantity"
          batchBloc.add(ValidateFieldsEvent(field: "quantity", isOk: true));

          // Limpiamos el controlador de cantidad
          batchBloc.quantitySelected = 0;
          _controllerCantidad.clear();

          // Esperar 1 segundo y llamar los códigos de barras del producto
          await Future.delayed(const Duration(seconds: 1));
          batchBloc.add(FetchBarcodesProductEvent());
        }
      }

      // Ejecutar las operaciones en bloque
      await updateDatabaseFields();
      batchBloc.add(ShowQuantityEvent(false));
      //todo activar
      // batchBloc.sortProductsByLocationId('cluster');
      await moveToNextProduct();
    } catch (e, s) {
      debugPrint("❌ Error en _nextProduct: $e -> $s");
      batchBloc.isProcessing = false;
      batchBloc.add(SetIsProcessingEvent(false));
    }
  }
}

class DialogValidateLot extends StatelessWidget {
  const DialogValidateLot({
    super.key,
    required this.bloc,
    required this.selectedLote,
    required this.onLoteSelectedWithValidate,
  });

  final ClusterPickingBloc bloc;
  final LoteProducto selectedLote;
  final Function(LoteProducto) onLoteSelectedWithValidate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //icono de advertencia
            const Icon(
              Icons.warning,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              'ADVERTENCIA',
              style: TextStyle(
                  fontSize: 16, color: black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              textAlign: TextAlign.center,
              'El lote seleccionado no es el sugerido desde la reserva en WMS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Lote sugerido: ', style: TextStyle(color: primaryColorApp)),
              Text('${bloc.currentProduct?.lotId}'),
            ],
          ),
          Row(
            children: [
              Text('Lote seleccionado: ',
                  style: TextStyle(color: primaryColorApp)),
              Text('${selectedLote.name}'),
            ],
          ),
          const SizedBox(height: 10),
          const Text('¿Desea continuar?'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Cancelar', style: TextStyle(color: white)),
        ),
        ElevatedButton(
          onPressed: () {
            onLoteSelectedWithValidate(selectedLote);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColorApp,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Aceptar', style: TextStyle(color: white)),
        ),
      ],
    );
  }
}
