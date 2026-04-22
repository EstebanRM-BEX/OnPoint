import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';

import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/dropdowbutton_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_temperature_manual_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_temperature_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/shared/widgets/lote_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/product/product_card_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/shared/widgets/scanner_product_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';

class ScanProductOrderScreen extends StatefulWidget {
  const ScanProductOrderScreen({
    super.key,
    required this.ordenCompra,
    required this.currentProduct,
  });

  final ResultEntrada? ordenCompra;
  final LineasTransferencia? currentProduct;

  @override
  State<ScanProductOrderScreen> createState() => _ScanProductOrderScreenState();
}

class _ScanProductOrderScreenState extends State<ScanProductOrderScreen>
    with WidgetsBindingObserver {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  @override
  void initState() {
    super.initState();
    // Añadimos el observer para escuchar el ciclo de vida de la app.
    WidgetsBinding.instance.addObserver(this);
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
        _handleDependencies();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
    }
  }

//focus para escanear

  FocusNode focusNode2 = FocusNode(); // producto
  FocusNode focusNode3 = FocusNode(); // cantidad por pda
  FocusNode focusNode4 = FocusNode(); //cantidad textformfieldƒ
  FocusNode focusNode5 = FocusNode(); //ubicacion destino
  FocusNode focusNode6 = FocusNode(); //lote

  String? selectedLocation;
  String? selectedMuelle;

  //controller
  final TextEditingController _controllerProduct = TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDependencies();
  }

  void _unfocusAll({required FocusNode except}) {
    for (final node in [
      focusNode2,
      focusNode3,
      focusNode4,
      focusNode5,
      focusNode6
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
    debugPrint('🚼 _handleDependencies');

    // No robar foco si hay un dialog u otra ruta encima de esta pantalla
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;

    final bloc = context.read<RecepcionBloc>();

    final hasLote = bloc.currentProduct.productTracking == "lot";
    final configMuelle =
        bloc.configurations.result?.result?.scanDestinationLocationReception ??
            false;

    if (!bloc.productIsOk && !bloc.quantityIsOk) {
      _requestOnly(focusNode2, 'product');
      return;
    }

    if (hasLote) {
      debugPrint('--- CON LOTE ---');
      debugPrint('productIsOk: ${bloc.productIsOk}');
      debugPrint('quantityIsOk: ${bloc.quantityIsOk}');
      debugPrint('loteIsOk: ${bloc.loteIsOk}');
      debugPrint('viewQuantity: ${bloc.viewQuantity}');
      debugPrint('locationsDestIsok: ${bloc.locationsDestIsok}');

      if (bloc.productIsOk &&
          !bloc.loteIsOk &&
          !bloc.quantityIsOk &&
          !bloc.viewQuantity) {
        _requestOnly(focusNode6, 'lote');
        return;
      }

      if (configMuelle) {
        if (bloc.productIsOk && !bloc.quantityIsOk && !bloc.locationsDestIsok) {
          _requestOnly(focusNode5, 'muelle');
          return;
        }
        if (bloc.productIsOk &&
            bloc.quantityIsOk &&
            bloc.locationsDestIsok &&
            !bloc.viewQuantity) {
          _requestOnly(focusNode3, 'quantity');
          return;
        }
      } else {
        if (bloc.productIsOk && !bloc.quantityIsOk && !bloc.viewQuantity) {
          _requestOnly(focusNode3, 'quantity');
          return;
        }
      }
    } else {
      // SIN LOTE
      debugPrint('--- SIN LOTE ---');
      if (configMuelle) {
        if (bloc.productIsOk && !bloc.quantityIsOk && !bloc.locationsDestIsok) {
          _requestOnly(focusNode5, 'muelle');
          return;
        }
        if (bloc.productIsOk &&
            bloc.quantityIsOk &&
            bloc.locationsDestIsok &&
            !bloc.viewQuantity) {
          _requestOnly(focusNode3, 'quantity');
          return;
        }
      } else {
        if (bloc.productIsOk && bloc.quantityIsOk && !bloc.viewQuantity) {
          _requestOnly(focusNode3, 'quantity');
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    focusNode2.dispose(); //product
    focusNode3.dispose(); //quantity
    focusNode4.dispose(); //quantity
    focusNode5.dispose(); //quantity
    focusNode6.dispose(); //quantity
    super.dispose();
  }

  void validateProduct(String value) {
    final bloc = context.read<RecepcionBloc>();

    final scan = value.trim().toLowerCase();

    _controllerProduct.text = "";
    final currentProduct = bloc.currentProduct;

    if (scan == currentProduct.productBarcode?.toLowerCase()) {
      bloc.add(ValidateFieldsOrderEvent(field: "product", isOk: true));
      bloc.add(ChangeQuantitySeparate(
        0,
        int.parse(currentProduct.productId),
        currentProduct.idRecepcion ?? 0,
        currentProduct.idMove ?? 0,
      ));
      bloc.add(ChangeProductIsOkEvent(
        currentProduct.idRecepcion ?? 0,
        true,
        int.parse(currentProduct.productId),
        0,
        currentProduct.idMove ?? 0,
      ));
      Future.microtask(() => focusNode2.requestFocus());
    } else {
      final isok =
          validateScannedBarcode(scan.trim(), bloc.currentProduct, bloc, true);
      if (!isok) {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        bloc.add(ValidateFieldsOrderEvent(field: "product", isOk: false));
        Future.microtask(() => focusNode2.requestFocus());
      }
    }
  }

  void validateLote(String value) {
    final bloc = context.read<RecepcionBloc>();
    final scan = value.trim().toLowerCase();
    debugPrint('scan lote: $scan');
    bloc.loteController.clear();
    //tengo una lista de lotes el cual quiero validar si el scan es igual a alguno de los lotes
    LotesProduct? matchedLote = bloc.listLotesProduct.firstWhere(
        (lotes) => lotes.name?.toLowerCase() == scan.trim(),
        orElse: () =>
            LotesProduct() // Si no se encuentra ningún match, devuelve null
        );

    if (matchedLote.name != null) {
      debugPrint('lote encontrado: ${matchedLote.name}');
      bloc.add(ValidateFieldsOrderEvent(field: "lote", isOk: true));
      bloc.add(SelectecLoteEvent(matchedLote));
      Future.microtask(() => focusNode6.requestFocus());
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      debugPrint('lote no encontrado');
      bloc.add(ValidateFieldsOrderEvent(field: "lote", isOk: false));
      Future.microtask(() => focusNode6.requestFocus());
    }
  }

  void validateQuantity(String value) {
    final bloc = context.read<RecepcionBloc>();
    final scan = value.trim().toLowerCase();

    _controllerQuantity.text = "";
    final currentProduct = bloc.currentProduct;

    if (bloc.quantitySelected == currentProduct.cantidadFaltante) {
      return;
    }
    if (scan == currentProduct.productBarcode?.toLowerCase()) {
      bloc.add(AddQuantitySeparate(
        currentProduct.idRecepcion,
        int.parse(currentProduct.productId),
        currentProduct.idMove ?? 0,
        1,
      ));
      Future.microtask(() => focusNode3.requestFocus());
    } else {
      validateScannedBarcode(scan.trim(), currentProduct, bloc, false);
      Future.microtask(() => focusNode3.requestFocus());
    }
  }

  void validateLocationDest(String value) {
    final bloc = context.read<RecepcionBloc>();
    final currentProduct = bloc.currentProduct;
    final scan = value.trim().toLowerCase();
    debugPrint('scan location: $scan');
    bloc.locationDestController.clear();
    ResultUbicaciones? matchedUbicacion = bloc.ubicaciones.firstWhere(
        (ubicacion) => ubicacion.barcode?.toLowerCase() == scan.trim(),
        orElse: () =>
            ResultUbicaciones() // Si no se encuentra ningún match, devuelve null
        );
    if (matchedUbicacion.barcode != null) {
      debugPrint('Ubicacion encontrada: ${matchedUbicacion.name}');
      bloc.add(ValidateFieldsOrderEvent(field: "locationDest", isOk: true));
      bloc.add(ChangeLocationDestIsOkEvent(
          currentProduct.idRecepcion ?? 0,
          true,
          int.parse(currentProduct.productId),
          currentProduct.idMove ?? 0,
          matchedUbicacion));
      Future.microtask(() => focusNode4.requestFocus());
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      debugPrint('Ubicacion no encontrada');
      bloc.add(ValidateFieldsOrderEvent(field: "locationDest", isOk: false));
      Future.microtask(() => focusNode4.requestFocus());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocBuilder<RecepcionBloc, RecepcionState>(
        builder: (context, state) {
          final recepcionBloc = context.read<RecepcionBloc>();
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                  builder: (context, status) {
                    return Container(
                      padding: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: primaryColorApp,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      width: double.infinity,
                      child: BlocConsumer<RecepcionBloc, RecepcionState>(
                          listener: (context, state) {
                        debugPrint('STATE ❤️‍🔥 $state');

                        if (state is ViewProductImageSuccess) {
                          showImageDialog(context, state.imageUrl);
                        } else if (state is ViewProductImageFailure) {
                          showScrollableErrorDialog(state.error);
                        }

                        if (state is GetTemperatureProduct) {
                          //cerramos el dialogo de envio de producto
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }

                          //validamos que el permiso de enviar imagenes de temperatura este activo
                          if (recepcionBloc.configurations.result?.result
                                  ?.showPhotoTemperature ==
                              true) {
                            showDialog(
                              barrierDismissible:
                                  false, // Evita que se cierre tocando fuera del diálogo
                              context: context,
                              builder: (context) => WillPopScope(
                                onWillPop: () async =>
                                    false, // Evita que se cierre con la flecha de atrás
                                child: DialogCapturaTemperatura(
                                  moveLineId: state.moveLineId,
                                ),
                              ),
                            );
                          } else {
                            showDialog(
                              barrierDismissible:
                                  false, // Evita que se cierre tocando fuera del diálogo
                              context: context,
                              builder: (context) => WillPopScope(
                                onWillPop: () async =>
                                    false, // Evita que se cierre con la flecha de atrás
                                child: DialogTemperaturaManual(
                                  moveLineId: state.moveLineId,
                                ),
                              ),
                            );
                          }
                        }

                        if (state is SendTemperatureSuccess) {
                          //cerramos el dialogo de envio de temperatura
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          Navigator.pushReplacementNamed(context, 'recepcion',
                              arguments: [widget.ordenCompra, 1]);
                        }

                        if (state is SendProductToOrderSuccess) {
                          //cerramos el dialogo
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          Navigator.pushReplacementNamed(context, 'recepcion',
                              arguments: [widget.ordenCompra, 1]);
                        }

                        if (state is SendProductToOrderFailure) {
                          Get.snackbar("360 Software Informa", state.error,
                              backgroundColor: white,
                              colorText: primaryColorApp,
                              icon: Icon(Icons.error, color: Colors.red));
                        }

                        if (state is SendProductToOrderLoading) {
                          showDialog(
                            context: context,
                            builder: (context) => const DialogLoading(
                              message: "Enviando producto...",
                            ),
                          );
                        }

                        //*estado cuando el producto es leido ok
                        if (state is ChangeProductOrderIsOkState) {
                          //pasamos al foco de lote
                          Future.delayed(const Duration(seconds: 1), () {
                            if (!mounted) return; // ← Añade esta verificación
                            if (context
                                    .read<RecepcionBloc>()
                                    .currentProduct
                                    .productTracking ==
                                "lot") {
                              FocusScope.of(context).requestFocus(focusNode6);
                            } else {
                              if (context
                                      .read<RecepcionBloc>()
                                      .configurations
                                      .result
                                      ?.result
                                      ?.scanDestinationLocationReception ==
                                  false) {
                                FocusScope.of(context).requestFocus(focusNode3);
                              } else {
                                FocusScope.of(context).requestFocus(focusNode5);
                              }
                            }
                          });
                          _handleDependencies();
                        }

                        if (state is ChangeLoteOrderIsOkState) {
                          Future.delayed(const Duration(seconds: 1), () {
                            if (context
                                    .read<RecepcionBloc>()
                                    .configurations
                                    .result
                                    ?.result
                                    ?.scanDestinationLocationReception ==
                                false) {
                              FocusScope.of(context).requestFocus(focusNode3);
                            } else {
                              FocusScope.of(context).requestFocus(focusNode5);
                            }
                          });
                          _handleDependencies();
                        }

                        if (state is ChangeLocationDestIsOkState) {
                          //pasamos al foco de lote
                          Future.delayed(const Duration(seconds: 1), () {
                            FocusScope.of(context).requestFocus(focusNode3);
                          });
                          _handleDependencies();
                        }

                        if (state is ChangeQuantitySeparateState) {
                          // if (state.quantity != 0.0) {
                          if (state.quantity ==
                              recepcionBloc.currentProduct.cantidadFaltante) {
                            //termianmso el proceso
                            _finishSeprateProductOrder(context, state.quantity);
                          }
                          // }
                        }
                      }, builder: (context, status) {
                        return Column(
                          children: [
                            const WarningWidgetCubit(),
                            Padding(
                              padding: EdgeInsets.only(
                                  // bottom: 5,
                                  top: status != ConnectionStatus.online
                                      ? 0
                                      : 35),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back,
                                        color: white),
                                    onPressed: () {
                                      termiateProcess();

                                      Navigator.pushReplacementNamed(
                                          context, 'recepcion',
                                          arguments: [widget.ordenCompra, 1]);
                                    },
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: size.width * 0.2),
                                    child: Text(widget.ordenCompra?.name ?? '',
                                        style: TextStyle(
                                            color: white, fontSize: 18)),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      ModalPrintersList.show(context,
                                          resId: recepcionBloc
                                              .currentProduct.idMove,
                                          companyId:
                                              widget.ordenCompra?.warehouseId ??
                                                  1);
                                    },
                                    child: Icon(
                                      Icons.print,
                                      color: white,
                                      size: 25,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
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
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
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
                                        top: 10,
                                        bottom: 10),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Ubicación de origen',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                            const Spacer(),
                                            Image.asset(
                                              "assets/icons/ubicacion.png",
                                              color: primaryColorApp,
                                              width: 20,
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Text(
                                                recepcionBloc.currentProduct
                                                        .locationName ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 14, color: black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )),
                              ),
                            ],
                          ),

                          // todo: Producto

                          ProductScannerWidget(
                            isProductOk: recepcionBloc.isProductOk,
                            productIsOk: recepcionBloc.productIsOk,
                            locationIsOk: true,
                            quantityIsOk: recepcionBloc.quantityIsOk,
                            locationDestIsOk: recepcionBloc.locationsDestIsok,
                            currentProductId: recepcionBloc
                                .currentProduct.productName
                                .toString(),
                            barcode:
                                recepcionBloc.currentProduct.productBarcode,
                            lotId: recepcionBloc.currentProduct.lotName,
                            expireDate:
                                recepcionBloc.currentProduct.fechaVencimiento,
                            size: size,
                            onValidateProduct: (value) {
                              validateProduct(value); // tu función actual
                            },
                            onKeyScanned: (keyLabel) {},
                            focusNode: focusNode2,
                            controller: _controllerProduct,
                            productDropdown: ProductDropdownOrderWidget(
                              selectedProduct: selectedLocation,
                              listOfProductsName:
                                  recepcionBloc.listOfProductsName,
                              currentProductId:
                                  (recepcionBloc.currentProduct.productId ?? 0)
                                      .toString(),
                              currentProduct: recepcionBloc.currentProduct,
                              isPDA: false,
                            ),
                            origin: '',
                            expiryWidget: Container(),
                            listOfBarcodes: recepcionBloc.listOfBarcodes,
                            onBarcodesDialogTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return DialogBarcodes(
                                      listOfBarcodes:
                                          recepcionBloc.listOfBarcodes);
                                },
                              );
                            },
                            onViewImgProduct: () {
                              recepcionBloc.add(ViewProductImageEvent(int.parse(
                                  recepcionBloc.currentProduct.productId)));
                            },
                          ),

                          //todo: lotes

                          Visibility(
                            visible:
                                recepcionBloc.currentProduct.productTracking ==
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
                                      color: recepcionBloc.loteIsOk
                                          ? green
                                          : yellow,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Card(
                                  color: recepcionBloc.isLoteOk
                                      ? recepcionBloc.loteIsOk
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
                                                    Navigator
                                                        .pushReplacementNamed(
                                                      context,
                                                      'new-lote',
                                                      arguments: [
                                                        widget.ordenCompra,
                                                        widget.currentProduct
                                                      ],
                                                    );
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
                                              LoteScannerWidget(
                                                controller: recepcionBloc
                                                    .loteController,
                                                focusNode: focusNode6,
                                                enabled: recepcionBloc
                                                        .productIsOk && //true
                                                    !recepcionBloc
                                                        .loteIsOk && //false
                                                    !recepcionBloc
                                                        .quantityIsOk && //false
                                                    !recepcionBloc.viewQuantity,
                                                hintText: recepcionBloc
                                                                .lotesProductCurrent
                                                                .name ==
                                                            "" ||
                                                        recepcionBloc
                                                                .lotesProductCurrent
                                                                .name ==
                                                            null
                                                    ? 'Esperando escaneo'
                                                    : recepcionBloc
                                                            .lotesProductCurrent
                                                            .name ??
                                                        "",
                                                onValidateLote: validateLote,
                                              ),
                                              ExpirationBadgeWidget(
                                                expirationDate: recepcionBloc
                                                    .lotesProductCurrent
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

                          //todo: ubicacion destino FIJA

                          (recepcionBloc.configurations.result?.result
                                      ?.scanDestinationLocationReception ==
                                  false)
                              ? Row(
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
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacementNamed(
                                            context, 'search-location-recep',
                                            arguments: [
                                              widget.ordenCompra,
                                              widget.currentProduct,
                                            ]);
                                      },
                                      child: Card(
                                        color: Colors.green[100],
                                        elevation: 5,
                                        child: Container(
                                            // color: Colors.amber,
                                            width: size.width * 0.85,
                                            padding: const EdgeInsets.only(
                                                left: 10,
                                                right: 10,
                                                top: 10,
                                                bottom: 10),
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
                                                    SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: SvgPicture.asset(
                                                        color: primaryColorApp,
                                                        "assets/icons/packing.svg",
                                                        height: 20,
                                                        width: 20,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        recepcionBloc
                                                                .currentProduct
                                                                .locationDestName ??
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
                                    ),
                                  ],
                                )
                              :

                              //todo : ubicacion destino DINAMICA
                              Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: recepcionBloc.locationsDestIsok
                                              ? green
                                              : yellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Card(
                                      color: recepcionBloc.isLocationDestOk
                                          ? recepcionBloc.locationsDestIsok
                                              ? Colors.green[100]
                                              : Colors.grey[300]
                                          : Colors.red[200],
                                      elevation: 5,
                                      child: Container(
                                          // color: Colors.amber,
                                          width: size.width * 0.85,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 2),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: !recepcionBloc
                                                              .locationsDestIsok && //false
                                                          recepcionBloc
                                                              .productIsOk && //false
                                                          !recepcionBloc
                                                              .quantityIsOk
                                                      ? () {
                                                          Navigator
                                                              .pushReplacementNamed(
                                                                  context,
                                                                  'search-location-recep',
                                                                  arguments: [
                                                                widget
                                                                    .ordenCompra,
                                                                widget
                                                                    .currentProduct
                                                              ]);
                                                        }
                                                      : null,
                                                  child: Row(
                                                    children: [
                                                      Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          'Ubicación destino',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Image.asset(
                                                        "assets/icons/ubicacion.png",
                                                        color: primaryColorApp,
                                                        width: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                BarcodeScannerField(
                                                  controller: recepcionBloc
                                                      .locationDestController,
                                                  focusNode: focusNode5,
                                                  onBarcodeScanned:
                                                      (value, context) {
                                                    return validateLocationDest(
                                                      value,
                                                    );
                                                  },
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      recepcionBloc.currentUbicationDest
                                                                      ?.name ==
                                                                  "" ||
                                                              recepcionBloc
                                                                      .currentUbicationDest
                                                                      ?.name ==
                                                                  null
                                                          ? 'Esperando escaneo'
                                                          : recepcionBloc
                                                                  .currentUbicationDest
                                                                  ?.name ??
                                                              "",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: black)),
                                                )
                                              ],
                                            ),
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
                SizedBox(
                  width: size.width,
                  height: !recepcionBloc.viewQuantity ? 110 : 150,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Card(
                          color: recepcionBloc.isQuantityOk
                              ? recepcionBloc.quantityIsOk
                                  ? white
                                  : Colors.grey[300]
                              : Colors.red[200],
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  //*mostramos la cantidad a recoger si la configuracion lo permite
                                  Visibility(
                                    visible: recepcionBloc.configurations.result
                                            ?.result?.hideExpectedQty ==
                                        false,
                                    child: Row(
                                      children: [
                                        const Text('Recoger:',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14)),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Text(
                                              recepcionBloc.currentProduct
                                                      .cantidadFaltante
                                                      ?.toString() ??
                                                  "",
                                              style: TextStyle(
                                                color: primaryColorApp,
                                                fontSize: 14,
                                              ),
                                            )),
                                        Text(
                                            recepcionBloc.currentProduct.uom ??
                                                "",
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),

                                  const Spacer(),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: BarcodeScannerField(
                                              controller: _controllerQuantity,
                                              focusNode: focusNode3,
                                              onBarcodeScanned:
                                                  (value, context) {
                                                validateQuantity(value);
                                              },
                                            ),
                                          ),
                                          Text(
                                              recepcionBloc.quantitySelected
                                                  .toString(),
                                              style: const TextStyle(
                                                  color: black, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: recepcionBloc.quantityIsOk &&
                                              recepcionBloc.quantitySelected >=
                                                  0
                                          ? () {
                                              debugPrint('press');
                                              recepcionBloc.add(
                                                  ShowQuantityOrderEvent(
                                                      !recepcionBloc
                                                          .viewQuantity));
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 100), () {
                                                FocusScope.of(context)
                                                    .requestFocus(focusNode4);
                                              });
                                            }
                                          : null,
                                      icon: Icon(Icons.edit_note_rounded,
                                          color: primaryColorApp, size: 30)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: recepcionBloc.viewQuantity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          child: SizedBox(
                            height: 40,
                            child: TextFormField(
                              //tmano del campo

                              focusNode: focusNode4,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                              showCursor: true,
                              onChanged: (value) {
                                // Verifica si el valor no está vacío y si es un número válido
                                if (value.isNotEmpty) {
                                  try {
                                    recepcionBloc.quantitySelected =
                                        int.parse(value);
                                  } catch (e) {
                                    // Manejo de errores si la conversión falla
                                    debugPrint(
                                        'Error al convertir a entero: $e');
                                    // Aquí puedes mostrar un mensaje al usuario o manejar el error de otra forma
                                  }
                                } else {
                                  // Si el valor está vacío, puedes establecer un valor por defecto
                                  recepcionBloc.quantitySelected =
                                      0; // O cualquier valor que consideres adecuado
                                }
                              },
                              controller: _cantidadController,
                              keyboardType: TextInputType.number,

                              decoration: InputDecorations.authInputDecoration(
                                hintText: 'Cantidad',
                                labelText: 'Cantidad',
                                suffixIconButton: IconButton(
                                  onPressed: () {
                                    recepcionBloc.add(ShowQuantityOrderEvent(
                                        !recepcionBloc.viewQuantity));
                                    _cantidadController.clear();
                                    //cambiamos el foco pa leer por pda la cantidad
                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      FocusScope.of(context)
                                          .requestFocus(focusNode3);
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: ElevatedButton(
                            onPressed: recepcionBloc.quantityIsOk &&
                                    recepcionBloc.quantitySelected >= 0
                                ? () {
                                    //cerramos el teclado
                                    FocusScope.of(context).unfocus();
                                    _validatebuttonquantity();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColorApp,
                              minimumSize: Size(size.width * 0.93, 35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'APLICAR CANTIDAD',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool validateScannedBarcode(
      String scannedBarcode,
      LineasTransferencia currentProduct,
      RecepcionBloc batchBloc,
      bool isProduct) {
    // Buscar el barcode que coincida con el valor escaneado
    Barcodes? matchedBarcode = context
        .read<RecepcionBloc>()
        .listOfBarcodes
        .firstWhere(
            (barcode) =>
                barcode.barcode?.toLowerCase() == scannedBarcode.trim(),
            orElse: () =>
                Barcodes() // Si no se encuentra ningún match, devuelve null
            );
    if (matchedBarcode.barcode != null) {
      if (isProduct) {
        batchBloc.add(ValidateFieldsOrderEvent(field: "product", isOk: true));

        batchBloc.add(ChangeQuantitySeparate(
          0,
          int.parse(currentProduct.productId),
          currentProduct.idRecepcion ?? 0,
          currentProduct.idMove ?? 0,
        ));

        batchBloc.add(ChangeProductIsOkEvent(
            currentProduct.idRecepcion ?? 0,
            true,
            int.parse(currentProduct.productId),
            0,
            currentProduct.idMove ?? 0));

        batchBloc.add(ChangeIsOkQuantity(
          currentProduct.idRecepcion ?? 0,
          true,
          int.parse(currentProduct.productId),
          currentProduct.idMove ?? 0,
        ));

        return true;
      } else {
        //valisamos si la suma de la cantidad del paquete es correcta con lo que se pide
        if (matchedBarcode.cantidad + batchBloc.quantitySelected >
            currentProduct.cantidadFaltante!) {
          _audioService.playErrorSound();
          _vibrationService.vibrate();
          return false;
        }

        batchBloc.add(AddQuantitySeparate(
          currentProduct.idRecepcion,
          int.parse(currentProduct.productId),
          currentProduct.idMove ?? 0,
          matchedBarcode.cantidad,
        ));
      }
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      return false;
    }
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    return false;
  }

  void _validatebuttonquantity() {
    final batchBloc = context.read<RecepcionBloc>();
    final currentProduct = batchBloc.currentProduct;

    //validamos que tengamos un lote seleccionado

    if (currentProduct.productTracking == 'lot') {
      if (context.read<RecepcionBloc>().lotesProductCurrent.id == null) {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        Get.snackbar(
          'Error',
          "Seleccione un lote",
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: Icon(Icons.error, color: Colors.amber),
        );
        return;
      }
    }

    if (batchBloc
            .configurations.result?.result?.scanDestinationLocationReception ==
        true) {
      if (context.read<RecepcionBloc>().currentUbicationDest?.id == null) {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        Get.snackbar(
          'Error',
          "Seleccione o escanee una ubicacion",
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: Icon(Icons.error, color: Colors.amber),
        );
        return;
      }
    }

    // double cantidad = double.parse(_cantidadController.text.isEmpty
    //     ? batchBloc.quantitySelected.toString()
    //     : _cantidadController.text);

    String input = _cantidadController.text.trim();

    // Si está vacío, usar la cantidad seleccionada del bloc
    if (input.isEmpty) {
      input = batchBloc.quantitySelected.toString();
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

    if (cantidad == currentProduct.cantidadFaltante) {
      batchBloc.add(ChangeQuantitySeparate(
          cantidad,
          int.parse(currentProduct.productId),
          currentProduct.idRecepcion ?? 0,
          currentProduct.idMove ?? 0));
    } else {
      FocusScope.of(context).unfocus();

      if (cantidad < (currentProduct.cantidadFaltante ?? 0)) {
        showDialog(
            context: context,
            builder: (context) {
              return DialogOrderAdvetenciaCantidadScreen(
                  currentProduct: currentProduct,
                  cantidad: cantidad,
                  onAccepted: () async {
                    batchBloc.add(ChangeQuantitySeparate(
                        cantidad,
                        int.parse(currentProduct.productId),
                        currentProduct.idRecepcion ?? 0,
                        currentProduct.idMove ?? 0));
                    _cantidadController.clear();
                    _finishSeprateProductOrder(context, cantidad);
                  },
                  onSplit: () {
                    batchBloc.add(ChangeQuantitySeparate(
                        cantidad,
                        int.parse(currentProduct.productId),
                        currentProduct.idRecepcion ?? 0,
                        currentProduct.idMove ?? 0));
                    _cantidadController.clear();

                    _finishSeprateProductOrderSplit(context, cantidad);
                  });
            });
      } else if (cantidad > (currentProduct.cantidadFaltante ?? 0)) {
        //validamos si tiene el permiso de mover mas de lo planteado

        if (batchBloc.configurations.result?.result?.allowMoveExcess == true) {
          batchBloc.add(ChangeQuantitySeparate(
              cantidad,
              int.parse(currentProduct.productId),
              currentProduct.idRecepcion ?? 0,
              currentProduct.idMove ?? 0));

          _finishSeprateProductOrder(context, cantidad);
        } else {
          _audioService.playErrorSound();
          _vibrationService.vibrate();
          Get.snackbar(
            'Error',
            "No tiene el permiso de mover mas de lo planteado",
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.red),
          );
        }
      }
    }
  }

  void _finishSeprateProductOrder(BuildContext context, dynamic cantidad) {
    if (context.read<RecepcionBloc>().currentProduct.productTracking == "lot") {
      if (context.read<RecepcionBloc>().selectLote == "") {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        Get.snackbar(
          'Error',
          "Seleccione un lote",
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: Icon(Icons.error, color: Colors.amber),
        );
        return;
      }
    }

    context.read<RecepcionBloc>().add(FinalizarRecepcionProducto());
    context.read<RecepcionBloc>().add(SendProductToOrder(false, cantidad));
    termiateProcess();
  }

  void _finishSeprateProductOrderSplit(
    BuildContext context,
    dynamic cantidad,
  ) {
    if (context.read<RecepcionBloc>().currentProduct.productTracking == "lot") {
      if (context.read<RecepcionBloc>().currentProduct.loteId == "") {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        Get.snackbar(
          'Error',
          "Seleccione un lote",
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: Icon(Icons.error, color: Colors.amber),
        );
        return;
      }
    }
    context
        .read<RecepcionBloc>()
        .add(FinalizarRecepcionProductoSplit(cantidad));
    context.read<RecepcionBloc>().add(SendProductToOrder(true, cantidad));
    termiateProcess();
  }

  void termiateProcess() {
    FocusScope.of(context).unfocus();

    context.read<RecepcionBloc>().add(CleanFieldsEvent());
    context.read<RecepcionBloc>().add(GetPorductsToEntrada(
        widget.ordenCompra?.id ?? 0,
        widget.ordenCompra?.type == 'dev' ? 'dev' : 'reception'));
  }
}
