// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/sounds_utils.dart';
import 'package:wms_app/src/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/location/LocationScanner_widget.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/create-transfer/widgets/locationDest/LocationCardButton_massTransfer_widget.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class CreateMassTrasferScreen extends StatefulWidget {
  const CreateMassTrasferScreen({
    super.key,
  });

  @override
  State<CreateMassTrasferScreen> createState() =>
      _CreateMassTrasferScreenState();
}

class _CreateMassTrasferScreenState extends State<CreateMassTrasferScreen>
    with WidgetsBindingObserver {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

//*focus
  FocusNode focusNode1 = FocusNode(); // ubicacion  destino
  FocusNode focusNode2 = FocusNode(); // producto
  final TextEditingController _controllerLocationDestino =
      TextEditingController();

  final TextEditingController _controllerProduct = TextEditingController();

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
    ]) {
      if (node != except) node.unfocus();
    }
  }

  void _handleDependencies() {
    final bloc = context.read<InfoRapidaBloc>();
    // final hasLote = bloc.currentProduct?.tracking == "lot";
    //mostramos todas las variables de foco y sus condiciones
    print('---------------- Manejo de dependencias ---------------');
    print("ubicación: ${bloc.locationDestIsOk}");
    print("producto: ${bloc.productIsOk}");

    final focusMap = {
      "locationDest": () => !bloc.locationDestIsOk && !bloc.productIsOk,
      "product": () => !bloc.productIsOk && bloc.locationDestIsOk,
    };

    final focusNodeByKey = {
      "locationDest": focusNode1,
      "product": focusNode2,
    };

    for (final entry in focusMap.entries) {
      if (entry.value()) {
        _focus(focusNodeByKey[entry.key]!, entry.key);
        return;
      }
    }

    setState(() {}); // Si necesitas un rebuild explícito
  }

  void validateLocationDest(String value) {
    final bloc = context.read<InfoRapidaBloc>();
    final scan = bloc.scannedValue2.trim().toLowerCase() == ""
        ? value.trim().toLowerCase()
        : bloc.scannedValue2.trim().toLowerCase();

    print('scan location dest: $scan');
    _controllerLocationDestino.clear();

    ResultUbicaciones? matchedUbicacion = bloc.ubicacionesFilters.firstWhere(
        (ubicacion) => ubicacion.barcode?.toLowerCase() == scan.trim(),
        orElse: () =>
            ResultUbicaciones() // Si no se encuentra ningún match, devuelve null
        );

    //validamos que la ubicacion de destino no sea la misma que la de origen
    if (matchedUbicacion.id == bloc.infoRapidaResult?.result?.id) {
      _vibrationService.vibrate();
      _audioService.playErrorSound();
      print('La ubicacion de destino no puede ser la misma que la de origen');
      bloc.add(ValidateFieldsEvent(field: "locationDest", isOk: false));
      bloc.add(ClearScannedValueTransferEvent('locationDest'));
      return;
    }

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

    bloc.add(ClearScannedValueTransferEvent('locationDest'));
  }

  void validateProduct(String value) {
    final bloc = context.read<InfoRapidaBloc>();

    final scan = (bloc.scannedValue2.isEmpty ? value : bloc.scannedValue2)
        .trim()
        .toLowerCase();

    _controllerProduct.clear();
    print('🔎 Scan barcode: $scan');

    // Buscar coincidencia directa por barcode o code
    final matchedProduct = bloc.infoRapidaResult.result?.productos?.firstWhere(
      (p) => p.codigoBarras?.toLowerCase() == scan,
      orElse: () => Producto(),
    );

    if (matchedProduct?.codigoBarras != null) {
      print('✅ producto encontrado directo: ${matchedProduct?.producto}');
      bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
      bloc.add(ChangeProductIsOkEvent(matchedProduct!, true));
      bloc.add(ClearScannedValueTransferEvent('product'));

      return;
    }
    print('❌ Producto no encontrado por ID');
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    bloc
      ..add(ValidateFieldsEvent(field: "product", isOk: false))
      ..add(ClearScannedValueTransferEvent('product'));
    return;
  }

  // Buscar en barcodes adicionales
  // final matchedBarcode = bloc.allBarcodeInventario.firstWhere(
  //   (b) => b.barcode?.toLowerCase() == scan,
  //   orElse: () => BarcodeInventario(),
  // );

  // if (matchedBarcode.barcode == null) {
  //   print('❌ Producto no encontrado en barcodes');
  //   _audioService.playErrorSound();
  //   _vibrationService.vibrate();
  //   bloc
  //     ..add(ValidateFieldsEvent(field: "product", isOk: false))
  //     ..add(ClearScannedValueTransferEvent('product'));
  //   return;
  // }

  // Buscar producto por id relacionado al barcode encontrado
  // final matchedById = bloc.productos.firstWhere(
  //   (p) => p.productId == matchedBarcode.idProduct,
  //   orElse: () => Product(),
  // );

  // if (matchedById.productId != null) {
  //   print('✅ Producto encontrado por ID: ${matchedById.name}');
  //   bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
  //   bloc.add(ChangeProductIsOkEvent(matchedById, true));

  //   return;
  // } else {
  //   print('❌ Producto no encontrado por ID');
  //   _audioService.playErrorSound();
  //   _vibrationService.vibrate();
  //   bloc
  //     ..add(ValidateFieldsEvent(field: "product", isOk: false))
  //     ..add(ClearScannedValueTransferEvent('product'));
  //   return;
  // }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        print('InfoRapidaBloc State: $state');

        //*estado cuando la ubicacion de origen es cambiada, pasamos a ubicacion de destino
        if (state is ChangeLocationIsOkState) {
          //cambiamos el foco
          if (state.isLocationDest == true) {
            // si es destino pasamos a producto
            Future.delayed(const Duration(seconds: 1), () {
              FocusScope.of(context).requestFocus(focusNode2);
            });
            _handleDependencies();
          }
        }

        if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            builder: (context) {
              return const DialogLoading(
                message: "Buscando informacion...",
              );
            },
          );
        }

        if (state is InfoRapidaLoaded) {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, 'location-info',
              arguments: [state.infoRapidaResult]);
        }

        if (state is CreateTransferFailure) {
          showScrollableErrorDialog(state.error);
        } else if (state is CreateTransferSuccess) {
          Get.snackbar(
            '360 Software Informa',
            'Transferencia creada con éxito',
            backgroundColor: Colors.white,
            colorText: primaryColorApp,
            icon: Icon(Icons.check_circle, color: green),
          );
        }

        if (state is ChangeProductOrderIsOkFailure) {
          Get.snackbar(
            '360 Software Informa',
            state.error,
            backgroundColor: Colors.white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: white,
          body: Column(
            children: [
              //APPBAR
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
                              icon: const Icon(Icons.arrow_back, color: white),
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  'location-info',
                                  arguments: [
                                    context
                                        .read<InfoRapidaBloc>()
                                        .infoRapidaResult
                                  ],
                                );
                              },
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: size.width * 0.12),
                              child: const Text("TRANSFERENCIA MASIVA",
                                  style: TextStyle(color: white, fontSize: 18)),
                            ),
                            const Spacer(),
                            //icono de refresh
                            IconButton(
                              icon: const Icon(Icons.refresh, color: white),
                              onPressed: () {
                                //volvemos asignar los productos filtrados a la lista de productos
                                context.read<InfoRapidaBloc>().add(
                                    ResetProductsFiltersMassTransferEvent());

                                Navigator.pushReplacementNamed(
                                  context,
                                  'location-info',
                                  arguments: [
                                    context
                                        .read<InfoRapidaBloc>()
                                        .infoRapidaResult
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
              //INFOR GENERAL
              Container(
                padding: const EdgeInsets.only(top: 2),
                child: SingleChildScrollView(
                  child: Column(children: [
                    //todo ubicacion de origen
                    LocationScannerAll(
                        isLocationOk: true,
                        locationIsOk: true,
                        productIsOk: true,
                        quantityIsOk: true,
                        currentLocationName: '_',
                        onLocationScanned: (value) {},
                        onKeyScanned: (keyLabel) {},
                        focusNode: FocusNode(),
                        controller: TextEditingController(),
                        locationDropdown: Column(
                          children: [
                            Card(
                              color: white,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Row(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Ubicación Origen',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: primaryColorApp,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Image.asset(
                                      'assets/icons/ubicacion.png',
                                      color: primaryColorApp,
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context
                                            .read<InfoRapidaBloc>()
                                            .infoRapidaResult
                                            .result
                                            ?.nombreCompleto ??
                                        'Sin nombre ',
                                    style: TextStyle(
                                        color: black, fontSize: 14),
                                  )),
                            ),
                          
                            const SizedBox(height: 5),
                          ],
                        )),

                    //todo ubicacion destino
                    LocationScannerAll(
                      isLocationOk: true,
                      locationIsOk:
                          context.read<InfoRapidaBloc>().locationDestIsOk,
                      productIsOk: true,
                      quantityIsOk: true,
                      currentLocationName: 'Esperando escaneo',
                      onLocationScanned: (value) {
                        validateLocationDest(value);
                      },
                      onKeyScanned: (keyLabel) {
                        context.read<InfoRapidaBloc>().add(
                            UpdateScannedValueEvent(keyLabel, 'locationDest'));
                      },
                      focusNode: focusNode1,
                      controller: _controllerLocationDestino,
                      locationDropdown: LocationCardButtonCreateMassTransfer(
                        bloc: context.read<
                            InfoRapidaBloc>(), // Tu instancia de BLoC/Controlador
                        cardColor:
                            white, // Asegúrate que 'white' esté definido en tus colores
                        textAndIconColor:
                            primaryColorApp, // Usa tu color primario
                        title: 'Ubicación Destino',
                        routeName: 'search-location-create-mass-transfer',
                        ubicacionFija: true,
                        isLocationDest: true,
                      ), // Pasamos el widget del dropdown como parámetro
                    ),
                  ]),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                      'Productos a transferir (${context.read<InfoRapidaBloc>().productosFiltersMassTransfer.length})',
                      style: TextStyle(fontSize: 15, color: primaryColorApp)),
                ),
              ),

              //*espacio para escanear y buscar el producto

              context.read<UserBloc>().fabricante.contains("Zebra")
                  ? Container(
                      height: 15,
                      margin: const EdgeInsets.only(bottom: 5),
                      child: TextFormField(
                        autofocus: true,
                        showCursor: false,
                        controller: _controllerProduct,
                        focusNode: focusNode2,
                        onChanged: (value) {
                          // Llamamos a la validación al cambiar el texto
                          validateProduct(
                            value,
                          );
                        },
                        decoration: InputDecoration(
                          disabledBorder: InputBorder.none,
                          hintStyle:
                              const TextStyle(fontSize: 14, color: black),
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  :

                  //*focus para leer los productos
                  Focus(
                      focusNode: focusNode2,
                      autofocus: true,
                      onKey: (FocusNode node, RawKeyEvent event) {
                        if (event is RawKeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter) {
                            validateProduct(
                                context.read<InfoRapidaBloc>().scannedValue3);
                            return KeyEventResult.handled;
                          } else {
                            context.read<InfoRapidaBloc>().add(
                                UpdateScannedValueEvent(
                                    event.data.keyLabel, 'product'));
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Container()),

              (context
                      .read<InfoRapidaBloc>()
                      .productosFiltersMassTransfer
                      .isEmpty)
                  ? Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Text('No hay productos agregados',
                              style: TextStyle(fontSize: 14, color: grey)),
                          const Text(
                              'Intente agregar productos a la transferencia',
                              style: TextStyle(fontSize: 12, color: grey)),
                        ],
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                      itemCount: context
                          .read<InfoRapidaBloc>()
                          .productosFiltersMassTransfer
                          .length,
                      padding: EdgeInsets.only(top: 0, left: 10, right: 10),
                      itemBuilder: (context, index) {
                        final product = context
                            .read<InfoRapidaBloc>()
                            .productosFiltersMassTransfer[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: GestureDetector(
                            onTap: () {
                              print(product.toMap());
                            },
                            child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Producto:",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              //dialogo de confirmcion de eliminar
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    title: Center(
                                                      child: const Text(
                                                        'Eliminar producto',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Text(
                                                          '¿Está seguro de que desea eliminar este producto?',
                                                          style: TextStyle(
                                                              color: black),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: <Widget>[
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor: grey,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Cancelar',
                                                          style: TextStyle(
                                                              color: white),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          context
                                                              .read<
                                                                  InfoRapidaBloc>()
                                                              .add(RemoveProductFromMassTransferEvent(
                                                                  product.id ??
                                                                      0));
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              primaryColorApp,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Eliminar',
                                                          style: TextStyle(
                                                              color: white),
                                                        ),
                                                      )
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: const Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "${product.producto}",
                                          style: const TextStyle(
                                              fontSize: 12, color: black),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Lote: ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text(
                                            product.lote == null ||
                                                    product.lote == ""
                                                ? "Sin lote"
                                                : "${product.lote}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: product.lote == null ||
                                                        product.lote == ""
                                                    ? red
                                                    : black),
                                          ),
                                        ],
                                      ),
                                      //fecha de vencimiento
                                      Row(children: [
                                        Text(
                                          "Caducidad: ",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp,
                                          ),
                                        ),
                                        Text(
                                          product.fechaVencimiento == null ||
                                                  product.fechaVencimiento == ""
                                              ? "Sin caducidad"
                                              : "${product.fechaVencimiento}",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: product.fechaVencimiento ==
                                                          null ||
                                                      product.fechaVencimiento ==
                                                          ""
                                                  ? red
                                                  : black),
                                        ),
                                      ]),

                                      Row(
                                        children: [
                                          Text(
                                            "Barcode: ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              product.codigoBarras == null ||
                                                      product.codigoBarras == ""
                                                  ? "Sin barcode"
                                                  : "${product.codigoBarras}",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: product.codigoBarras ==
                                                              null ||
                                                          product.codigoBarras ==
                                                              ""
                                                      ? red
                                                      : black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Cantidad: ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              product.cantidad == null
                                                  ? "0.0"
                                                  : "${product.cantidad}",
                                              style: const TextStyle(
                                                  fontSize: 12, color: black),
                                            ),
                                          ),
                                          const Spacer(),
                                          //unidad
                                          Text(
                                            "Unidad: ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text(
                                            product.unidadMedida == null
                                                ? "Sin unidad"
                                                : "${product.unidadMedida}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: product.unidadMedida ==
                                                            null ||
                                                        product.unidadMedida ==
                                                            ""
                                                    ? red
                                                    : black),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )),
                          ),
                        );
                      },
                    )),

              //btn de crear transferencia
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColorApp,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    //validamso que tengamos productos en la lista
                    if (context
                        .read<InfoRapidaBloc>()
                        .productosFiltersMassTransfer
                        .isEmpty) {
                      Get.snackbar(
                        '360 Software Informa',
                        'No hay productos para crear la transferencia',
                        backgroundColor: Colors.white,
                        colorText: primaryColorApp,
                        icon: Icon(Icons.warning, color: red),
                      );
                      return;
                    }

                    //validamso que tengamos una ubicacion de origen
                    if (context
                                .read<InfoRapidaBloc>()
                                .infoRapidaResult
                                .result
                                ?.nombre ==
                            null ||
                        context
                                .read<InfoRapidaBloc>()
                                .infoRapidaResult
                                .result
                                ?.nombre ==
                            "") {
                      Get.snackbar(
                        '360 Software Informa',
                        'Debe seleccionar una ubicación de origen',
                        backgroundColor: Colors.white,
                        colorText: primaryColorApp,
                        icon: Icon(Icons.warning, color: red),
                      );
                      return;
                    }

                    //validamso que tengamos una ubicacion de destino
                    if (context
                                .read<InfoRapidaBloc>()
                                .currentUbicationDest
                                ?.id ==
                            null ||
                        context
                                .read<InfoRapidaBloc>()
                                .currentUbicationDest
                                ?.id ==
                            0) {
                      Get.snackbar(
                        '360 Software Informa',
                        'Debe seleccionar una ubicación de destino',
                        backgroundColor: Colors.white,
                        colorText: primaryColorApp,
                        icon: Icon(Icons.warning, color: red),
                      );
                      return;
                    }

                    //si todo esta ok, creamos la transferencia
                    context
                        .read<InfoRapidaBloc>()
                        .add(CreateNewMassTransferEvent());
                  },
                  child: Text(
                    "Crear transferencia",
                    style: TextStyle(color: white),
                  )),
              const SizedBox(
                height: 10,
              )
            ],
          ),
        );
      },
    );
  }

  String convertirTiempo(String tiempoStr) {
    // Convertimos el string a un double
    double segundos = double.tryParse(tiempoStr) ?? 0.0;
    // Calculamos horas, minutos y segundos
    int horas = (segundos / 3600).floor(); // 3600 segundos = 1 hora
    int minutos =
        ((segundos % 3600) / 60).floor(); // Resto de segundos dividido entre 60
    int segundosRestantes = (segundos % 60).round(); // Resto de segundos
    // Formateamos los valores en 2 dígitos (ej. 01, 02, etc.)
    String horasStr = horas.toString().padLeft(2, '0');
    String minutosStr = minutos.toString().padLeft(2, '0');
    String segundosStr = segundosRestantes.toString().padLeft(2, '0');

    return '$horasStr:$minutosStr:$segundosStr';
  }
}
