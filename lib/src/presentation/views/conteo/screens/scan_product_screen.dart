// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/location/location_dropdown_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/others/dialog_validate_product_send_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/product/product_dropdown_widget.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/location/scanner_location_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/product/scanner_product_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/quantity/scanner_quantity_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_numbers_widget.dart';

class ScanProductConteoScreen extends StatefulWidget {
  const ScanProductConteoScreen({super.key});

  @override
  State<ScanProductConteoScreen> createState() =>
      _ScanProductConteoScreenState();
}

class _ScanProductConteoScreenState extends State<ScanProductConteoScreen>
    with WidgetsBindingObserver {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

  //*focus
  FocusNode focusNode1 = FocusNode(); // ubicacion  de origen
  FocusNode focusNode2 = FocusNode(); // producto
  FocusNode focusNode3 = FocusNode(); // cantidad por pda
  FocusNode focusNode4 = FocusNode(); //cantidad textformfield
  FocusNode focusNode5 = FocusNode(); // lote

  //controller
  final TextEditingController _controllerLocation = TextEditingController();
  final TextEditingController _controllerProduct = TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final TextEditingController _controllerLote = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  String? selectedLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted) {
      showDialog(
        context: context,
        builder: (context) =>
            const DialogLoading(message: "Espere un momento..."),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
      // _handleFocusAccordingToState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleFocusAccordingToState();
  }

  void _setOnlyFocus(FocusNode nodeToFocus) {
    for (final node in [
      focusNode1,
      focusNode2,
      focusNode3,
      focusNode4,
      focusNode5,
    ]) {
      if (node == nodeToFocus) {
        FocusScope.of(context).requestFocus(node);
      } else {
        node.unfocus();
      }
    }
  }

  void _handleFocusAccordingToState() {
    final bloc = context.read<ConteoBloc>();
    final hasLote = bloc.currentProduct.productTracking == "lot";

    final focusMap = {
      "location": () =>
          !bloc.locationIsOk &&
          !bloc.productIsOk &&
          !bloc.quantityIsOk &&
          !bloc.locationDestIsOk,
      "product": () =>
          bloc.locationIsOk &&
          !bloc.productIsOk &&
          !bloc.quantityIsOk &&
          !bloc.locationDestIsOk,
      "lote": () =>
          hasLote &&
          bloc.locationIsOk &&
          bloc.productIsOk &&
          !bloc.loteIsOk &&
          !bloc.quantityIsOk &&
          !bloc.viewQuantity,
      "quantity": () =>
          bloc.locationIsOk &&
          bloc.productIsOk &&
          (hasLote ? bloc.loteIsOk : true) &&
          bloc.quantityIsOk &&
          !bloc.locationDestIsOk &&
          !bloc.viewQuantity
    };

    //mostrar las variables
    print("locationIsOk: ${bloc.locationIsOk}");
    print("productIsOk: ${bloc.productIsOk}");
    print("locationDestIsOk: ${bloc.locationDestIsOk}");
    print("loteIsOk: ${bloc.loteIsOk}");
    print("quantityIsOk: ${bloc.quantityIsOk}");
    print("viewQuantity: ${bloc.viewQuantity}");

    final focusNodeByKey = {
      "location": focusNode1,
      "product": focusNode2,
      "lote": focusNode5,
      "quantity": focusNode3,
    };

    for (final entry in focusMap.entries) {
      if (entry.value()) {
        debugPrint("🚼 ${entry.key}");
        _setOnlyFocus(focusNodeByKey[entry.key]!);
        break;
      }
    }
  }

  @override
  void dispose() {
    for (final node in [
      focusNode1,
      focusNode2,
      focusNode3,
      focusNode4,
    ]) {
      node.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _getScannedOrManual(String scanned, String manual) {
    print("Scanned: $scanned, Manual: $manual");
    final scan = scanned.trim().toLowerCase();
    return scan.isEmpty ? manual.trim().toLowerCase() : scan;
  }

  void validateLote(String value) {
    final bloc = context.read<ConteoBloc>();
    String scan = bloc.scannedValue4.trim().toLowerCase() == ""
        ? value.trim().toLowerCase()
        : bloc.scannedValue4.trim().toLowerCase();
    print('scan lote: $scan');
    _controllerLote.clear();
    //tengo una lista de lotes el cual quiero validar si el scan es igual a alguno de los lotes
    LotesProduct? matchedLote = bloc.listLotesProduct.firstWhere(
        (lotes) => lotes.name?.toLowerCase() == scan.trim(),
        orElse: () =>
            LotesProduct() // Si no se encuentra ningún match, devuelve null
        );

    if (matchedLote.name != null) {
      print('lote encontrado: ${matchedLote.name}');
      bloc.add(ValidateFieldsEvent(field: "lote", isOk: true));
      bloc.add(SelectecLoteEvent(matchedLote));
      bloc.add(ClearScannedValueEvent('lote'));
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      print('lote no encontrado');
      bloc.add(ValidateFieldsEvent(field: "lote", isOk: false));
      bloc.add(ClearScannedValueEvent('lote'));
    }
  }

  void validateLocation(String value) {
    final bloc = context.read<ConteoBloc>();
    final scan = _getScannedOrManual(bloc.scannedValue1, value);
    final product = bloc.currentProduct;

    _controllerLocation.clear();

    if (scan == product.locationBarcode?.toLowerCase()) {
      bloc.add(ValidateFieldsEvent(field: "location", isOk: true));
      bloc.add(ChangeLocationIsOkEvent(false, ResultUbicaciones(),
          product.productId ?? 0, product.orderId ?? 0, product.idMove ?? 0));
      bloc.oldLocation = product.locationId.toString();
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      bloc.add(ValidateFieldsEvent(field: "location", isOk: false));
    }

    bloc.add(ClearScannedValueEvent('location'));
  }

  void validateProduct(String value) {
    final bloc = context.read<ConteoBloc>();
    final scan = _getScannedOrManual(bloc.scannedValue2, value);
    final product = bloc.currentProduct;

    _controllerProduct.clear();

    if (scan == product.productBarcode?.toLowerCase()) {
      bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
      bloc.add(ChangeProductIsOkEvent(
        false,
        Product(),
        product.orderId ?? 0,
        true,
        product.productId ?? 0,
        0,
        product.idMove ?? 0,
      ));
    } else {
      final isOk = validateScannedBarcode(scan, product, bloc, true);
      if (!isOk) {
        _vibrationService.vibrate();
        _audioService.playErrorSound();
        bloc.add(ValidateFieldsEvent(field: "product", isOk: false));
      }
    }

    bloc.add(ClearScannedValueEvent('product'));
  }

  bool validateScannedBarcode(String scannedBarcode, CountedLine currentProduct,
      ConteoBloc bloc, bool isProduct) {
    // Buscar el barcode que coincida con el valor escaneado
    Barcodes? matchedBarcode = bloc.listOfBarcodes.firstWhere(
        (barcode) => barcode.barcode?.toLowerCase() == scannedBarcode,
        orElse: () =>
            Barcodes() // Si no se encuentra ningún match, devuelve null
        );
    if (matchedBarcode.barcode != null) {
      if (isProduct) {
        bloc.add(ValidateFieldsEvent(field: "product", isOk: true));

        bloc.add(ChangeQuantitySeparate(
          false,
          0,
          currentProduct.productId ?? 0,
          currentProduct.orderId ?? 0,
          currentProduct.idMove ?? 0,
        ));

        bloc.add(ChangeProductIsOkEvent(
          false,
          Product(),
          currentProduct.orderId ?? 0,
          true,
          currentProduct.productId ?? 0,
          0,
          currentProduct.idMove ?? 0,
        ));

        bloc.add(ChangeIsOkQuantity(
          currentProduct.orderId ?? 0,
          true,
          currentProduct.productId ?? 0,
          currentProduct.idMove ?? 0,
        ));

        return true;
      } else {
        bloc.add(AddQuantitySeparate(
            currentProduct.productId ?? 0,
            currentProduct.orderId ?? 0,
            matchedBarcode.idMove ?? 0,
            matchedBarcode.cantidad,
            false));
      }
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      return false;
    }
    _vibrationService.vibrate();
    _audioService.playErrorSound();
    return false;
  }

  void validateQuantity(String value) {
    final bloc = context.read<ConteoBloc>();

    String scan = bloc.scannedValue3.trim().toLowerCase() == ""
        ? value.trim().toLowerCase()
        : bloc.scannedValue3.trim().toLowerCase();
    print('scan quantity: $scan');
    _controllerQuantity.clear();
    final currentProduct = bloc.currentProduct;

    if (scan == currentProduct.productBarcode?.toLowerCase()) {
      bloc.add(AddQuantitySeparate(currentProduct.productId ?? 0,
          currentProduct.orderId ?? 0, currentProduct.idMove ?? 0, 1, false));
      bloc.add(ClearScannedValueEvent('quantity'));
    } else {
      validateScannedBarcode(scan, currentProduct, bloc, false);
      bloc.add(ClearScannedValueEvent('quantity'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocBuilder<ConteoBloc, ConteoState>(
        builder: (context, state) {
          return Scaffold(
              backgroundColor: white,
              body: Column(
                children: [
                  //todo: barra info
                  BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                    builder: (context, status) {
                      return Container(
                        width: size.width,
                        color: primaryColorApp,
                        child: BlocConsumer<ConteoBloc, ConteoState>(
                            listener: (context, state) {
                          print("❤️‍🔥 state : $state");

                          if (state is ViewProductImageSuccess) {
                            showImageDialog(context, state.imageUrl);
                          } else if (state is ViewProductImageFailure) {
                            showScrollableErrorDialog(state.error);
                          }

                          if (state is SendProductConteoFailure) {
                            showScrollableErrorDialog(state.error);
                          }

                          // * validamos en todo cambio de estado de cantidad separada

                          if (state is SendProductConteoSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(milliseconds: 1000),
                              content: Text(state.response.result?.msg ?? ""),
                              backgroundColor: Colors.green[200],
                            ));
                            //limpiamos los valores pa volver a iniciar con otro producto
                            cantidadController.clear();
                            context.read<ConteoBloc>().add(ResetValuesEvent(
                                resetAll: true, isLoading: false));

                            context.read<ConteoBloc>().add(
                                  LoadConteoAndProductsEvent(
                                      ordenConteoId: state
                                              .response.result?.data?.orderId ??
                                          0),
                                );

                            Navigator.pushReplacementNamed(
                              context,
                              'conteo-detail',
                              arguments: [
                                1,
                                context.read<ConteoBloc>().ordenConteo,
                              ],
                            );
                          }

                          if (state is ChangeLoteIsOkState) {
                            //cambiamos el foco a cantidad cuando hemos seleccionado un lote
                            Future.delayed(const Duration(seconds: 1), () {
                              FocusScope.of(context).requestFocus(focusNode3);
                            });
                            _handleFocusAccordingToState();
                          }

                          if (state is ChangeQuantitySeparateStateError) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(milliseconds: 1000),
                              content: Text(state.msg),
                              backgroundColor: Colors.red[200],
                            ));
                          }

                          if (state is ValidateFieldsStateError) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              duration: const Duration(milliseconds: 1000),
                              content: Text(state.msg),
                              backgroundColor: Colors.red[200],
                            ));
                          }

                          //*estado cando la ubicacion de origen es cambiada
                          if (state is ChangeLocationIsOkState) {
                            //cambiamos el foco
                            Future.delayed(const Duration(seconds: 1), () {
                              FocusScope.of(context).requestFocus(focusNode2);
                            });
                            _handleFocusAccordingToState();
                          }

                          //*estado cuando el producto es leido ok
                          if (state is ChangeProductOrderIsOkState) {
                            // Verificamos si el producto tiene lote para saber a dónde mover el foco
                            if (context
                                    .read<ConteoBloc>()
                                    .currentProduct
                                    .productTracking ==
                                "lot") {
                              // Si la pantalla sigue activa, movemos el foco
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted) {
                                  FocusScope.of(context)
                                      .requestFocus(focusNode5);
                                }
                              });
                            } else {
                              // Si no tiene lote, movemos el foco a otro lugar
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted) {
                                  FocusScope.of(context)
                                      .requestFocus(focusNode3);
                                }
                              });
                            }

                            _handleFocusAccordingToState();
                          } else if (state is ProductAlreadySentState) {
                            //mostramos un dialogo DialogValidateProductSendWidget

                            showDialog(
                                context: context,
                                builder: (context) {
                                  return DialogValidateProductSendWidget(
                                      productExist: state.productExist,
                                      product: state.product,
                                      cantidadController: cantidadController);
                                });
                          }
                        }, builder: (context, status) {
                          return Column(
                            children: [
                              const WarningWidgetCubit(),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        cantidadController.clear();

                                        context.read<ConteoBloc>().add(
                                            ResetValuesEvent(
                                                resetAll: true,
                                                isLoading: false));

                                        Navigator.pushReplacementNamed(
                                          context,
                                          'conteo-detail',
                                          arguments: [
                                            1,
                                            context
                                                .read<ConteoBloc>()
                                                .ordenConteo,
                                          ],
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white, size: 20),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          right: size.width * 0.015),
                                      child: Text(
                                        'CONTEO FISICO',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      );
                    },
                  ),
                  //todo: scaners
                  Expanded(
                      child: Container(
                          padding: const EdgeInsets.only(top: 2),
                          child: SingleChildScrollView(
                              child: Column(children: [
                            //todo : ubicacion de origen

                            LocationScannerWidget(
                              isLocationOk:
                                  context.read<ConteoBloc>().isLocationOk,
                              locationIsOk:
                                  context.read<ConteoBloc>().locationIsOk,
                              productIsOk:
                                  context.read<ConteoBloc>().productIsOk,
                              quantityIsOk:
                                  context.read<ConteoBloc>().quantityIsOk,
                              locationDestIsOk: false,
                              currentLocationId: context
                                  .read<ConteoBloc>()
                                  .currentProduct
                                  .locationName
                                  .toString(),
                              onValidateLocation: (value) {
                                validateLocation(value);
                              },
                              onKeyScanned: (keyLabel) {
                                context.read<ConteoBloc>().add(
                                    UpdateScannedValueEvent(
                                        keyLabel, 'location'));
                              },
                              focusNode: focusNode1,
                              controller: _controllerLocation,
                              locationDropdown: LocationDropdownConteoWidget(
                                selectedLocation: selectedLocation,
                                positionsOrigen:
                                    context.read<ConteoBloc>().positionsOrigen,
                                currentLocationId: context
                                    .read<ConteoBloc>()
                                    .currentProduct
                                    .locationName
                                    .toString(),
                                conteoBloc: context.read<ConteoBloc>(),
                                currentProduct:
                                    context.read<ConteoBloc>().currentProduct,
                                isPDA: !context
                                    .read<UserBloc>()
                                    .fabricante
                                    .contains("Zebra"),
                              ),
                            ),

                            // todo: Producto

                            ProductScannerWidget(
                              isViewLote: false,
                              isProductOk:
                                  context.read<ConteoBloc>().isProductOk,
                              productIsOk:
                                  context.read<ConteoBloc>().productIsOk,
                              locationIsOk:
                                  context.read<ConteoBloc>().locationIsOk,
                              quantityIsOk:
                                  context.read<ConteoBloc>().quantityIsOk,
                              locationDestIsOk: false,
                              category: context
                                  .read<ConteoBloc>()
                                  .currentProduct
                                  .categoryName
                                  .toString(),
                              currentProductId: context
                                  .read<ConteoBloc>()
                                  .currentProduct
                                  .productName
                                  .toString(),
                              barcode: context
                                  .read<ConteoBloc>()
                                  .currentProduct
                                  .productBarcode,
                              lotId: context
                                  .read<ConteoBloc>()
                                  .currentProduct
                                  .lotName,
                              origin: "",
                              expireDate: context
                                  .read<ConteoBloc>()
                                  .currentProduct
                                  .fechaVencimiento,
                              size: size,
                              onValidateProduct: (value) {
                                validateProduct(value); // tu función actual
                              },
                              onKeyScanned: (keyLabel) {
                                context.read<ConteoBloc>().add(
                                    UpdateScannedValueEvent(
                                        keyLabel, 'product'));
                              },
                              focusNode: focusNode2,
                              controller: _controllerProduct,
                              productDropdown: ProductDropdownConteoWidget(
                                selectedProduct:
                                    selectedLocation, // o selectedProduct
                                listOfProductsName: context
                                    .read<ConteoBloc>()
                                    .listOfProductsName,
                                currentProductId: context
                                    .read<ConteoBloc>()
                                    .currentProduct
                                    .productName
                                    .toString(),
                                conteoBloc: context.read<ConteoBloc>(),
                                currentProduct:
                                    context.read<ConteoBloc>().currentProduct,
                              ),
                              expiryWidget: Container(),
                              listOfBarcodes:
                                  context.read<ConteoBloc>().listOfBarcodes,
                              onBarcodesDialogTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return DialogBarcodes(
                                      listOfBarcodes: context
                                          .read<ConteoBloc>()
                                          .listOfBarcodes,
                                    );
                                  },
                                );
                              },
                              onViewImgProduct: () {
                                context.read<ConteoBloc>().add(
                                    ViewProductImageEvent(context
                                            .read<ConteoBloc>()
                                            .currentProduct
                                            .productId ??
                                        0));
                              },
                            ),

                            //todo: lotes

                            Visibility(
                              visible: context
                                      .read<ConteoBloc>()
                                      .currentProduct
                                      .productTracking ==
                                  "lot",
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color:
                                            context.read<ConteoBloc>().loteIsOk
                                                ? green
                                                : yellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Card(
                                    color: context.read<ConteoBloc>().isLoteOk
                                        ? context.read<ConteoBloc>().loteIsOk
                                            ? Colors.green[100]
                                            : Colors.grey[300]
                                        : Colors.red[200],
                                    elevation: 5,
                                    child: Container(
                                        width: size.width * 0.85,
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10, bottom: 10),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Lote del producto',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: primaryColorApp),
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
                                                IconButton(
                                                    onPressed: () {
                                                      //validamos que el producto ya esta escaneado y la ubicacion tambien
                                                      if (context
                                                              .read<
                                                                  ConteoBloc>()
                                                              .productIsOk &&
                                                          context
                                                              .read<
                                                                  ConteoBloc>()
                                                              .locationIsOk) {
                                                        Navigator
                                                            .pushReplacementNamed(
                                                          context,
                                                          'new-lote-orden',
                                                          arguments: [
                                                            context
                                                                .read<
                                                                    ConteoBloc>()
                                                                .currentProduct
                                                          ],
                                                        );
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: primaryColorApp,
                                                      size: 20,
                                                    ))
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                //widget de scan
                                                context
                                                        .read<UserBloc>()
                                                        .fabricante
                                                        .contains("Zebra")
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 0,
                                                                vertical: 5),
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              height: 20,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      bottom: 5,
                                                                      top: 5),
                                                              child:
                                                                  TextFormField(
                                                                autofocus: true,
                                                                showCursor:
                                                                    false,
                                                                controller:
                                                                    _controllerLote, // Asignamos el controlador
                                                                enabled: context
                                                                        .read<
                                                                            ConteoBloc>()
                                                                        .locationIsOk && //true
                                                                    context
                                                                        .read<
                                                                            ConteoBloc>()
                                                                        .productIsOk && //true
                                                                    !context
                                                                        .read<
                                                                            ConteoBloc>()
                                                                        .loteIsOk && //false
                                                                    !context
                                                                        .read<
                                                                            ConteoBloc>()
                                                                        .quantityIsOk && //false
                                                                    !context
                                                                        .read<
                                                                            ConteoBloc>()
                                                                        .viewQuantity,

                                                                focusNode:
                                                                    focusNode5,
                                                                onChanged:
                                                                    (value) {
                                                                  // Llamamos a la validación al cambiar el texto
                                                                  validateLote(
                                                                      value);
                                                                },
                                                                decoration:
                                                                    InputDecoration(
                                                                  hintText: context.read<ConteoBloc>().currentProductLote?.name ==
                                                                              "" ||
                                                                          context.read<ConteoBloc>().currentProductLote?.name ==
                                                                              null
                                                                      ? 'Esperando escaneo'
                                                                      : context
                                                                              .read<ConteoBloc>()
                                                                              .currentProductLote
                                                                              ?.name ??
                                                                          "",
                                                                  disabledBorder:
                                                                      InputBorder
                                                                          .none,
                                                                  hintStyle: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          black),
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Focus(
                                                        focusNode: focusNode5,
                                                        onKey: (FocusNode node,
                                                            RawKeyEvent event) {
                                                          if (event
                                                              is RawKeyDownEvent) {
                                                            if (event
                                                                    .logicalKey ==
                                                                LogicalKeyboardKey
                                                                    .enter) {
                                                              validateLote(context
                                                                  .read<
                                                                      ConteoBloc>()
                                                                  .scannedValue4);

                                                              return KeyEventResult
                                                                  .handled;
                                                            } else {
                                                              context
                                                                  .read<
                                                                      ConteoBloc>()
                                                                  .add(UpdateScannedValueEvent(
                                                                      event.data
                                                                          .keyLabel,
                                                                      'lote'));

                                                              return KeyEventResult
                                                                  .handled;
                                                            }
                                                          }
                                                          return KeyEventResult
                                                              .ignored;
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 0,
                                                                  vertical: 5),
                                                          child: Column(
                                                            children: [
                                                              Align(
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      'Lote: ',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              black),
                                                                    ),
                                                                    Text(
                                                                      context
                                                                              .read<ConteoBloc>()
                                                                              .currentProductLote
                                                                              ?.name ??
                                                                          "Esperando escaneo",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              black),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),

                                                ExpirationBadgeWidget(
                                                  expirationDate: context
                                                      .read<ConteoBloc>()
                                                      .currentProductLote
                                                      ?.expirationDate,
                                                ),
                                              ],
                                            )
                                          ],
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ])))),
                  //todo: cantidad
                  QuantityScannerWidget(
                    size: size,
                    isQuantityOk: context.read<ConteoBloc>().isQuantityOk,
                    quantityIsOk: context.read<ConteoBloc>().quantityIsOk,
                    locationIsOk: context.read<ConteoBloc>().locationIsOk,
                    productIsOk: context.read<ConteoBloc>().productIsOk,
                    locationDestIsOk: false,
                    totalQuantity: context
                        .read<ConteoBloc>()
                        .currentProduct
                        .quantityInventory,
                    quantitySelected:
                        context.read<ConteoBloc>().quantitySelected,
                    unidades:
                        context.read<ConteoBloc>().currentProduct.uom ?? "",
                    controller: _controllerQuantity,
                    manualController: cantidadController,
                    scannerFocusNode: focusNode3,
                    manualFocusNode: focusNode4,
                    viewQuantity: context.read<ConteoBloc>().viewQuantity,
                    onIconButtonPressed: () {
                      print('borrando');
                      context.read<ConteoBloc>().add(ShowQuantityEvent(
                          !context.read<ConteoBloc>().viewQuantity));
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(focusNode3);
                      });
                    },
                    onKeyScanned: (keyLabel) {
                      context
                          .read<ConteoBloc>()
                          .add(UpdateScannedValueEvent(keyLabel, 'quantity'));
                    },
                    showKeyboard:
                        context.read<UserBloc>().fabricante.contains("Zebra"),
                    onToggleViewQuantity: () {
                      context.read<ConteoBloc>().add(ShowQuantityEvent(
                          !context.read<ConteoBloc>().viewQuantity));
                      cantidadController.clear();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(focusNode4);
                      });
                      print('Toggle view quantity');
                    },
                    onValidateButton: () {
                      FocusScope.of(context).unfocus();
                      _validatebuttonquantity();
                    },
                    onValidateScannerInput: (value) {
                      validateQuantity(value);
                    },
                    onManualQuantityChanged: (value) {
                      print('onManualQuantityChanged: $value');
                    },
                    onManualQuantitySubmitted: (value) {
                      final intValue = double.parse(value);

                      context.read<ConteoBloc>().add(ChangeQuantitySeparate(
                          false,
                          intValue,
                          context.read<ConteoBloc>().currentProduct.productId ??
                              0,
                          context.read<ConteoBloc>().currentProduct.orderId ??
                              0,
                          context.read<ConteoBloc>().currentProduct.idMove ??
                              0));

                      context.read<ConteoBloc>().add(ShowQuantityEvent(
                          !context.read<ConteoBloc>().viewQuantity));
                    },
                    customKeyboard: CustomKeyboardNumber(
                      controller: cantidadController,
                      onchanged: _validatebuttonquantity,
                    ),
                    isViewCant: context
                                .read<ConteoBloc>()
                                .ordenConteo
                                .mostrarCantidad ==
                            1
                        ? true
                        : false,
                  ),
                ],
              ));
        },
      ),
    );
  }

  void _validatebuttonquantity() {
    final bloc = context.read<ConteoBloc>();

    String input = cantidadController.text.trim();
    //validamos quantity

    print("cantidad: $input");

    // Si está vacío, usar la cantidad seleccionada del bloc
    if (input.isEmpty) {
      input = bloc.quantitySelected.toString();
    }

    // Reemplaza coma por punto para manejar formatos decimales europeos
    input = input.replaceAll(',', '.');

    // Expresión regular para validar un número válido
    final isValid = RegExp(r'^\d+([.,]?\d+)?$').hasMatch(input);

    // Validación de formato
    if (!isValid) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        'Error',
        'Cantidad inválida',
        backgroundColor: white,
        colorText: primaryColorApp,
        duration: const Duration(milliseconds: 1000),
        icon: Icon(Icons.error, color: Colors.amber),
        snackPosition: SnackPosition.TOP,
      );

      return;
    }

    // Intentar convertir a double
    double? cantidad = double.tryParse(input);
    if (cantidad == null) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        'Error',
        'Cantidad inválida',
        backgroundColor: white,
        colorText: primaryColorApp,
        duration: const Duration(milliseconds: 1000),
        icon: Icon(Icons.error, color: Colors.amber),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // if (bloc.currentUbication?.id == null) {
    //   Get.snackbar(
    //     '360 Software Informa',
    //     "No se ha selecionado la ubicacion",
    //     backgroundColor: white,
    //     colorText: primaryColorApp,
    //     icon: Icon(Icons.error, color: Colors.amber),
    //   );
    //   return;
    // }

    if (bloc.currentProduct.productTracking == 'lot') {
      if (bloc.currentProductLote?.id == null) {
        _audioService.playErrorSound();
        _vibrationService.vibrate();

        Get.snackbar(
          '360 Software Informa',
          "No se ha selecionado el lote",
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: Icon(Icons.error, color: Colors.amber),
        );
        return;
      } else {
        double cantidad = double.parse(cantidadController.text.isEmpty
            ? bloc.quantitySelected.toString()
            : cantidadController.text);

        print("cantidad: $cantidad");
        bloc.add(SendProductConteoEvent(false, cantidad, bloc.currentProduct));
      }
    } else {
      double cantidad = double.parse(cantidadController.text.isEmpty
          ? bloc.quantitySelected.toString()
          : cantidadController.text);
      print("cantidad: $cantidad");
      bloc.add(SendProductConteoEvent(false, cantidad, bloc.currentProduct));
    }
  }
}
