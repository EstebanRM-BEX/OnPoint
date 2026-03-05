import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/scanner_location_widget.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';

import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/dropdowbutton_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/location/location_card_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/others/dialog_temperature_manual_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/others/dialog_temperature_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/product/product_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/shared/widgets/scanner_product_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({
    super.key,
    this.packingModel,
    this.batchModel,
  });

  final PedidoPacking? packingModel;
  final BatchPackingModel? batchModel;

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  FocusNode focusNode1 = FocusNode(); // ubicacion  de origen
  FocusNode focusNode2 = FocusNode(); // producto
  FocusNode focusNode3 = FocusNode(); // cantidad por pda
  FocusNode focusNode4 = FocusNode(); //cantidad textformfield

  String? selectedLocation;

  //controller
  final TextEditingController _controllerLocation = TextEditingController();
  final TextEditingController _controllerProduct = TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDependencies();
  }

  void _handleDependencies() {
    final batchBloc = context.read<WmsPackingBloc>();
    if (!batchBloc.locationIsOk && //false
        !batchBloc.productIsOk && //false
        !batchBloc.quantityIsOk && //false
        !batchBloc.locationDestIsOk) //false
    {
      debugPrint('❤️‍🔥 location');
      FocusScope.of(context).requestFocus(focusNode1);
      focusNode2.unfocus();
      focusNode3.unfocus();
      focusNode4.unfocus();
    }
    if (batchBloc.locationIsOk && //true
        !batchBloc.productIsOk && //false
        !batchBloc.quantityIsOk && //false
        !batchBloc.locationDestIsOk) //false
    {
      debugPrint('❤️‍🔥 product');
      FocusScope.of(context).requestFocus(focusNode2);
      focusNode1.unfocus();
      focusNode3.unfocus();
      focusNode4.unfocus();
    }
    if (batchBloc.locationIsOk && //true
        batchBloc.productIsOk && //true
        batchBloc.quantityIsOk && //ttrue
        !batchBloc.locationDestIsOk && //false
        !batchBloc.viewQuantity) //false
    {
      debugPrint('❤️‍🔥 quantity');
      FocusScope.of(context).requestFocus(focusNode3);
      focusNode1.unfocus();
      focusNode2.unfocus();
      focusNode4.unfocus();
    }
  }

  @override
  void dispose() {
    focusNode1.dispose();
    focusNode2.dispose();
    focusNode3.dispose();
    focusNode4.dispose();
    super.dispose();
  }

  void validateLocation(String value) {
    final batchBloc = context.read<WmsPackingBloc>();

    final scan = value.trim().toLowerCase();

    _controllerLocation.text = "";
    final currentProduct = batchBloc.currentProduct;
    if (scan == currentProduct.barcodeLocation.toString().toLowerCase()) {
      batchBloc.add(ValidateFieldsPackingEvent(field: "location", isOk: true));
      batchBloc.add(ChangeLocationIsOkEvent(currentProduct.idProduct ?? 0,
          currentProduct.pedidoId ?? 0, currentProduct.idMove ?? 0));
      Future.microtask(() => focusNode1.requestFocus());
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      batchBloc.add(ValidateFieldsPackingEvent(field: "location", isOk: false));
      Future.microtask(() => focusNode1.requestFocus());
    }
  }

  void validateProduct(String value) {
    final batchBloc = context.read<WmsPackingBloc>();

    final scan = value.trim().toLowerCase();

    _controllerProduct.text = "";
    final currentProduct = batchBloc.currentProduct;

    if (scan == currentProduct.barcode?.toLowerCase()) {
      batchBloc.add(ValidateFieldsPackingEvent(field: "product", isOk: true));

      batchBloc.add(ChangeQuantitySeparate(0, currentProduct.idProduct ?? 0,
          currentProduct.pedidoId ?? 0, currentProduct.idMove ?? 0));
      batchBloc.add(ChangeProductIsOkEvent(true, currentProduct.idProduct ?? 0,
          currentProduct.pedidoId ?? 0, 0, currentProduct.idMove ?? 0));
      batchBloc.add(ChangeIsOkQuantity(true, currentProduct.idProduct ?? 0,
          currentProduct.pedidoId ?? 0, currentProduct.idMove ?? 0));
      Future.microtask(() => focusNode2.requestFocus());
    } else {
      final isok = validateScannedBarcode(
          scan, batchBloc.currentProduct, batchBloc, true);
      if (!isok) {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        batchBloc
            .add(ValidateFieldsPackingEvent(field: "product", isOk: false));
        Future.microtask(() => focusNode2.requestFocus());
      }
    }
  }

  void validateQuantity(String value) {
    final batchBloc = context.read<WmsPackingBloc>();

    final scan = value.trim().toLowerCase();

    _controllerQuantity.text = "";
    final currentProduct = batchBloc.currentProduct;
    if (scan == currentProduct.barcode?.toLowerCase()) {
      batchBloc.add(AddQuantitySeparate(1, currentProduct.idMove ?? 0,
          currentProduct.idProduct ?? 0, currentProduct.pedidoId ?? 0));
      Future.microtask(() => focusNode3.requestFocus());
    } else {
      validateScannedBarcode(scan, batchBloc.currentProduct, batchBloc, false);
      Future.microtask(() => focusNode3.requestFocus());
    }
  }

  bool validateScannedBarcode(String scannedBarcode,
      ProductoPedido currentProduct, WmsPackingBloc batchBloc, bool isProduct) {
    // Buscar el barcode que coincida con el valor escaneado
    Barcodes? matchedBarcode = context
        .read<WmsPackingBloc>()
        .listOfBarcodes
        .firstWhere(
            (barcode) =>
                barcode.barcode?.toLowerCase() == scannedBarcode.trim(),
            orElse: () =>
                Barcodes() // Si no se encuentra ningún match, devuelve null
            );
    if (matchedBarcode.barcode != null) {
      if (isProduct) {
        batchBloc.add(ValidateFieldsPackingEvent(field: "product", isOk: true));

        batchBloc.add(ChangeQuantitySeparate(0, currentProduct.idProduct ?? 0,
            currentProduct.pedidoId ?? 0, currentProduct.idMove ?? 0));

        batchBloc.add(ChangeProductIsOkEvent(
            true,
            currentProduct.idProduct ?? 0,
            currentProduct.pedidoId ?? 0,
            0,
            currentProduct.idMove ?? 0));

        batchBloc.add(ChangeIsOkQuantity(true, currentProduct.idProduct ?? 0,
            currentProduct.pedidoId ?? 0, currentProduct.idMove ?? 0));

        return true;
      } else {
        //valisamos si la suma de la cantidad del paquete es correcta con lo que se pide
        if ((matchedBarcode.cantidad + batchBloc.quantitySelected) >
            currentProduct.quantity!) {
          _audioService.playErrorSound();
          _vibrationService.vibrate();
          return false;
        }
        batchBloc.add(AddQuantitySeparate(
            matchedBarcode.cantidad,
            currentProduct.idMove ?? 0,
            currentProduct.idProduct ?? 0,
            currentProduct.pedidoId ?? 0));
      }
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      return false;
    }
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocBuilder<WmsPackingBloc, WmsPackingState>(
        builder: (context, state) {
          final packingBloc = context.read<WmsPackingBloc>();

          return Scaffold(
              backgroundColor: Colors.white,
              body: Column(
                children: [
                  //*barra de informacion
                  BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                    builder: (context, status) {
                      return Container(
                        width: size.width,
                        color: primaryColorApp,
                        child: BlocConsumer<WmsPackingBloc, WmsPackingState>(
                          listener: (context, state) {
                            debugPrint('❤️‍🔥 state: $state ');

                            if (state is ViewProductImageSuccess) {
                              showImageDialog(context, state.imageUrl);
                            } else if (state is ViewProductImageFailure) {
                              showScrollableErrorDialog(state.error);
                            }

                            if (state is ChangeQuantitySeparateState) {
                              if (state.quantity ==
                                  packingBloc.currentProduct.quantity) {
                                _finichPackingProduct(context);
                              }
                            }

                            if (state is SetPickingPackingLoadingState) {
                              showDialog(
                                context: context,
                                builder: (context) => const DialogLoading(
                                  message: "Separando producto...",
                                ),
                              );
                            }

                            if (state is SetPickingPackingOkState) {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }

                              //validamos si el producto maneja temperatura
                              if (packingBloc
                                          .currentProduct.manejaTemperatura ==
                                      1 ||
                                  packingBloc
                                          .currentProduct.manejaTemperatura ==
                                      true) {
                                if (packingBloc.configurations.result?.result
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
                                        moveLineId:
                                            packingBloc.currentProduct.idMove ??
                                                0,
                                      ),
                                    ),
                                  );

                                  return;
                                } else {
                                  showDialog(
                                    barrierDismissible:
                                        false, // Evita que se cierre tocando fuera del diálogo
                                    context: context,
                                    builder: (context) => WillPopScope(
                                      onWillPop: () async =>
                                          false, // Evita que se cierre con la flecha de atrás
                                      child: DialogTemperaturaManualPacking(
                                        moveLineId:
                                            packingBloc.currentProduct.idMove ??
                                                0,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              Navigator.pushReplacementNamed(
                                context,
                                'packing-detail',
                                arguments: [
                                  widget.packingModel,
                                  widget.batchModel,
                                  1
                                ],
                              );
                            }

                            if (state is SendTemperatureSuccess) {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              Navigator.pushReplacementNamed(
                                context,
                                'packing-detail',
                                arguments: [
                                  widget.packingModel,
                                  widget.batchModel,
                                  1
                                ],
                              );
                            }

                            if (state is SendTemperatureFailure) {
                              Navigator.pop(context);
                              showScrollableErrorDialog(state.error);
                            }

                            if (state is SendImageNovedadSuccess) {
                              packingBloc.add(ChangeQuantitySeparate(
                                  state.cantidad,
                                  packingBloc.currentProduct.idProduct ?? 0,
                                  packingBloc.currentProduct.pedidoId ?? 0,
                                  packingBloc.currentProduct.idMove ?? 0));
                              cantidadController.clear();
                              _finichPackingProduct(context);
                            }

                            if (state is ChangeLocationPackingIsOkState) {
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted) {
                                  FocusScope.of(context)
                                      .requestFocus(focusNode2);
                                }
                              });
                              _handleDependencies();
                            }

                            if (state is ChangeProductPackingIsOkState) {
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted) {
                                  FocusScope.of(context)
                                      .requestFocus(focusNode3);
                                }
                              });
                              _handleDependencies();
                            }
                          },
                          builder: (context, state) {
                            return Column(
                              children: [
                                const WarningWidgetCubit(),
                                Padding(
                                  padding: const EdgeInsets.only(top: 25),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          packingBloc.quantitySelected = 0;
                                          cantidadController.clear();
                                          packingBloc.oldLocation = "";

                                          context.read<WmsPackingBloc>().add(
                                                  LoadAllProductsFromPedidoEvent(
                                                packingBloc.currentProduct
                                                        .pedidoId ??
                                                    0,
                                              ));
                                          Navigator.pushReplacementNamed(
                                            context,
                                            'packing-detail',
                                            arguments: [
                                              widget.packingModel,
                                              widget.batchModel,
                                              1
                                            ],
                                          );
                                        },
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.white, size: 30),
                                      ),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Center(
                                          child: Text(
                                            "Certificación de Packing",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Form(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              //todo : ubicacion de origen

                              LocationScannerWidget(
                                isLocationOk: packingBloc.isLocationOk,
                                locationIsOk: packingBloc.locationIsOk,
                                productIsOk: packingBloc.productIsOk,
                                quantityIsOk: packingBloc.quantityIsOk,
                                locationDestIsOk: packingBloc.locationDestIsOk,
                                currentLocationId: packingBloc
                                    .currentProduct.locationId
                                    .toString(),
                                onValidateLocation: (value) {
                                  validateLocation(value);
                                },
                                onKeyScanned: (keyLabel) {},
                                focusNode: focusNode1,
                                controller: _controllerLocation,
                                locationDropdown: LocationPackingDropdownWidget(
                                  isPDA: true,
                                  selectedLocation: selectedLocation,
                                  positionsOrigen:
                                      packingBloc.currentProduct.locationId,
                                  currentLocationId: packingBloc
                                      .currentProduct.locationId
                                      .toString(),
                                  batchBloc: packingBloc,
                                  currentProduct: packingBloc.currentProduct,
                                ),
                              ),

                              // todo: Producto

                              ProductScannerWidget(
                                isProductOk: packingBloc.isProductOk,
                                productIsOk: packingBloc.productIsOk,
                                locationIsOk: packingBloc.locationIsOk,
                                quantityIsOk: packingBloc.quantityIsOk,
                                locationDestIsOk: packingBloc.locationDestIsOk,
                                currentProductId: packingBloc
                                    .currentProduct.productId
                                    .toString(),
                                barcode: packingBloc.currentProduct.barcode,
                                lotId: packingBloc.currentProduct.lotId,
                                origin: '',
                                expireDate:
                                    packingBloc.currentProduct.expireDate,
                                size: size,
                                onValidateProduct: (value) {
                                  validateProduct(value); // tu función actual
                                },
                                onKeyScanned: (keyLabel) {},
                                focusNode: focusNode2,
                                controller: _controllerProduct,
                                productDropdown: ProductDropdownPackingWidget(
                                  selectedProduct: selectedLocation,
                                  listOfProductsName:
                                      packingBloc.listOfProductsName,
                                  currentProductId: packingBloc
                                      .currentProduct.idProduct
                                      .toString(),
                                  batchBloc: packingBloc,
                                  currentProduct: packingBloc.currentProduct,
                                  isPDA: false,
                                ),
                                expiryWidget: ExpirationBadgeWidget(
                                  expirationDate:
                                      packingBloc.currentProduct?.expireDate,
                                ),
                                listOfBarcodes: packingBloc.listOfBarcodes,
                                onBarcodesDialogTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return DialogBarcodes(
                                          listOfBarcodes:
                                              packingBloc.listOfBarcodes);
                                    },
                                  );
                                },
                                onViewImgProduct: () {
                                  packingBloc.add(ViewProductImageEvent(
                                      packingBloc.currentProduct.idProduct ??
                                          0));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  //todo: cantidad
                  SizedBox(
                    width: size.width,
                    height: packingBloc.viewQuantity == true &&
                            context
                                .read<UserBloc>()
                                .fabricante
                                .contains("Zebra")
                        ? 345
                        : !packingBloc.viewQuantity
                            ? 110
                            : 150,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: Card(
                            color: packingBloc.isQuantityOk
                                ? packingBloc.quantityIsOk
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
                                    const Text('Recoger:',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 14)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          (packingBloc.currentProduct
                                                      .quantity ??
                                                  0.0)
                                              .toString(),
                                          style: TextStyle(
                                            color: primaryColorApp,
                                            fontSize: 14,
                                          ),
                                        )),
                                    Text(
                                        packingBloc.currentProduct.unidades ??
                                            "",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 14)),
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
                                                packingBloc.quantitySelected
                                                    .toString(),
                                                style: const TextStyle(
                                                    color: black,
                                                    fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                        onPressed: packingBloc
                                                    .configurations
                                                    .result
                                                    ?.result
                                                    ?.manualQuantityPack ==
                                                false
                                            ? null
                                            : packingBloc.quantityIsOk &&
                                                    packingBloc
                                                            .quantitySelected >=
                                                        0
                                                ? () {
                                                    packingBloc.add(
                                                        ShowQuantityPackEvent(
                                                            !packingBloc
                                                                .viewQuantity));
                                                    Future.delayed(
                                                        const Duration(
                                                            milliseconds: 100),
                                                        () {
                                                      if (mounted) {
                                                        FocusScope.of(context)
                                                            .requestFocus(
                                                                focusNode4);
                                                      }
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
                          visible: packingBloc.viewQuantity,
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
                                      packingBloc.quantitySelected =
                                          double.parse(value);
                                    } catch (e) {
                                      // Manejo de errores si la conversión falla
                                      debugPrint(
                                          'Error al convertir a entero: $e');
                                      // Aquí puedes mostrar un mensaje al usuario o manejar el error de otra forma
                                    }
                                  } else {
                                    // Si el valor está vacío, puedes establecer un valor por defecto
                                    packingBloc.quantitySelected =
                                        0; // O cualquier valor que consideres adecuado
                                  }
                                },
                                controller: cantidadController,
                                keyboardType: TextInputType.number,
                                decoration:
                                    InputDecorations.authInputDecoration(
                                  hintText: 'Cantidad',
                                  labelText: 'Cantidad',
                                  suffixIconButton: IconButton(
                                    onPressed: () {
                                      packingBloc.add(ShowQuantityPackEvent(
                                          !packingBloc.viewQuantity));
                                      cantidadController.clear();
                                      //cambiamos el foco pa leer por pda la cantidad
                                      Future.delayed(
                                          const Duration(milliseconds: 100),
                                          () {
                                        if (mounted) {
                                          FocusScope.of(context)
                                              .requestFocus(focusNode3);
                                        }
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
                              onPressed: packingBloc.quantityIsOk &&
                                      packingBloc.quantitySelected >= 0
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
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ));
        },
      ),
    );
  }

  void _finichPackingProduct(BuildContext context) async {
    //cerramos el foco
    FocusScope.of(context).unfocus();
    //marcamos el producto como terminado

    final batchBloc = context.read<WmsPackingBloc>();
    batchBloc.add(SetPickingsEvent(
        batchBloc.currentProduct.idProduct ?? 0,
        batchBloc.currentProduct.pedidoId ?? 0,
        batchBloc.currentProduct.idMove ?? 0));
  }

  void _finichPackingProductSplit(BuildContext context, double cantidad) async {
    //marcamos el producto como terminado
    debugPrint('Entramos a _finichPackingProductSplit -----');
    final batchBloc = context.read<WmsPackingBloc>();

    batchBloc.add(SetPickingSplitEvent(
      batchBloc.currentProduct,
      batchBloc.currentProduct.idMove ?? 0,
      cantidad,
      batchBloc.currentProduct.idProduct ?? 0,
      batchBloc.currentProduct.pedidoId ?? 0,
    ));

    batchBloc.add(
        LoadAllProductsFromPedidoEvent(batchBloc.currentProduct.pedidoId ?? 0));
  }

  void _validatebuttonquantity() {
    final batchBloc = context.read<WmsPackingBloc>();
    final currentProduct = batchBloc.currentProduct;

    String input = cantidadController.text.trim();

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

    double cantidad = double.parse(cantidadController.text.isEmpty
        ? batchBloc.quantitySelected.toString()
        : cantidadController.text);

    if (cantidad == currentProduct.quantity) {
      batchBloc.add(ChangeQuantitySeparate(
          cantidad,
          currentProduct.idProduct ?? 0,
          currentProduct.pedidoId ?? 0,
          currentProduct.idMove ?? 0));
    } else {
      FocusScope.of(context).unfocus();
      if (cantidad < (currentProduct.quantity ?? 0)) {
        showDialog(
            context: context,
            builder: (context) {
              return DialogPackingAdvetenciaCantidadScreen(
                  currentProduct: currentProduct,
                  cantidad: cantidad,
                  onAccepted: () async {
                    batchBloc.add(ChangeQuantitySeparate(
                        cantidad,
                        currentProduct.idProduct ?? 0,
                        currentProduct.pedidoId ?? 0,
                        currentProduct.idMove ?? 0));
                    cantidadController.clear();
                    _finichPackingProduct(context);
                  },
                  onSplit: () {
                    batchBloc.add(ChangeQuantitySeparate(
                        cantidad,
                        currentProduct.idProduct ?? 0,
                        currentProduct.pedidoId ?? 0,
                        currentProduct.idMove ?? 0));
                    cantidadController.clear();
                    _finichPackingProductSplit(context, cantidad);
                  });
            });
      } else {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: const Text('Cantidad erronea'),
          backgroundColor: Colors.red[200],
        ));
      }
    }
  }
}
