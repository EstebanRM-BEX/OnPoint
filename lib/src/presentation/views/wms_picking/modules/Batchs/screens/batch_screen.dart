// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print, unrelated_type_equality_checks, unnecessary_null_comparison, unused_element, sort_child_properties_last, no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/sounds_utils.dart';
import 'package:wms_app/src/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/location/location_dropdown_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/muelle/Scanner_locationDest_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/muelle/muelle_dropdown_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/SelectSubMuelleBottomSheet_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/cant_lineas_muelle_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_picking_incompleted_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dropdowbutton_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/popunButton_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/progressIndicatos_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/location/scanner_location_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/product/product_dropdown_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/product/scanner_product_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/quantity/scanner_quantity_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_numbers_widget.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  _BatchDetailScreenState createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchScreen>
    with WidgetsBindingObserver {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

  String scannedValue6 = '';
  String? selectedLocation;
  String? selectedMuelle;

  FocusNode focusNode1 = FocusNode(); // ubicacion  de origen
  FocusNode focusNode2 = FocusNode(); // producto
  FocusNode focusNode3 = FocusNode(); // cantidad por pda
  FocusNode focusNode4 = FocusNode(); //cantidad textformfield
  FocusNode focusNode5 = FocusNode(); //cantidad muelle
  FocusNode focusNode6 = FocusNode(); //Submuelle

  //controller
  final TextEditingController _controllerLocation = TextEditingController();
  final TextEditingController _controllerProduct = TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final TextEditingController _controllerMuelle = TextEditingController();
  final TextEditingController _controllerSubMuelle = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted) {
      // 1. Variable para capturar el contexto del diálogo
      BuildContext? dialogContext;

      showDialog(
        context: context,
        barrierDismissible: false, // Evita cierre manual
        builder: (ctx) {
          // 2. Capturamos el contexto del builder
          dialogContext = ctx;
          return const DialogLoading(message: "Espere un momento...");
        },
      );

      Future.delayed(const Duration(seconds: 1), () {
        // 3. Verificamos que la pantalla siga montada
        if (!mounted) return;

        // 4. Verificamos que el diálogo siga existiendo y usamos SU contexto
        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.of(dialogContext!).pop();
        }
      });
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
      focusNode6
    ]) {
      if (node == nodeToFocus) {
        FocusScope.of(context).requestFocus(node);
      } else {
        node.unfocus();
      }
    }
  }

  void _handleFocusAccordingToState() {
    final bloc = context.read<BatchBloc>();

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
      "quantity": () =>
          bloc.locationIsOk &&
          bloc.productIsOk &&
          bloc.quantityIsOk &&
          !bloc.locationDestIsOk &&
          !bloc.viewQuantity,
      "muelle": () =>
          bloc.locationIsOk &&
          bloc.productIsOk &&
          !bloc.quantityIsOk &&
          !bloc.locationDestIsOk,
    };

    final focusNodeByKey = {
      "location": focusNode1,
      "product": focusNode2,
      "quantity": focusNode3,
      "muelle": focusNode5,
    };

    for (final entry in focusMap.entries) {
      if (entry.value()) {
        debugPrint("🚼 ${entry.key}");
        _setOnlyFocus(focusNodeByKey[entry.key]!);
        break;
      }
    }
  }

  String _getScannedOrManual(String scanned, String manual) {
    print("Scanned: $scanned, Manual: $manual");
    final scan = scanned.trim().toLowerCase();
    return scan.isEmpty ? manual.trim().toLowerCase() : scan;
  }

  void validateLocation(String value) async {
    final bloc = context.read<BatchBloc>();
    final scan = _getScannedOrManual(bloc.scannedValue1, value);
    final product = bloc.currentProduct;

    _controllerLocation.clear();

    if (scan == product.barcodeLocation?.toLowerCase()) {
      bloc.add(ValidateFieldsEvent(field: "location", isOk: true));
      bloc.add(ChangeLocationIsOkEvent(
          product.idProduct ?? 0,
          bloc.batchWithProducts.batch?.id ?? 0,
          product.idMove ?? 0,
          bloc.typePicking));
      bloc.oldLocation = product.locationId.toString();
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();

      bloc.add(ValidateFieldsEvent(field: "location", isOk: false));
    }

    bloc.add(ClearScannedValueEvent('location'));
  }

  void validateProduct(String value) async {
    final bloc = context.read<BatchBloc>();
    final scan = _getScannedOrManual(bloc.scannedValue2, value);
    final product = bloc.currentProduct;

    debugPrint('scan product: $scan');
    _controllerProduct.clear();

    if (scan == product.barcode?.toLowerCase()) {
      bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
      bloc.add(ChangeProductIsOkEvent(
          true,
          product.idProduct ?? 0,
          bloc.batchWithProducts.batch?.id ?? 0,
          0,
          product.idMove ?? 0,
          bloc.typePicking));
    } else {
      final isOk = await validateScannedBarcode(scan, product, bloc, true);
      if (!isOk) {
        _vibrationService.vibrate();
        _audioService.playErrorSound();
        bloc.add(ValidateFieldsEvent(field: "product", isOk: false));
      }
    }

    bloc.add(ClearScannedValueEvent('product'));
  }

  void validateQuantity(String value) async {
    print("Validando cantidad: $value");
    final bloc = context.read<BatchBloc>();
    final scan = _getScannedOrManual(bloc.scannedValue3, value);
    final product = bloc.currentProduct;

    _controllerQuantity.clear();

    if (bloc.quantitySelected == product.quantity) return;

    if (scan == product.barcode?.toLowerCase()) {
      bloc.add(AddQuantitySeparate(product.idProduct ?? 0, product.idMove ?? 0,
          1, false, bloc.typePicking));
    } else {
      await validateScannedBarcode(scan, product, bloc, false);
    }

    bloc.add(ClearScannedValueEvent('quantity'));
  }

  void validateMuelle(String value) async {
    final bloc = context.read<BatchBloc>();
    final scan = _getScannedOrManual(bloc.scannedValue4, value);
    final product = bloc.currentProduct;

    _controllerMuelle.clear();

    final expected =
        bloc.configurations.result?.result?.muelleOption == "multiple"
            ? product.barcodeLocationDest?.toLowerCase()
            : bloc.batchWithProducts.batch?.barcodeMuelle?.toLowerCase();

    if (scan == expected) {
      validatePicking(bloc, context, product);
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();

      bloc.add(ValidateFieldsEvent(field: "locationDest", isOk: false));
    }

    bloc.add(ClearScannedValueEvent('muelle'));
  }

  @override
  void dispose() {
    for (final node in [
      focusNode1,
      focusNode2,
      focusNode3,
      focusNode4,
      focusNode5,
      focusNode6
    ]) {
      node.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocBuilder<BatchBloc, BatchState>(builder: (context, state) {
        final batchBloc = context.read<BatchBloc>();

        int totalTasks = context.read<BatchBloc>().filteredProducts.length;

        double progress = totalTasks > 0
            ? context.read<BatchBloc>().filteredProducts.where((e) {
                  return e.isSeparate == 1;
                }).length /
                totalTasks
            : 0.0;

        final currentProduct = batchBloc.currentProduct;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              //todo: barra info
              BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                builder: (context, status) {
                  return Container(
                    width: size.width,
                    color: primaryColorApp,
                    child: BlocConsumer<BatchBloc, BatchState>(
                        listenWhen: (previous, current) {
                      if (current is LoadingFetchBatch) {
                        print("------------entramos------------");
                        return true;
                      }
                      return true;
                    }, listener: (context, state) {
                      print("❤️‍🔥 state : $state");
                      if (state is ViewProductImageSuccess) {
                        showImageDialog(context, state.imageUrl);
                      } else if (state is ViewProductImageFailure) {
                        showScrollableErrorDialog(state.error);
                      }

                      // * validamos en todo cambio de estado de cantidad separada
                      if (state is ChangeQuantitySeparateStateSuccess) {
                        if (state.quantity == currentProduct.quantity) {
                          _nextProduct(currentProduct, batchBloc);
                        }
                      }

                      if (state is CurrentProductChangedStateLoading) {
                        showDialog(
                          context: context,
                          barrierDismissible:
                              false, // No permitir que el usuario cierre el diálogo manualmente
                          builder: (context) => const DialogLoading(
                            message: 'Cargando producto...',
                          ),
                        );
                      }

                      if (state is CurrentProductChangedState) {
                        Future.delayed(const Duration(seconds: 1), () {
                          // _handleDependencies();
                          Navigator.pop(context);
                        });
                      }

                      if (state is ChangeQuantitySeparateStateError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text(state.msg),
                          backgroundColor: Colors.red[200],
                        ));
                      }

                      if (state is CurrentProductChangedStateError) {
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

                      if (state is SelectNovedadStateError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text(state.msg),
                          backgroundColor: Colors.red[200],
                        ));
                      }

                      if (state is LoadDataInfoError) {
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
                      if (state is ChangeProductIsOkState) {
                        //cambiamos el foco a cantidad
                        Future.delayed(const Duration(seconds: 1), () {
                          FocusScope.of(context).requestFocus(focusNode3);
                        });
                        _handleFocusAccordingToState();
                      }
                      //*estado cuando el muelle fue editado
                      if (state is SubMuelleEditSusses) {
                        //mostramos alerta
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text(state.message),
                          backgroundColor: Colors.green[200],
                        ));
                      }

                      if (state is SubMuelleEditFail) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text(state.message),
                          backgroundColor: Colors.red[200],
                        ));
                      }

                      if (state is MuellesLoadingState) {
                        showDialog(
                          context: context,
                          barrierDismissible:
                              false, // No permitir que el usuario cierre el diálogo manualmente
                          builder: (context) => const DialogLoading(
                            message: 'Cargando muelles...',
                          ),
                        );
                      }

                      if (state is MuellesErrorState) {
                        Navigator.pop(context);

                        showScrollableErrorDialog(state.error);
                      }

                      if (state is MuellesLoadedState) {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          backgroundColor: white,
                          context: context,
                          isDismissible: false,
                          enableDrag: false,
                          builder: (context) {
                            return SelectSubMuelleBottomSheet(
                              controller: _controllerSubMuelle,
                              focusNode: focusNode6,
                            );
                          },
                        );
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

                                    batchBloc.add(ResetValuesEvent());
                                    context.read<WMSPickingBloc>().add(
                                        FilterBatchesBStatusEvent(
                                            '', batchBloc.typePicking));

                                    //validamos el type
                                    if (batchBloc.typePicking == 'components') {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        'picking-componentes-batch',
                                      );
                                    } else if (batchBloc.typePicking ==
                                        'batch') {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        'wms-picking',
                                      );
                                    } else {
                                      Navigator.pushReplacementNamed(
                                          context, '/home');
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white, size: 20),
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    batchBloc.batchWithProducts.batch?.name ??
                                        '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                const Spacer(),
                                PopupMenuButtonWidget(
                                    currentProduct: currentProduct),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            child: ProgressIndicatorWidget(
                              progress: progress,
                              completed: batchBloc.filteredProducts.where((e) {
                                return e.isSeparate == 1;
                              }).length,
                              total: totalTasks,
                            ),
                          ),
                          const SizedBox(height: 10),
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

                        LocationScannerWidget(
                          isLocationOk: batchBloc.isLocationOk,
                          locationIsOk: batchBloc.locationIsOk,
                          productIsOk: batchBloc.productIsOk,
                          quantityIsOk: batchBloc.quantityIsOk,
                          locationDestIsOk: batchBloc.locationDestIsOk,
                          currentLocationId:
                              batchBloc.currentProduct.locationId.toString(),
                          onValidateLocation: (value) {
                            validateLocation(value);
                          },
                          onKeyScanned: (keyLabel) {
                            context.read<BatchBloc>().add(
                                UpdateScannedValueEvent(keyLabel, 'location'));
                          },
                          focusNode: focusNode1,
                          controller: _controllerLocation,
                          locationDropdown: LocationDropdownWidget(
                            selectedLocation: selectedLocation,
                            positionsOrigen: batchBloc.positionsOrigen,
                            currentLocationId:
                                currentProduct.locationId.toString(),
                            batchBloc: batchBloc,
                            currentProduct: currentProduct,
                            isPDA: !context
                                .read<UserBloc>()
                                .fabricante
                                .contains("Zebra"),
                          ),
                        ),

                        // todo: Producto

                        ProductScannerWidget(
                          isProductOk: batchBloc.isProductOk,
                          productIsOk: batchBloc.productIsOk,
                          locationIsOk: batchBloc.locationIsOk,
                          quantityIsOk: batchBloc.quantityIsOk,
                          locationDestIsOk: batchBloc.locationDestIsOk,
                          currentProductId:
                              batchBloc.currentProduct.productId.toString(),
                          barcode: currentProduct.barcode,
                          lotId: currentProduct.lotId,
                          origin: currentProduct.origin,
                          expireDate: currentProduct.expireDate,
                          size: size,
                          onValidateProduct: (value) {
                            validateProduct(value); // tu función actual
                          },
                          onKeyScanned: (keyLabel) {
                            context.read<BatchBloc>().add(
                                UpdateScannedValueEvent(keyLabel, 'product'));
                          },
                          focusNode: focusNode2,
                          controller: _controllerProduct,
                          productDropdown: ProductDropdownWidget(
                            selectedProduct:
                                selectedLocation, // o selectedProduct
                            listOfProductsName: batchBloc.listOfProductsName,
                            currentProductId:
                                batchBloc.currentProduct.productId.toString(),
                            batchBloc: batchBloc,
                            currentProduct: currentProduct,
                          ),
                          expiryWidget: ExpirationBadgeWidget(
                            expirationDate:
                                batchBloc.currentProduct?.expireDate,
                          ),
                          listOfBarcodes: batchBloc.listOfBarcodes,
                          onBarcodesDialogTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return DialogBarcodes(
                                    listOfBarcodes: batchBloc.listOfBarcodes);
                              },
                            );
                          },
                          onViewImgProduct: () {
                            batchBloc.add(ViewProductImageEvent(
                                currentProduct.idProduct ?? 0));
                          },
                        ),

                        //Todo: MUELLE

                        if (batchBloc.filteredProducts
                                    .where((e) => e.isSeparate == 0)
                                    .length ==
                                1 ||
                            batchBloc.filteredProducts
                                .where((e) => e.isSeparate == 0)
                                .isEmpty)
                          LocationDestScannerWidget(
                            isLocationDestOk: batchBloc.isLocationDestOk,
                            locationDestIsOk: batchBloc.locationDestIsOk,
                            locationIsOk: batchBloc.locationIsOk,
                            productIsOk: batchBloc.productIsOk,
                            quantityIsOk: batchBloc.quantityIsOk,
                            size: size,
                            muelleHint:
                                batchBloc.batchWithProducts.batch?.muelle ?? "",
                            onValidateMuelle: (value) {
                              validateMuelle(
                                  value); // tu función actual de validación
                            },
                            onKeyScanned: (keyLabel) {
                              context.read<BatchBloc>().add(
                                  UpdateScannedValueEvent(keyLabel, 'muelle'));
                            },
                            focusNode: focusNode5,
                            controller: _controllerMuelle,
                            dropdownWidget: MuelleDropdownWidget(
                              selectedMuelle: selectedMuelle,
                              batchBloc: batchBloc,
                              currentProduct: currentProduct,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              //todo muelle multiple
              Visibility(
                visible:
                    batchBloc.configurations.result?.result?.muelleOption ==
                        "multiple",
                child: Container(
                    width: size.width,
                    height: 55,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    child: Card(
                        color: Colors.grey[300],
                        elevation: 5,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            child: Row(children: [
                              CantLineasMuelle(
                                  productsOk:
                                      batchBloc.filteredProducts.where((e) {
                                return (e.isSeparate == 1) &&
                                    (e.idLocationDest ==
                                        batchBloc.batchWithProducts.batch
                                            ?.idMuellePadre);
                              }).toList()),
                              const Spacer(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: ElevatedButton(
                                    onPressed: batchBloc.filteredProducts
                                            .where((e) {
                                              return (e.isSeparate == 1) &&
                                                  (e.idLocationDest ==
                                                      batchBloc
                                                          .batchWithProducts
                                                          .batch
                                                          ?.idMuellePadre);
                                            })
                                            .toList()
                                            .isEmpty
                                        ? null
                                        : () {
                                            batchBloc.add(FetchMuellesEvent());
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColorAppLigth,
                                      minimumSize: const Size(100, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      batchBloc.batchWithProducts.batch?.muelle
                                              .toString() ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    )),
                              ),
                            ])))),
              ),

              //todo: cantidad
              QuantityScannerWidget(
                size: size,
                isQuantityOk: batchBloc.isQuantityOk,
                quantityIsOk: batchBloc.quantityIsOk,
                locationIsOk: batchBloc.locationIsOk,
                productIsOk: batchBloc.productIsOk,
                locationDestIsOk: batchBloc.locationDestIsOk,
                totalQuantity: currentProduct.quantity,
                quantitySelected: batchBloc.quantitySelected,
                unidades: currentProduct.unidades ?? "",
                controller: _controllerQuantity,
                manualController: cantidadController,
                scannerFocusNode: focusNode3,
                manualFocusNode: focusNode4,
                viewQuantity: batchBloc.viewQuantity,
                onIconButtonPressed: () {
                  print('borrando');
                  batchBloc.add(ShowQuantityEvent(!batchBloc.viewQuantity));
                  Future.delayed(const Duration(milliseconds: 100), () {
                    FocusScope.of(context).requestFocus(focusNode3);
                  });
                },
                onKeyScanned: (keyLabel) {
                  context
                      .read<BatchBloc>()
                      .add(UpdateScannedValueEvent(keyLabel, 'quantity'));
                },
                showKeyboard:
                    context.read<UserBloc>().fabricante.contains("Zebra"),
                onToggleViewQuantity: () {
                  batchBloc.add(ShowQuantityEvent(!batchBloc.viewQuantity));
                  cantidadController.clear();
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
                      batchBloc.quantitySelected = double.parse(value);
                    } catch (e) {
                      print('❌ Error al convertir a número: $e');
                    }
                  } else {
                    batchBloc.quantitySelected = 0;
                  }
                },
                onManualQuantitySubmitted: (value) {
                  if (value.isNotEmpty) {
                    final intValue = int.parse(value);
                    if (intValue > (currentProduct.quantity ?? 0)) {
                      batchBloc.add(
                          ValidateFieldsEvent(field: "quantity", isOk: false));
                      cantidadController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: const Text('Cantidad incorrecta'),
                          backgroundColor: Colors.red[200],
                        ),
                      );
                    } else {
                      if (intValue == currentProduct.quantity) {
                        batchBloc.add(ChangeQuantitySeparate(
                            intValue,
                            currentProduct.idProduct ?? 0,
                            currentProduct.idMove ?? 0,
                            batchBloc.typePicking));
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return DialogAdvetenciaCantidadScreen(
                              currentProduct: currentProduct,
                              cantidad: batchBloc.quantitySelected,
                              batchId:
                                  batchBloc.batchWithProducts.batch?.id ?? 0,
                              onAccepted: () {
                                batchBloc.add(ChangeQuantitySeparate(
                                    intValue,
                                    currentProduct.idProduct ?? 0,
                                    currentProduct.idMove ?? 0,
                                    batchBloc.typePicking));
                                _nextProduct(currentProduct, batchBloc);
                              },
                            );
                          },
                        );
                      }
                    }
                  }
                  batchBloc.add(ShowQuantityEvent(false));
                },
                customKeyboard: CustomKeyboardNumber(
                  controller: cantidadController,
                  onchanged: _validatebuttonquantity,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _validatebuttonquantity() {
    final batchBloc = context.read<BatchBloc>();
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

    if (cantidad == currentProduct.quantity) {
      batchBloc.add(ChangeQuantitySeparate(
          cantidad,
          currentProduct.idProduct ?? 0,
          currentProduct.idMove ?? 0,
          batchBloc.typePicking));
    } else {
      FocusScope.of(context).unfocus();
      if (cantidad < (currentProduct.quantity ?? 0).toDouble()) {
        showDialog(
          context: context,
          builder: (context) {
            return DialogAdvetenciaCantidadScreen(
              currentProduct: currentProduct,
              cantidad: cantidad,
              batchId: batchBloc.batchWithProducts.batch?.id ?? 0,
              onAccepted: () async {
                batchBloc.add(ChangeQuantitySeparate(
                    cantidad,
                    currentProduct.idProduct ?? 0,
                    currentProduct.idMove ?? 0,
                    batchBloc.typePicking));
                _nextProduct(currentProduct, batchBloc);
                cantidadController.clear();
              },
            );
          },
        );
      } else {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(milliseconds: 1000),
          content: const Text('Cantidad errónea'),
          backgroundColor: Colors.red[200],
        ));
      }
    }
  }

  void _nextProduct(ProductsBatch currentProduct, BatchBloc batchBloc) async {
    // Si el proceso ya está en ejecución, no hacemos nada
    if (batchBloc.isProcessing) return;

    // Establecemos la bandera para indicar que el proceso está en ejecución
    batchBloc.add(SetIsProcessingEvent(true));

    try {
      DataBaseSqlite db = DataBaseSqlite();
      final batch = batchBloc.batchWithProducts.batch;

      // Si no hay batch, termina la ejecución
      if (batch == null) return;

      print("currentProduct ${currentProduct.productId}");

      // Función para actualizar la base de datos en varios campos a la vez
      Future<void> _updateDatabaseFields() async {
        await db.setFieldTableBatchProducts(
            batch.id ?? 0,
            currentProduct.idProduct ?? 0,
            'is_separate',
            1,
            currentProduct.idMove ?? 0,
            batchBloc.typePicking);

        await db.incrementProductSeparateQty(
            batch.id ?? 0, batchBloc.typePicking);
      }

      // Función para gestionar la transición al siguiente producto
      Future<void> _moveToNextProduct() async {
        // Si estamos en la última posición
        final separated =
            batchBloc.filteredProducts.where((e) => e.isSeparate == 0).toList();

        if (batchBloc.index + 1 == separated.length) {
          // Último elemento alcanzado

          // Cambiar el producto actual
          context.read<BatchBloc>().add(ChangeCurrentProduct(
                currentProduct: currentProduct,
                type: batchBloc.typePicking,
              ));

          // Cambiar el estado de cantidad
          batchBloc.add(ChangeIsOkQuantity(
              false,
              currentProduct.idProduct ?? 0,
              batch.id ?? 0,
              currentProduct.idMove ?? 0,
              batchBloc.typePicking));

          // Marcar como "no correcto" la cantidad
          await db.setFieldTableBatchProducts(
              batch.id ?? 0,
              currentProduct.idProduct ?? 0,
              'is_quantity_is_ok',
              0,
              currentProduct.idMove ?? 0,
              batchBloc.typePicking);

          // Recargar productos
          context.read<BatchBloc>().add(FetchBatchWithProductsEvent(
              batch.id ?? 0, batchBloc.typePicking));

          // Esperar 1 segundo y mover el foco
          await Future.delayed(const Duration(seconds: 1));
          FocusScope.of(context).requestFocus(focusNode5);
        } else {
          // Si no estamos en la última posición, cambiamos el producto actual
          context.read<BatchBloc>().add(ChangeCurrentProduct(
                currentProduct: currentProduct,
                type: batchBloc.typePicking,
              ));

          // Validamos el campo "quantity"
          batchBloc.add(ValidateFieldsEvent(field: "quantity", isOk: true));

          // Limpiamos el controlador de cantidad
          batchBloc.quantitySelected = 0;
          cantidadController.clear();

          // Esperar 1 segundo y llamar los códigos de barras del producto
          await Future.delayed(const Duration(seconds: 1));
          batchBloc.add(FetchBarcodesProductEvent());
        }
      }

      // Ejecutar las operaciones en bloque
      await _updateDatabaseFields();
      batchBloc.add(ShowQuantityEvent(false));
      batchBloc.sortProductsByLocationId(batchBloc.typePicking);
      await _moveToNextProduct();
    } catch (e, s) {
      print("❌ Error en _nextProduct: $e -> $s");
      // Manejo de errores
    } finally {
      batchBloc.add(SetIsProcessingEvent(false));
    }
  }

  Future<bool> validateScannedBarcode(String scannedBarcode,
      ProductsBatch currentProduct, BatchBloc batchBloc, bool isProduct) async {
    // Buscar el barcode que coincida con el valor escaneado
    Barcodes? matchedBarcode = context
        .read<BatchBloc>()
        .listOfBarcodes
        .firstWhere(
            (barcode) => barcode.barcode?.toLowerCase() == scannedBarcode,
            orElse: () =>
                Barcodes() // Si no se encuentra ningún match, devuelve null
            );
    if (matchedBarcode.barcode != null) {
      if (isProduct) {
        batchBloc.add(ValidateFieldsEvent(field: "product", isOk: true));

        batchBloc.add(ChangeQuantitySeparate(0, currentProduct.idProduct ?? 0,
            currentProduct.idMove ?? 0, batchBloc.typePicking));

        batchBloc.add(ChangeProductIsOkEvent(
            true,
            currentProduct.idProduct ?? 0,
            batchBloc.batchWithProducts.batch?.id ?? 0,
            0,
            currentProduct.idMove ?? 0,
            batchBloc.typePicking));

        batchBloc.add(ChangeIsOkQuantity(
            true,
            currentProduct.idProduct ?? 0,
            batchBloc.batchWithProducts.batch?.id ?? 0,
            currentProduct.idMove ?? 0,
            batchBloc.typePicking));

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
            batchBloc.typePicking));
      }
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      return false;
    }
    _vibrationService.vibrate();
    _audioService.playErrorSound();
    return false;
  }

  void validatePicking(
      BatchBloc batchBloc, BuildContext context, ProductsBatch currentProduct) {
    batchBloc.add(FetchBatchWithProductsEvent(
        batchBloc.batchWithProducts.batch?.id ?? 0, batchBloc.typePicking));

    //validamos que la cantidad de productos separados sea igual a la cantidad de productos pedidos
//validamos el 100 de las unidades separadas
    final double unidadesSeparadas =
        double.parse(batchBloc.calcularUnidadesSeparadas());

    if (unidadesSeparadas == "100.0" || unidadesSeparadas >= 100.0) {
      var productsToSend = batchBloc.filteredProducts
          .where((element) => element.isSendOdoo == 0)
          .toList();

      // Si hay productos pendientes de enviar a Odoo, mostramos un modal
      if (productsToSend.isNotEmpty) {
        showDialog(
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
                      // Navigator.pop(context);
                      if (batchBloc.configurations.result?.result
                              ?.showDetallesPicking ==
                          true) {
                        //cerramos el focus
                        batchBloc.isSearch = false;
                        batchBloc
                            .add(LoadProductEditEvent(batchBloc.typePicking));
                        // batchBloc.add(IsShouldRunDependencies(false));
                        Navigator.pushReplacementNamed(
                          context,
                          'batch-detail',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(milliseconds: 1000),
                            content:
                                Text('No tienes permisos para ver detalles'),
                          ),
                        );
                      }
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
        batchBloc.add(ValidateFieldsEvent(field: "locationDest", isOk: true));
        batchBloc.add(ChangeLocationDestIsOkEvent(
            true,
            currentProduct.idProduct ?? 0,
            batchBloc.batchWithProducts.batch?.id ?? 0,
            currentProduct.idMove ?? 0,
            batchBloc.typePicking));

        batchBloc.add(EndTimePick(
            batchBloc.batchWithProducts.batch?.id ?? 0, DateTime.now()));

        batchBloc.add(PickingOkEvent(batchBloc.batchWithProducts.batch?.id ?? 0,
            currentProduct.idProduct ?? 0, batchBloc.typePicking));
        context
            .read<WMSPickingBloc>()
            .add(FilterBatchesBStatusEvent('', batchBloc.typePicking));
        batchBloc.index = 0;
        batchBloc.isSearch = true;
        //validamos el type
        if (batchBloc.typePicking == 'components') {
          Navigator.pushReplacementNamed(
            context,
            'picking-componentes-batch',
          );
        } else if (batchBloc.typePicking == 'batch') {
          Navigator.pushReplacementNamed(
            context,
            'wms-picking',
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return DialogPickingIncompleted(
                currentProduct: batchBloc.currentProduct,
                cantidad: unidadesSeparadas,
                batchBloc: batchBloc,
                onAccepted: () {
                  if (batchBloc
                          .configurations.result?.result?.showDetallesPicking ==
                      true) {
                    //cerramos el focus
                    batchBloc.isSearch = false;
                    batchBloc.add(LoadProductEditEvent(batchBloc.typePicking));
                    Navigator.pushReplacementNamed(
                      context,
                      'batch-detail',
                    ).then((_) {});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(milliseconds: 1000),
                        content: Text('No tienes permisos para ver detalles'),
                      ),
                    );
                  }
                });
          });
    }
  }
}
