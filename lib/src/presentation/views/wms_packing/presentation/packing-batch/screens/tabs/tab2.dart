// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/dialog_confirmated_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class Tab2Screen extends StatefulWidget {
  const Tab2Screen({super.key, this.packingModel, this.batchModel});

  final PedidoPacking? packingModel;
  final BatchPackingModel? batchModel;

  @override
  State<Tab2Screen> createState() => _Tab2ScreenState();
}

class _Tab2ScreenState extends State<Tab2Screen> {
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
    final bloc = context.read<WmsPackingBloc>();

    // Normalizamos el valor escaneado
    final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    print('🔎 Scan barcode (packing batch): $scan');

    final listOfProducts = bloc.listOfProductosProgress;

    /// Función auxiliar para procesar el producto encontrado
    /// Función auxiliar para procesar el producto encontrado
    void processProduct(ProductoPedido product) {
      bloc
        ..add(FetchProductEvent(product))
        ..add(ChangeLocationIsOkEvent(
          product.idProduct ?? 0,
          product.pedidoId ?? 0,
          product.idMove ?? 0,
        ))
        ..add(ChangeProductIsOkEvent(
          true,
          product.idProduct ?? 0,
          product.pedidoId ?? 0,
          0,
          product.idMove ?? 0,
        ))
        ..add(ChangeIsOkQuantity(
          true,
          product.idProduct ?? 0,
          product.pedidoId ?? 0,
          product.idMove ?? 0,
        ))
        ..add(ClearScannedValuePackEvent('toDo'));

      // 1. Eliminamos la variable 'dialogContext' y su captura manual.

      showDialog(
        context: context,
        barrierDismissible:
            false, // Bloquea que el usuario lo cierre tocando afuera
        builder: (ctx) {
          return const DialogLoading(
            message: 'Cargando información del producto...',
          );
        },
      );

      Future.delayed(const Duration(seconds: 1), () {
        // Verifica si la pantalla Tab2Screen sigue montada
        if (!mounted) return;

        // 2. SOLUCIÓN: Usamos el 'context' general de la clase (Tab2Screen).
        // Navigator.pop() cierra la ruta superior de la pila, que es el Dialog que acabamos de abrir.
        Navigator.of(context).pop();

        // 3. Navegación a la siguiente vista
        Navigator.pushReplacementNamed(
          context,
          'Packing',
          arguments: [widget.packingModel, widget.batchModel],
        );
      });

      print('✅ Producto procesado: ${product.toMap()}');
    }

    // 1️⃣ Buscar por código de barras principal
    final product = listOfProducts.firstWhere(
      (p) =>
          p.barcode?.toLowerCase() == scan ||
          p.productCode?.toLowerCase() == scan,
      orElse: () => ProductoPedido(),
    );

    if (product.idMove != null) {
      processProduct(product);
      return;
    }

    // 2️⃣ Buscar por barcodes secundarios
    final barcode = bloc.listAllOfBarcodes.firstWhere(
      (b) => b.barcode?.toLowerCase() == scan,
      orElse: () => Barcodes(),
    );

    if (barcode.barcode != null) {
      final productByBarcode = listOfProducts.firstWhere(
        (p) => p.idProduct.toString() == barcode.idProduct.toString(),
        orElse: () => ProductoPedido(),
      );

      if (productByBarcode.idProduct != null) {
        processProduct(productByBarcode);
        return;
      }
    }

    _audioService.playErrorSound();
    _vibrationService.vibrate();

    // 3️⃣ Si no se encuentra nada → mostrar error
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Código erróneo"),
      backgroundColor: Colors.red[200],
      duration: const Duration(milliseconds: 500),
    ));
    bloc.add(ClearScannedValuePackEvent('toDo'));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<WmsPackingBloc, WmsPackingState>(
      listener: (context, state) {
        print('state: $state');
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton: context
                      .read<WmsPackingBloc>()
                      .configurations
                      .result
                      ?.result
                      ?.scanProduct ==
                  true
              ? Stack(
                  children: [
                    // El FloatingActionButton
                    Positioned(
                      bottom:
                          0.0, // Ajusta según sea necesario para colocar en la parte inferior
                      right:
                          0.0, // Ajusta según sea necesario para colocar en la parte derecha
                      child: FloatingActionButton(
                        onPressed: context
                                .read<WmsPackingBloc>()
                                .listOfProductosProgress
                                .isEmpty
                            ? null
                            : () {
                                //cerramos el teclado
                                context
                                    .read<WmsPackingBloc>()
                                    .add(ChangeStickerEvent(false));

                                FocusScope.of(context).unfocus();

                                showDialog(
                                  context: context,
                                  builder: (_) {
                                    final bloc = context.read<WmsPackingBloc>();
                                    return DialogConfirmatedPacking(
                                      productos: context
                                          .read<WmsPackingBloc>()
                                          .listOfProductsForPacking,
                                      isCertificate: false,
                                      isSticker: bloc.isSticker,
                                      onToggleSticker: (value) {
                                        bloc.add(ChangeStickerEvent(value));
                                      },
                                      onConfirm: () {
                                        bloc.add(SetPackingsEvent(
                                            context
                                                .read<WmsPackingBloc>()
                                                .listOfProductsForPacking,
                                            bloc.isSticker,
                                            false));
                                      },
                                    );
                                  },
                                );
                              },
                        backgroundColor: primaryColorApp,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: SvgPicture.asset(
                            color: white,
                            "assets/icons/packing.svg",
                            height: 20,
                            width: 20,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    // El número de productos seleccionados
                    Positioned(
                      bottom: 40.0, // Posición hacia arriba
                      right: 0.0, // Posición hacia la derecha
                      child: context
                              .read<WmsPackingBloc>()
                              .listOfProductsForPacking
                              .isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context
                                    .read<WmsPackingBloc>()
                                    .listOfProductsForPacking
                                    .length
                                    .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const SizedBox
                              .shrink(), // No mostrar el número si no hay productos seleccionados
                    ),
                  ],
                )
              : null,
          body: BlocBuilder<WmsPackingBloc, WmsPackingState>(
            builder: (context, state) {
              return Container(
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
                                  hintStyle: const TextStyle(
                                      fontSize: 14, color: black),
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
                                        context
                                            .read<WmsPackingBloc>()
                                            .scannedValue5,
                                        context);
                                    return KeyEventResult.handled;
                                  } else {
                                    context.read<WmsPackingBloc>().add(
                                        UpdateScannedValuePackEvent(
                                            event.data.keyLabel, 'toDo'));
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Container()),

                      (context
                              .read<WmsPackingBloc>()
                              .listOfProductosProgress
                              .isEmpty)
                          ? Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Text('No hay productos',
                                      style:
                                          TextStyle(fontSize: 14, color: grey)),
                                  const Text('Intente buscar otro producto',
                                      style:
                                          TextStyle(fontSize: 12, color: grey)),
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
                          : Expanded(
                              child: ListView.builder(
                                itemCount: context
                                    .read<WmsPackingBloc>()
                                    .listOfProductosProgress
                                    .length,
                                itemBuilder: (context, index) {
                                  final product = context
                                      .read<WmsPackingBloc>()
                                      .listOfProductosProgress[index];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Card(
                                      // Cambia el color de la tarjeta si el producto está seleccionado
                                      color: context
                                              .read<WmsPackingBloc>()
                                              .listOfProductsForPacking
                                              .contains(product)
                                          ? primaryColorAppLigth // Color amarillo si está seleccionado
                                          : Colors
                                              .white, // Color blanco si no está seleccionado
                                      elevation: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            //* Checkbox para seleccionar o deseleccionar el producto
                                            //* se activa segun el permiso
                                            Visibility(
                                              visible: context
                                                      .read<WmsPackingBloc>()
                                                      .configurations
                                                      .result
                                                      ?.result
                                                      ?.scanProduct ==
                                                  true,
                                              child: Checkbox(
                                                value: context
                                                    .read<WmsPackingBloc>()
                                                    .listOfProductsForPacking
                                                    .contains(product),
                                                onChanged: (bool? selected) {
                                                  if (selected == true) {
                                                    // Seleccionar producto
                                                    context
                                                        .read<WmsPackingBloc>()
                                                        .add(
                                                            SelectProductPackingEvent(
                                                                product));
                                                  } else {
                                                    // Deseleccionar producto
                                                    context
                                                        .read<WmsPackingBloc>()
                                                        .add(
                                                            UnSelectProductPackingEvent(
                                                                product));
                                                  }
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  final bloc = context
                                                      .read<WmsPackingBloc>();
                                                  print(
                                                      "Producto seleccionado: ${product.toMap()}");
                                                  // 1. VALIDACIÓN DEFENSIVA: Verificar si el producto ya está en estado 'preparado'
                                                  if (bloc.productsDone.any(
                                                      (doneProduct) =>
                                                          doneProduct.idMove ==
                                                          product.idMove)) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                      content: const Text(
                                                          "Este producto se encuentra en estado preparado, por favor seleccione otro"),
                                                      backgroundColor:
                                                          Colors.red[200],
                                                    ));
                                                    return; // Salimos de la función
                                                  }

                                                  // 2. DISPARAR EVENTO DE CARGA DE DATOS
                                                  // Esto inicia la operación asíncrona que tu BLoC debe resolver (ej. traer los productos del pedido)
                                                  bloc.add(FetchProductEvent(
                                                      product));

                                                  // 3. MOSTRAR DIÁLOGO DE CARGA
                                                  // Usamos Future.microtask para asegurar que el diálogo se muestre antes de la espera
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

                                                  // 4. ✅ SINCRONIZACIÓN CRÍTICA Y NAVEGACIÓN
                                                  // Usamos Future.delayed SÓLO como un tiempo fijo de espera para la API/DB,
                                                  // que es tu mecanismo actual. Si tu BLoC tuviera un Stream de 'Loaded',
                                                  // lo ideal sería usar BlocListener.

                                                  // El retraso de 1000ms da tiempo al BLoC para cambiar de estado (Loaded)
                                                  Future.delayed(
                                                      const Duration(
                                                          milliseconds: 1000),
                                                      () {
                                                    if (mounted) {
                                                      // Chequeo de seguridad de contexto

                                                      // 4.1. Cerrar el diálogo de carga (usando el context del widget, ya que el diálogo fue abierto con él)
                                                      Navigator.of(context,
                                                              rootNavigator:
                                                                  true)
                                                          .pop();

                                                      // 4.2. Navegar a la vista 'Packing' (Línea 450)
                                                      // Se asume que la vista 'Packing' ahora puede usar los datos que el BLoC ya cargó.
                                                      Navigator
                                                          .pushReplacementNamed(
                                                        context,
                                                        'Packing',
                                                        arguments: [
                                                          widget.packingModel,
                                                          widget.batchModel,
                                                        ],
                                                      );
                                                    }
                                                  });
                                                },
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        "${product.productId}",
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: black),
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Ubicación: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        Visibility(
                                                          visible: product
                                                                  .manejaTemperatura ==
                                                              1,
                                                          child: Icon(
                                                            Icons
                                                                .thermostat_outlined,
                                                            color:
                                                                primaryColorApp,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      "${product.locationId}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: black,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Pedido: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        Text(
                                                            "${product.pedidoId}",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        black)),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Cantidad: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        Text(
                                                          (product.isProductSplit == 1 &&
                                                                      product.isSeparate ==
                                                                          1
                                                                  ? product
                                                                      .pendingQuantity
                                                                  : product
                                                                          .quantity ??
                                                                      0.0)
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: black,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        Text(
                                                          "UND Medida: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        Text(
                                                            "${product.unidades}",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        black)),
                                                      ],
                                                    ),
                                                    if (product.tracking ==
                                                        'lot')
                                                      Column(
                                                        children: [
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                              "Número de serie/lote: ",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    primaryColorApp,
                                                              ),
                                                            ),
                                                          ),
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                                "${product.lotId}",
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        black)),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ));
            },
          ),
        );
      },
    );
  }
}
