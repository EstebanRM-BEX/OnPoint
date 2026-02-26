// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/location/LocationCardButton_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/location/LocationScanner_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/lote/lote_scannear_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/product/ProductScanner_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/product/product_dropdown_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/others/dialog_validate_product_send_widget.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/quantity/scanner_quantity_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class NewProductConteoScreen extends StatefulWidget {
  const NewProductConteoScreen({Key? key}) : super(key: key);

  @override
  State<NewProductConteoScreen> createState() => _NewProductConteoScreenState();
}

class _NewProductConteoScreenState extends State<NewProductConteoScreen>
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
      _handleDependencies();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDependencies();
  }

  void _focus(FocusNode node, String label) {
    print("🚼 $label");
    FocusScope.of(context).requestFocus(node);
    _unfocusOthers(except: node);
  }

  void _unfocusOthers({required FocusNode except}) {
    for (final node in [
      focusNode1,
      focusNode2,
      focusNode3,
      focusNode4,
      focusNode5
    ]) {
      if (node != except) node.unfocus();
    }
  }

  void _handleDependencies() {
    final bloc = context.read<ConteoBloc>();
    final hasLote = bloc.currentProduct.productTracking == "lot";

    final focusMap = {
      "location": () =>
          !bloc.locationIsOk && !bloc.productIsOk && !bloc.quantityIsOk,
      "product": () =>
          bloc.locationIsOk && !bloc.productIsOk && !bloc.quantityIsOk,
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
          !bloc.viewQuantity,
    };

    final focusNodeByKey = {
      "location": focusNode1,
      "product": focusNode2,
      "lote": focusNode5,
      "quantity": focusNode3,
    };

    for (final entry in focusMap.entries) {
      if (entry.value()) {
        _focus(focusNodeByKey[entry.key]!, entry.key);
        return;
      }
    }

    setState(() {}); // Si necesitas un rebuild explícito
  }

  void validateLocation(String value) {
    final bloc = context.read<ConteoBloc>();
    final scan = value.trim().toLowerCase();

    print('scan location: $scan');
    _controllerLocation.clear();

    ResultUbicaciones? matchedUbicacion = bloc.ubicacionesFilters.firstWhere(
        (ubicacion) => ubicacion.barcode?.toLowerCase() == scan.trim(),
        orElse: () =>
            ResultUbicaciones() // Si no se encuentra ningún match, devuelve null
        );

    if (matchedUbicacion.barcode != null) {
      print('Ubicacion encontrada: ${matchedUbicacion.name}');
      bloc.add(ValidateFieldsEvent(field: "location", isOk: true));
      bloc.add(ChangeLocationIsOkEvent(true, matchedUbicacion, 0, 0, 0));
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      print('Ubicacion no encontrada');
      bloc.add(ValidateFieldsEvent(field: "location", isOk: false));
    }
    Future.microtask(() => focusNode1.requestFocus());
  }

  void validateProduct(String value) {
    final bloc = context.read<ConteoBloc>();
    final scan = bloc.scannedValue2.trim().toLowerCase() == ""
        ? value.trim().toLowerCase()
        : bloc.scannedValue2.trim().toLowerCase();

    _controllerProduct.clear();
    print('🔎 Scan barcode: $scan');

    Product? matchedProducts = bloc.productosFilters.firstWhere(
        (productoUbi) =>
            productoUbi.barcode?.toLowerCase() == scan.trim() ||
            productoUbi.code?.toLowerCase() == scan.trim(),
        orElse: () =>
            Product() // Si no se encuentra ningún match, devuelve null
        );

    if (matchedProducts.barcode != null) {
      print('producto encontrado: ${matchedProducts.name}');
      bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
      bloc.add(ChangeProductIsOkEvent(true, matchedProducts, 0, true, 0, 0, 0));
      return;
    }

    // Buscar en barcodes adicionales
    final matchedBarcode = bloc.listAllOfBarcodes.firstWhere(
      (b) => b.barcode?.toLowerCase() == scan,
      orElse: () => Barcodes(),
    );

    if (matchedBarcode.barcode == null) {
      print('❌ Producto no encontrado en barcodes');
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      bloc.add(ValidateFieldsEvent(field: "product", isOk: false));
      Future.microtask(() => focusNode2.requestFocus());
      return;
    }

    // Buscar producto por id relacionado al barcode encontrado
    final matchedById = bloc.productos.firstWhere(
      (p) => p.productId == matchedBarcode.idProduct,
      orElse: () => Product(),
    );

    if (matchedById.productId != null) {
      print('✅ Producto encontrado por ID: ${matchedById.name}');
      bloc
        ..add(ValidateFieldsEvent(field: "product", isOk: true))
        ..add(ChangeProductIsOkEvent(true, matchedById, 0, true, 0, 0, 0));
      return;
    } else {
      print('❌ Producto no encontrado por ID');
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      bloc.add(ValidateFieldsEvent(field: "product", isOk: false));
      Future.microtask(() => focusNode2.requestFocus());
      return;
    }
  }

  void validateQuantity(String value) {
    final bloc = context.read<ConteoBloc>();

    String scan = bloc.scannedValue3.trim().toLowerCase() == ""
        ? value.trim().toLowerCase()
        : bloc.scannedValue3.trim().toLowerCase();
    print('scan quantity: $scan');
    _controllerQuantity.clear();
    final currentProduct = bloc.currentProduct;

    if (scan == currentProduct?.productBarcode?.toLowerCase()) {
      bloc.add(AddQuantitySeparate(currentProduct.productId ?? 0,
          currentProduct.orderId ?? 0, currentProduct.idMove ?? 0, 1, false));
    } else {
      validateScannedBarcode(
          scan, currentProduct ?? CountedLine(), bloc, false);
    }
    Future.microtask(() => focusNode3.requestFocus());
  }

  void validateLote(String value) {
    final bloc = context.read<ConteoBloc>();
    final scan = value.trim().toLowerCase();
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
      Future.microtask(() => focusNode5.requestFocus());
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      print('lote no encontrado');
      bloc.add(ValidateFieldsEvent(field: "lote", isOk: false));
      Future.microtask(() => focusNode5.requestFocus());
    }
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
          true,
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
        return true;
      }
    }
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocBuilder<ConteoBloc, ConteoState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: white,
          body: Column(
            children: [
              BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                builder: (context, status) {
                  return Container(
                    width: size.width,
                    color: primaryColorApp,
                    child: BlocConsumer<ConteoBloc, ConteoState>(
                        listener: (context, state) {
                      print("❤️‍🔥 state : $state");

                      if (state is ResetValuesLoadingState) {
                        showDialog(
                          context: context,
                          builder: (context) => const DialogLoading(
                              message: "Limpiando valores..."),
                        );
                        Future.delayed(const Duration(seconds: 1), () {
                          FocusScope.of(context).requestFocus(focusNode1);
                          Navigator.of(context).pop();
                        });
                        _handleDependencies();
                      } else if (state is UpdateProductLoadingEvent) {
                        //cerramos el dialogo
                        Navigator.of(context).pop();
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
                      } else if (state is SendProductConteoFailure) {
                        showScrollableErrorDialog(state.error);
                      }

                      // * validamos en todo cambio de estado de cantidad separada

                      else if (state is SendProductConteoSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text(state.response.result?.msg ?? ""),
                          backgroundColor: Colors.green[200],
                        ));
                        //limpiamos los valores pa volver a iniciar con otro producto
                        cantidadController.clear();
                        context.read<ConteoBloc>().add(
                            ResetValuesEvent(resetAll: true, isLoading: false));

                        context.read<ConteoBloc>().add(
                              LoadConteoAndProductsEvent(
                                  ordenConteoId:
                                      state.response.result?.data?.orderId ??
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
                      } else if (state is ChangeLoteIsOkState) {
                        //cambiamos el foco a cantidad cuando hemos seleccionado un lote
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).requestFocus(focusNode3);
                          _handleDependencies();
                        });
                      } else if (state is ChangeQuantitySeparateStateError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text(state.msg),
                          backgroundColor: Colors.red[200],
                        ));
                      } else if (state is ValidateFieldsStateError) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: const Duration(milliseconds: 1000),
                          content: Text(state.msg),
                          backgroundColor: Colors.red[200],
                        ));
                      }

                      //*estado cando la ubicacion de origen es cambiada
                      else if (state is ChangeLocationIsOkState) {
                        //cambiamos el foco
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).requestFocus(focusNode2);
                          _handleDependencies();
                        });
                      }

                      //*estado cuando el producto es leido ok
                      else if (state is ChangeProductOrderIsOkState) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context
                                  .read<ConteoBloc>()
                                  .currentProduct
                                  .productTracking ==
                              "lot") {
                            focusNode5.requestFocus();
                          } else {
                            focusNode3.requestFocus();
                          }
                          _handleDependencies();
                        });
                      } else if (state is GetLotesProductSuccess) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          focusNode5.requestFocus();
                          _handleDependencies();
                        });
                      }
                    }, builder: (context, status) {
                      return Column(
                        children: [
                          const WarningWidgetCubit(),
                          Padding(
                            padding: const EdgeInsets.only(top: 25),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    cantidadController.clear();

                                    context.read<ConteoBloc>().add(
                                        ResetValuesEvent(
                                            resetAll: false, isLoading: false));

                                    Navigator.pushReplacementNamed(
                                      context,
                                      'conteo-detail',
                                      arguments: [
                                        1,
                                        context.read<ConteoBloc>().ordenConteo,
                                      ],
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white, size: 20),
                                ),
                                const Spacer(),
                                Padding(
                                  padding: EdgeInsets.only(
                                      right: size.width * 0.015),
                                  child: Text(
                                    'CONTEO FISICO',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    context.read<ConteoBloc>().add(
                                        ResetValuesEvent(
                                            resetAll: false, isLoading: true));
                                    _handleDependencies();
                                    cantidadController.clear();
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white, size: 20),
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
                      const SizedBox(height: 10),

                      LocationScannerAll(
                        isLocationOk: context.read<ConteoBloc>().isLocationOk,
                        locationIsOk: context.read<ConteoBloc>().locationIsOk,
                        productIsOk: context.read<ConteoBloc>().productIsOk,
                        quantityIsOk: context.read<ConteoBloc>().quantityIsOk,
                        currentLocationName:
                            context.read<ConteoBloc>().currentUbication?.name,
                        onLocationScanned: (value) {
                          validateLocation(value);
                        },
                        focusNode: focusNode1,
                        controller: _controllerLocation,
                        locationDropdown: LocationCardButtonConteo(
                          bloc: context.read<
                              ConteoBloc>(), // Tu instancia de BLoC/Controlador
                          cardColor:
                              white, // Asegúrate que 'white' esté definido en tus colores
                          textAndIconColor:
                              primaryColorApp, // Usa tu color primario
                          title: 'Ubicación de existencias',
                          routeName: 'search-location-conteo',
                          ubicacionFija: true,
                        ), // Pasamos el widget del dropdown como parámetro
                      ),

                      //todo: producto
                      ProductScannerAll(
                        focusNode: focusNode2,
                        controller: _controllerProduct,
                        locationIsOk: context.read<ConteoBloc>().locationIsOk,
                        productIsOk: context.read<ConteoBloc>().productIsOk,
                        quantityIsOk: context.read<ConteoBloc>().quantityIsOk,
                        isProductOk: context.read<ConteoBloc>().isProductOk,
                        currentProduct:
                            context.read<ConteoBloc>().currentProduct,
                        onValidateProduct: (value) {
                          validateProduct(value);
                        },
                        productDropdown: ProductDropdowmnWidget(),
                      ),

                      //todo lote
                      Visibility(
                        // El padre controla la visibilidad
                        visible: context
                                .read<ConteoBloc>()
                                .currentProduct
                                .productTracking ==
                            "lot",
                        child: LoteScannerWidget(
                          routeName: 'search-lote-conteo',
                          focusNode: focusNode5,
                          controller: _controllerLote,
                          isLoteOk: context.read<ConteoBloc>().isLoteOk,
                          loteIsOk: context.read<ConteoBloc>().loteIsOk,
                          locationIsOk: context.read<ConteoBloc>().locationIsOk,
                          productIsOk: context.read<ConteoBloc>().productIsOk,
                          quantityIsOk: context.read<ConteoBloc>().quantityIsOk,
                          viewQuantity: context.read<ConteoBloc>().viewQuantity,
                          currentProduct:
                              context.read<ConteoBloc>().currentProduct,
                          currentProductLote:
                              context.read<ConteoBloc>().currentProductLote,
                          onValidateLote: (value) {
                            validateLote(value);
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              //todo: cantidad
              QuantityScannerWidget(
                size: size,
                isQuantityOk: context.read<ConteoBloc>().isQuantityOk,
                quantityIsOk: context.read<ConteoBloc>().quantityIsOk,
                locationIsOk: context.read<ConteoBloc>().locationIsOk,
                productIsOk: context.read<ConteoBloc>().productIsOk,
                locationDestIsOk: false,
                totalQuantity: 0,
                quantitySelected: context.read<ConteoBloc>().quantitySelected,
                unidades: context.read<ConteoBloc>().currentProduct.uom ?? "",
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
                      true,
                      intValue,
                      context.read<ConteoBloc>().currentProduct.productId ?? 0,
                      context.read<ConteoBloc>().currentProduct.orderId ?? 0,
                      context.read<ConteoBloc>().currentProduct.idMove ?? 0));

                  context.read<ConteoBloc>().add(ShowQuantityEvent(
                      !context.read<ConteoBloc>().viewQuantity));
                },
                isViewCant: false,
              ),
            ],
          ),
        );
      },
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
        bloc.add(SendProductConteoEvent(true, cantidad, bloc.currentProduct));
      }
    } else {
      double cantidad = double.parse(cantidadController.text.isEmpty
          ? bloc.quantitySelected.toString()
          : cantidadController.text);
      print("cantidad: $cantidad");
      bloc.add(SendProductConteoEvent(true, cantidad, bloc.currentProduct));
    }
  }
}
