// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously, prefer_is_empty

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab2ScreenRecep extends StatefulWidget {
  const Tab2ScreenRecep({
    super.key,
    required this.ordenCompra,
  });

  final ResultEntrada? ordenCompra;

  @override
  State<Tab2ScreenRecep> createState() => _Tab2ScreenRecepState();
}

class _Tab2ScreenRecepState extends State<Tab2ScreenRecep> {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

  FocusNode focusNode1 = FocusNode(); //cantidad textformfield

  final TextEditingController _controllerToDo = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FocusScope.of(context).requestFocus(focusNode1);
  }

  @override
  void dispose() {
    focusNode1.dispose();
    super.dispose();
  }

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<RecepcionBloc>();

    // Normalizar el valor escaneado
    final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    print('🔎 Scan barcode: $scan');

    // Filtrar productos válidos
    final listOfProducts = bloc.listProductsEntrada
        .where(
          (p) =>
              (p.isSeparate == 0 || p.isSeparate == null) &&
              (p.isDoneItem == 0 || p.isDoneItem == null),
        )
        .toList();

    /// Función auxiliar para procesar un producto encontrado
    /// Función auxiliar para procesar un producto encontrado
    void processProduct(LineasTransferencia product) {
      // Variable para almacenar el contexto creado por showDialog
      BuildContext? dialogContext;

      // Disparar eventos del BLoC (sin cambios)
      bloc
        ..add(ValidateFieldsOrderEvent(field: "product", isOk: true))
        ..add(ChangeQuantitySeparate(
          0,
          int.parse(product.productId),
          product.idRecepcion ?? 0,
          product.idMove ?? 0,
        ))
        ..add(ChangeProductIsOkEvent(
          product.idRecepcion ?? 0,
          true,
          int.parse(product.productId),
          0,
          product.idMove ?? 0,
        ))
        ..add(FetchPorductOrder(product))
        ..add(ClearScannedValueOrderEvent('toDo'));

      // 1. ABRIR DIÁLOGO Y CAPTURAR SU CONTEXTO
      showDialog(
        context: context,
        builder: (ctx) {
          // ✅ Capturamos el contexto del diálogo como 'ctx'
          dialogContext = ctx; // Almacenamos la referencia
          return const DialogLoading(
            message: 'Cargando información del producto...',
          );
        },
      );

      // 2. TEMPORIZADOR PARA CERRAR Y NAVEGAR
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        // 3. ✅ CORRECCIÓN CLAVE: Usar el contexto capturado para el POP
        if (dialogContext != null && dialogContext!.mounted) {
          // El 'pop' ahora es seguro y usa el contexto válido del diálogo
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }

        // 4. Navegación a la siguiente vista
        Navigator.pushReplacementNamed(
          context,
          'scan-product-order',
          arguments: [widget.ordenCompra, product],
        );
      });

      print('✅ Producto procesado: ${product.toMap()}');
    }

// ... (El resto de tu función validateBarcode sin cambios)

    // 1️⃣ Buscar producto por código de barras principal
    final product = listOfProducts.firstWhere(
      (p) =>
          p.productBarcode?.toLowerCase() == scan ||
          p.productCode?.toLowerCase() == scan,
      orElse: () => LineasTransferencia(),
    );

    if (product.idMove != null) {
      processProduct(product);
      return;
    }

    // 2️⃣ Buscar en lista de barcodes asociados
    final barcode = bloc.listAllOfBarcodes.firstWhere(
      (b) => b.barcode?.toLowerCase() == scan,
      orElse: () => Barcodes(),
    );

    if (barcode.barcode != null) {
      final productByBarcode = listOfProducts.firstWhere(
        (p) => p.productId.toString() == barcode.idProduct.toString(),
        orElse: () => LineasTransferencia(),
      );

      if (productByBarcode.productId != null) {
        processProduct(productByBarcode);
        return;
      }
    }

    _vibrationService.vibrate();
    _audioService.playErrorSound();

    // 3️⃣ Si no se encuentra nada → mostrar error
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Código erróneo"),
      backgroundColor: Colors.red[200],
      duration: const Duration(milliseconds: 500),
    ));
    bloc.add(ClearScannedValueOrderEvent('toDo'));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<RecepcionBloc, RecepcionState>(
        listener: (context, state) {
          if (state is SendProductToOrderFailure) {
            showScrollableErrorDialog(state.error);
          }
        },
        builder: (context, state) {
          final recepcionBloc = context.read<RecepcionBloc>();
          return Scaffold(
            backgroundColor: white,
            body: Container(
              margin: const EdgeInsets.only(top: 5),
              width: double.infinity,
              height: size.height * 0.8,
              child: Column(
                children: [
                  //*espacio para escanear y buscar el producto

                  context.read<UserBloc>().fabricante.contains("Zebra")
                      ? Container(
                          height: 15,
                          margin: const EdgeInsets.only(bottom: 5),
                          child: TextFormField(
                            autofocus: true,
                            showCursor: false,
                            controller: _controllerToDo,
                            focusNode: focusNode1,
                            onChanged: (value) {
                              // Llamamos a la validación al cambiar el texto
                              validateBarcode(value, context);
                            },
                            decoration: InputDecoration(
                              // hintText:
                              //     batchBloc.currentProduct.locationId.toString(),
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
                          focusNode: focusNode1,
                          autofocus: true,
                          onKey: (FocusNode node, RawKeyEvent event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.enter) {
                                validateBarcode(
                                    context.read<RecepcionBloc>().scannedValue5,
                                    context);
                                return KeyEventResult.handled;
                              } else {
                                context.read<RecepcionBloc>().add(
                                    UpdateScannedValueOrderEvent(
                                        event.data.keyLabel, 'toDo'));
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Container()),

                  (recepcionBloc.listProductsEntrada.where((element) {
                            return (element.isSeparate == 0 ||
                                    element.isSeparate == null) &&
                                (element.isDoneItem == 0 ||
                                    element.isDoneItem == null);
                          }).length ==
                          0)
                      ? Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Text('No hay productos',
                                  style: TextStyle(fontSize: 14, color: grey)),
                              const Text('Intente buscar otro producto',
                                  style: TextStyle(fontSize: 12, color: grey)),
                              Visibility(
                                visible: context
                                    .read<UserBloc>()
                                    .fabricante
                                    .contains("Zebra"),
                                child: Container(
                                  height: 60,
                                ),
                              ),
                            ],
                          ),
                        )
                      :
                      // :
                      Expanded(
                          child: ListView.builder(
                            itemCount: recepcionBloc.listProductsEntrada
                                .where((element) {
                              return (element.isSeparate == 0 ||
                                      element.isSeparate == null) &&
                                  (element.isDoneItem == 0 ||
                                      element.isDoneItem == null);
                            }).length,
                            itemBuilder: (context, index) {
                              final product = recepcionBloc
                                  .listProductsEntrada //recepcionBloc.listProductsEntrada
                                  .where((element) {
                                return (element.isSeparate == 0 ||
                                        element.isSeparate == null) &&
                                    (element.isDoneItem == 0 ||
                                        element.isDoneItem == null);
                              }).elementAt(index);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Card(
                                  // color: white,
                                  // Cambia el color de la tarjeta si el producto está seleccionado
                                  color: product.isSelected == 1
                                      ? primaryColorAppLigth // Color amarillo si está seleccionado
                                      : Colors
                                          .white, // Color blanco si no está seleccionado
                                  elevation: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () async {
                                        context
                                            .read<RecepcionBloc>()
                                            .add(FetchPorductOrder(
                                              product,
                                            ));

                                        Future.microtask(() {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) {
                                              return const DialogLoading(
                                                message:
                                                    'Cargando información del producto...',
                                              );
                                            },
                                          );
                                        });

                                        Future.delayed(
                                            const Duration(milliseconds: 1000),
                                            () {
                                          if (!mounted) return;

                                          // 4.1. Cerrar el diálogo de carga (usando el context del widget, ya que el diálogo fue abierto con él)
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();

                                          // 4.2. Navegar a la vista 'Packing' (Línea 450)
                                          // Se asume que la vista 'Packing' ahora puede usar los datos que el BLoC ya cargó.
                                          Navigator.pushReplacementNamed(
                                            context,
                                            'scan-product-order',
                                            arguments: [
                                              widget.ordenCompra,
                                              product
                                            ],
                                          );
                                        });
                                        print(product.toMap());
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              //icono de temperatura
                                              const Spacer(),
                                              if (product.manejaTemperatura ==
                                                  1)
                                                Icon(
                                                  Icons.thermostat_outlined,
                                                  color: primaryColorApp,
                                                  size: 16,
                                                ),
                                            ],
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "${product.productName}",
                                              style: const TextStyle(
                                                  fontSize: 12, color: black),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "Codigo: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Text("${product.productCode}",
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black)),
                                            ],
                                          ),
                                          Text(
                                            "Ubicación de origen: ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text("${product.locationName}",
                                              style: const TextStyle(
                                                  fontSize: 12, color: black)),
                                          Visibility(
                                            visible: recepcionBloc
                                                    .configurations
                                                    .result
                                                    ?.result
                                                    ?.hideExpectedQty ==
                                                false,
                                            child: Row(
                                              children: [
                                                Text(
                                                  "Cantidad: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                Text(
                                                    "${product.cantidadFaltante}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
