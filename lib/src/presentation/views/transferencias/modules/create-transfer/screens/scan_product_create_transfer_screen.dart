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
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/location/LocationScanner_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/lote/lote_scannear_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/product/ProductScanner_widget.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/widgets/location/LocationCardButton_widget%20copy.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/widgets/others/popup_menu_widget.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/widgets/product/product_dropdown_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/quantity/scanner_quantity_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_numbers_widget.dart';

class CreateTransferScreen extends StatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  State<CreateTransferScreen> createState() => _CreateTransferScreenState();
}

class _CreateTransferScreenState extends State<CreateTransferScreen>
    with WidgetsBindingObserver {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

  //*focus
  FocusNode focusNode1 = FocusNode(); // ubicacion  de origen
  FocusNode focusNode2 = FocusNode(); // producto
  FocusNode focusNode3 = FocusNode(); // cantidad por pda
  FocusNode focusNode4 = FocusNode(); //cantidad textformfield
  FocusNode focusNode5 = FocusNode(); // lote
  FocusNode focusNode6 = FocusNode(); // ubicacion  de destino

  //controller
  final TextEditingController _controllerLocation = TextEditingController();
  final TextEditingController _controllerLocationDestino =
      TextEditingController();
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
      focusNode5,
      focusNode6,
    ]) {
      if (node != except) node.unfocus();
    }
  }

  void _handleDependencies() {
    final bloc = context.read<CreateTransferBloc>();
    final hasLote = bloc.currentProduct?.tracking == "lot";

    //mostramos todas las variables de foco y sus condiciones
    print('---------------- Manejo de dependencias ---------------');
    print("ubicación: ${bloc.locationIsOk}");
    print("producto: ${bloc.productIsOk}");
    print("lote: ${bloc.loteIsOk}");
    print("cantidad: ${bloc.quantityIsOk}");
    print("ubicación destino: ${bloc.locationDestIsOk}");

    final focusMap = {
      "location": () =>
          !bloc.locationIsOk &&
          !bloc.locationIsOk &&
          !bloc.productIsOk &&
          !bloc.quantityIsOk,
      "product": () =>
          bloc.locationIsOk &&
          bloc.locationDestIsOk &&
          !bloc.productIsOk &&
          !bloc.quantityIsOk,
      "lote": () =>
          hasLote &&
          bloc.locationIsOk &&
          bloc.locationDestIsOk &&
          bloc.productIsOk &&
          !bloc.loteIsOk &&
          !bloc.quantityIsOk &&
          !bloc.viewQuantity,
      "quantity": () =>
          bloc.locationIsOk &&
          bloc.locationDestIsOk &&
          bloc.productIsOk &&
          (hasLote ? bloc.loteIsOk : true) &&
          bloc.quantityIsOk &&
          !bloc.viewQuantity,
      "locationDest": () =>
          bloc.locationIsOk &&
          !bloc.locationDestIsOk &&
          !bloc.productIsOk &&
          !bloc.quantityIsOk,
    };

    final focusNodeByKey = {
      "location": focusNode1,
      "product": focusNode2,
      "lote": focusNode5,
      "quantity": focusNode3,
      "locationDest": focusNode6,
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
    final bloc = context.read<CreateTransferBloc>();
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
      bloc.add(ChangeLocationIsOkEvent(matchedUbicacion, false));
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      print('Ubicacion no encontrada');
      bloc.add(ValidateFieldsEvent(field: "location", isOk: false));
    }

    Future.microtask(() => focusNode1.requestFocus());
  }

  void validateLocationDest(String value) {
    final bloc = context.read<CreateTransferBloc>();
    final scan = value.trim().toLowerCase();

    print('scan location dest: $scan');
    _controllerLocationDestino.clear();

    ResultUbicaciones? matchedUbicacion = bloc.ubicacionesFilters.firstWhere(
        (ubicacion) => ubicacion.barcode?.toLowerCase() == scan.trim(),
        orElse: () =>
            ResultUbicaciones() // Si no se encuentra ningún match, devuelve null
        );

    if (matchedUbicacion.barcode != null) {
      print('Ubicacion encontrada: ${matchedUbicacion.name}');
      bloc.add(ValidateFieldsEvent(field: "locationDest", isOk: true));
      bloc.add(ChangeLocationIsOkEvent(matchedUbicacion, true));
    } else {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      print('Ubicacion no encontrada');
      bloc.add(ValidateFieldsEvent(field: "locationDest", isOk: false));
    }

    Future.microtask(() => focusNode6.requestFocus());
  }

  void validateProduct(String value) {
    final bloc = context.read<CreateTransferBloc>();

    final scan = value.trim().toLowerCase();

    _controllerProduct.clear();
    print('🔎 Scan barcode: $scan');

    // Buscar coincidencia directa por barcode o code
    final matchedProduct = bloc.productos.firstWhere(
      (p) => p.barcode?.toLowerCase() == scan || p.code?.toLowerCase() == scan,
      orElse: () => Product(),
    );

    if (matchedProduct.barcode != null) {
      print('✅ producto encontrado directo: ${matchedProduct.name}');
      bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
      bloc.add(ChangeProductIsOkEvent(matchedProduct, true));
      return;
    }

    // Buscar en barcodes adicionales
    final matchedBarcode = bloc.allBarcodeInventario.firstWhere(
      (b) => b.barcode?.toLowerCase() == scan,
      orElse: () => BarcodeInventario(),
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
      bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
      bloc.add(ChangeProductIsOkEvent(matchedById, true));

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

// Función auxiliar para eliminar caracteres especiales que causan problemas
  String _normalizeLote(String? text) {
    if (text == null) return '';
    // Convertir a minúsculas y luego reemplazar guiones bajos y guiones por un string vacío
    return text.toLowerCase().replaceAll(RegExp(r'[-_]'), '');
  }

  void validateLote(String value) {
    final bloc = context.read<CreateTransferBloc>();

    // Normalizamos el scan de entrada
    final rawScan =
        (bloc.scannedValue4.isEmpty ? value : bloc.scannedValue4).trim();
    final scan = _normalizeLote(rawScan); // <-- Usamos la nueva función aquí

    print('scan lote normalizado: $scan');
    _controllerLote.clear();

    // Buscar el lote
    LotesProduct? matchedLote = bloc.listLotesProduct.firstWhere(
        // ✅ Normalizamos el nombre del lote ANTES de la comparación
        (lotes) => _normalizeLote(lotes.name) == scan,
        orElse: () => LotesProduct());

    if (matchedLote.name != null) {
      print('lote encontrado: ${matchedLote.name}');
      bloc.add(ValidateFieldsEvent(field: "lote", isOk: true));
      bloc.add(SelectecLoteEvent(matchedLote));
      Future.microtask(() => focusNode5.requestFocus());
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      print('lote no encontrado');
      bloc.add(ValidateFieldsEvent(field: "lote", isOk: false));
      Future.microtask(() => focusNode5.requestFocus());
    }
  }

  void validateQuantity(String value) {
    final bloc = context.read<CreateTransferBloc>();

    String scan = bloc.scannedValue3.trim().toLowerCase() == ""
        ? value.trim().toLowerCase()
        : bloc.scannedValue3.trim().toLowerCase();
    print('scan quantity: $scan');
    _controllerQuantity.clear();
    final currentProduct = bloc.currentProduct;

    if (scan == currentProduct?.barcode?.toLowerCase()) {
      bloc.add(AddQuantitySeparate(currentProduct?.productId ?? 0, 1, false));
      Future.microtask(() => focusNode3.requestFocus());
    } else {
      validateScannedBarcode(
        scan,
        currentProduct ?? Product(),
        bloc,
      );
      Future.microtask(() => focusNode3.requestFocus());
    }
  }

  // Función auxiliar para eliminar caracteres especiales que causan problemas
  String _normalizeScan(String? text) {
    if (text == null) return '';
    // Convertir a minúsculas y eliminar guiones bajos y guiones.
    return text.toLowerCase().replaceAll(RegExp(r'[-_]'), '');
  }

  bool validateScannedBarcode(
    String scannedBarcode,
    Product currentProduct,
    CreateTransferBloc bloc,
  ) {
    // 1. Normalizar el barcode escaneado
    final normalizedScan = _normalizeScan(scannedBarcode);

    // Si el escaneo normalizado está vacío, no hacemos nada
    if (normalizedScan.isEmpty) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      return false;
    }

    // 2. Buscar el barcode normalizado
    BarcodeInventario? matchedBarcode = bloc.listOfBarcodes.firstWhere(
        // ✅ Normalizar el barcode de la lista antes de comparar
        (barcode) => _normalizeScan(barcode.barcode) == normalizedScan,
        orElse: () => BarcodeInventario());

    if (matchedBarcode.barcode != null) {
      // Éxito
      bloc.add(AddQuantitySeparate(
          currentProduct.productId ?? 0, matchedBarcode.cantidad, false));
      return true;
    }

    // Fallo
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return BlocConsumer<CreateTransferBloc, CreateTransferState>(
      listener: (context, state) {
        print('🔔 Estado actual: $state');

        if (state is ValidateStockFailure) {
          showScrollableErrorDialog(state.error);
        } else if (state is CreateTransferFailure) {
          showScrollableErrorDialog(state.error);
        } else

        //estado para cuando estamos agregando un producto a la transferencia
        if (state is ProductAddingToTransferLoadingState) {
          showDialog(
            context: context,
            builder: (context) =>
                const DialogLoading(message: "Agregando producto..."),
          );
        } else
        //estado para cuando agregamos un producto a la transferencia
        if (state is ProductAddedToTransferState) {
          Navigator.pop(context); //cerramos el dialog de carga
          Get.snackbar(
            '360 Software Informa',
            'Producto agregado a la transferencia correctamente',
            backgroundColor: white,
            colorText: primaryColorApp,
            duration: const Duration(milliseconds: 1000),
            icon: Icon(Icons.check_circle, color: Colors.green),
            snackPosition: SnackPosition.TOP,
          );
        } else {
          //*estado cuando la ubicacion de origen es cambiada, pasamos a ubicacion de destino
          if (state is ChangeLocationIsOkState) {
            //cambiamos el foco
            if (state.isLocationDest == false) {
              /// si es origien pasamos a destino
              Future.delayed(const Duration(seconds: 1), () {
                FocusScope.of(context).requestFocus(focusNode6);
              });
              _handleDependencies();
            } else {
              // si es destino pasamos a producto
              Future.delayed(const Duration(seconds: 1), () {
                FocusScope.of(context).requestFocus(focusNode2);
              });
              _handleDependencies();
            }
          }
          //*estado cuando el producto es leido ok
          else if (state is ChangeProductOrderIsOkState) {
            //validamos si el producto tiene lote, si es asi pasamos el foco al lote
            if (context.read<CreateTransferBloc>().currentProduct?.tracking ==
                "lot") {
              Future.delayed(const Duration(seconds: 1), () {
                FocusScope.of(context).requestFocus(focusNode5);
              });
            } else {
              Future.delayed(const Duration(seconds: 1), () {
                FocusScope.of(context).requestFocus(focusNode3);
              });
            }
            _handleDependencies();
          } else if (state is ChangeQuantityIsOkState) {
            _handleDependencies();
          } else if (state is ChangeLoteIsOkState) {
            //cambiamos el foco a cantidad cuando hemos seleccionado un lote
            Future.delayed(const Duration(seconds: 1), () {
              FocusScope.of(context).requestFocus(focusNode3);
            });
            _handleDependencies();
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
          } else if (state is ClearDataCreateTransferLoadingState) {
            showDialog(
              context: context,
              builder: (context) =>
                  const DialogLoading(message: "Limpiando datos..."),
            );
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.pop(context);
            });
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
            backgroundColor: white,
            body: Column(
              children: [
                //*AppBar
                Container(
                  decoration: BoxDecoration(
                    color: primaryColorApp,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  width: double.infinity,
                  child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                      builder: (context, status) {
                    return Column(
                      children: [
                        const WarningWidgetCubit(),
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: 0,
                              top: status != ConnectionStatus.online ? 0 : 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.arrow_back, color: white),
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    'transferencias',
                                  );
                                },
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(left: size.width * 0.12),
                                child: const Text("CREAR TRANSFERENCIA",
                                    style:
                                        TextStyle(color: white, fontSize: 18)),
                              ),
                              const Spacer(),
                              PopupMenuCreateTransferWidget()
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(top: 2),
                    child: SingleChildScrollView(
                      child: Column(children: [
                        //todo ubicacion de origen
                        LocationScannerAll(
                          isLocationOk:
                              context.read<CreateTransferBloc>().isLocationOk,
                          locationIsOk:
                              context.read<CreateTransferBloc>().locationIsOk,
                          productIsOk:
                              context.read<CreateTransferBloc>().productIsOk,
                          quantityIsOk:
                              context.read<CreateTransferBloc>().quantityIsOk,
                          currentLocationName: context
                              .read<CreateTransferBloc>()
                              .currentUbication
                              ?.name,
                          onLocationScanned: (value) {
                            validateLocation(value);
                          },
                          focusNode: focusNode1,
                          controller: _controllerLocation,
                          locationDropdown: LocationCardButtonCreateTransfer(
                            bloc: context.read<
                                CreateTransferBloc>(), // Tu instancia de BLoC/Controlador
                            cardColor:
                                white, // Asegúrate que 'white' esté definido en tus colores
                            textAndIconColor:
                                primaryColorApp, // Usa tu color primario
                            title: 'Ubicación Origen',
                            routeName: 'search-location-create-transfer',
                            ubicacionFija: true,
                            isLocationDest: false,
                          ), // Pasamos el widget del dropdown como parámetro
                        ),

                        //todo ubicacion destino
                        LocationScannerAll(
                          isLocationOk: context
                              .read<CreateTransferBloc>()
                              .isLocationDestOk,
                          locationIsOk: context
                              .read<CreateTransferBloc>()
                              .locationDestIsOk,
                          productIsOk:
                              context.read<CreateTransferBloc>().productIsOk,
                          quantityIsOk:
                              context.read<CreateTransferBloc>().quantityIsOk,
                          currentLocationName: context
                              .read<CreateTransferBloc>()
                              .currentUbicationDest
                              ?.name,
                          onLocationScanned: (value) {
                            validateLocationDest(value);
                          },
                          focusNode: focusNode6,
                          controller: _controllerLocationDestino,
                          locationDropdown: LocationCardButtonCreateTransfer(
                            bloc: context.read<
                                CreateTransferBloc>(), // Tu instancia de BLoC/Controlador
                            cardColor:
                                white, // Asegúrate que 'white' esté definido en tus colores
                            textAndIconColor:
                                primaryColorApp, // Usa tu color primario
                            title: 'Ubicación Destino',
                            routeName: 'search-location-create-transfer',
                            ubicacionFija: true,
                            isLocationDest: true,
                          ), // Pasamos el widget del dropdown como parámetro
                        ),

                        //todo: producto
                        ProductScannerAll(
                          isCreateTransfer: true,
                          focusNode: focusNode2,
                          controller: _controllerProduct,
                          locationIsOk:
                              context.read<CreateTransferBloc>().locationIsOk,
                          productIsOk:
                              context.read<CreateTransferBloc>().productIsOk,
                          quantityIsOk:
                              context.read<CreateTransferBloc>().quantityIsOk,
                          isProductOk:
                              context.read<CreateTransferBloc>().isProductOk,
                          currentProduct:
                              context.read<CreateTransferBloc>().currentProduct,
                          onValidateProduct: (value) {
                            validateProduct(value);
                          },
                          productDropdown:
                              ProductDropdownCreateTransferWidget(),
                        ),

                        //todo lote
                        Visibility(
                          // El padre controla la visibilidad
                          visible: context
                                  .read<CreateTransferBloc>()
                                  .currentProduct
                                  ?.tracking ==
                              "lot",
                          child: LoteScannerWidget(
                            routeName: 'search-lote-create-transfer',
                            focusNode: focusNode5,
                            controller: _controllerLote,
                            isLoteOk:
                                context.read<CreateTransferBloc>().isLoteOk,
                            loteIsOk:
                                context.read<CreateTransferBloc>().loteIsOk,
                            locationIsOk:
                                context.read<CreateTransferBloc>().locationIsOk,
                            productIsOk:
                                context.read<CreateTransferBloc>().productIsOk,
                            quantityIsOk:
                                context.read<CreateTransferBloc>().quantityIsOk,
                            viewQuantity:
                                context.read<CreateTransferBloc>().viewQuantity,
                            currentProduct: context
                                .read<CreateTransferBloc>()
                                .currentProduct,
                            currentProductLote: context
                                .read<CreateTransferBloc>()
                                .currentProductLote,
                            onValidateLote: (value) {
                              validateLote(value);
                            },
                          ),
                        ),
                      ]),
                    ),
                  ),
                )

                //todo: cantidad
                ,
                QuantityScannerWidget(
                  size: size,
                  isQuantityOk: context.read<CreateTransferBloc>().isQuantityOk,
                  quantityIsOk: context.read<CreateTransferBloc>().quantityIsOk,
                  locationIsOk: context.read<CreateTransferBloc>().locationIsOk,
                  productIsOk: context.read<CreateTransferBloc>().productIsOk,
                  locationDestIsOk: false,
                  totalQuantity: 0,
                  quantitySelected:
                      context.read<CreateTransferBloc>().quantitySelected,
                  unidades:
                      context.read<CreateTransferBloc>().currentProduct?.uom ??
                          "",
                  controller: _controllerQuantity,
                  manualController: cantidadController,
                  scannerFocusNode: focusNode3,
                  manualFocusNode: focusNode4,
                  viewQuantity: context.read<CreateTransferBloc>().viewQuantity,
                  onIconButtonPressed: () {
                    print('borrando');
                    context.read<CreateTransferBloc>().add(ShowQuantityEvent(
                        !context.read<CreateTransferBloc>().viewQuantity));
                    Future.delayed(const Duration(milliseconds: 100), () {
                      FocusScope.of(context).requestFocus(focusNode3);
                    });
                  },
                  showKeyboard:
                      context.read<UserBloc>().fabricante.contains("Zebra"),
                  onToggleViewQuantity: () {
                    context.read<CreateTransferBloc>().add(ShowQuantityEvent(
                        !context.read<CreateTransferBloc>().viewQuantity));
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

                    context
                        .read<CreateTransferBloc>()
                        .add(ChangeQuantitySeparate(
                          intValue,
                          context
                                  .read<CreateTransferBloc>()
                                  .currentProduct
                                  ?.productId ??
                              0,
                        ));

                    context.read<CreateTransferBloc>().add(ShowQuantityEvent(
                        !context.read<CreateTransferBloc>().viewQuantity));
                  },
                  isViewCant: false,
                ),
              ],
            ));
      },
    );
  }

  void _validatebuttonquantity() {
    final bloc = context.read<CreateTransferBloc>();

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

    if (cantidad <= 0.0 || cantidad <= 0) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        'Error',
        'La cantidad debe ser mayor que cero',
        backgroundColor: white,
        colorText: primaryColorApp,
        duration: const Duration(milliseconds: 1000),
        icon: Icon(Icons.error, color: Colors.amber),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (bloc.currentProduct?.tracking == 'lot') {
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
        //validamos el stock del producto con lote antes de agregar a la transferencia
        bloc.add(ValidateStockProductEvent(cantidad));
      }
    } else {
      double cantidad = double.parse(cantidadController.text.isEmpty
          ? bloc.quantitySelected.toString()
          : cantidadController.text);
      print("cantidad: $cantidad");
      bloc.add(ValidateStockProductEvent(cantidad));
    }
  }
}
