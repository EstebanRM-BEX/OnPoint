// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/sounds_utils.dart';
import 'package:wms_app/src/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/dialog_confirmated_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
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
    final bloc = context.read<PackingConsolidateBloc>();

    // Normalizamos el valor escaneado
    final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    print('🔎 Scan barcode (packing batch): $scan');

    final listOfProducts = bloc.listOfProductosProgress;

    /// Función auxiliar para procesar el producto encontrado
    /// Función auxiliar para procesar el producto encontrado y manejar la navegación.
    void processProduct(ProductoPedido product) {
      // 1. Declarar la variable de contexto para el diálogo
      BuildContext? dialogContext;

      // Disparar eventos del BLoC (Lógica de negocio en cascada)
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

      // 2. ABRIR DIÁLOGO Y CAPTURAR SU CONTEXTO
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext =
              ctx; // ✅ Capturamos la referencia al contexto del diálogo
          return const DialogLoading(
            message: 'Cargando información del producto...',
          );
        },
      );

      // 3. TEMPORIZADOR ASÍNCRONO (Retraso de 1 segundo)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        // 4. ✅ CORRECCIÓN CRÍTICA: Usar el contexto capturado para el POP seguro
        if (dialogContext != null && dialogContext!.mounted) {
          // El 'pop' ahora es seguro y usa el contexto válido del diálogo
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }

        // 5. Navegación a la siguiente vista
        // Esta línea es ahora segura porque el diálogo fue cerrado previamente.
        Navigator.pushReplacementNamed(
          context,
          'scan-product-consolidate',
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
    return BlocConsumer<PackingConsolidateBloc, PackingConsolidateState>(
      listener: (context, state) {
        print('state: $state');
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton: context
                      .read<PackingConsolidateBloc>()
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
                                .read<PackingConsolidateBloc>()
                                .listOfProductosProgress
                                .isEmpty
                            ? null
                            : () {
                                //cerramos el teclado
                                context
                                    .read<PackingConsolidateBloc>()
                                    .add(ChangeStickerEvent(false));

                                FocusScope.of(context).unfocus();

                                showDialog(
                                  context: context,
                                  builder: (_) {
                                    final bloc =
                                        context.read<PackingConsolidateBloc>();
                                    return DialogConfirmatedPacking(
                                      productos: context
                                          .read<PackingConsolidateBloc>()
                                          .listOfProductsForPacking,
                                      isCertificate: false,
                                      isSticker: bloc.isSticker,
                                      onToggleSticker: (value) {
                                        bloc.add(ChangeStickerEvent(value));
                                      },
                                      onConfirm: () {
                                        bloc.add(SetPackingsEvent(
                                            context
                                                .read<PackingConsolidateBloc>()
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
                              .read<PackingConsolidateBloc>()
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
                                    .read<PackingConsolidateBloc>()
                                    .listOfProductsForPacking
                                    .length
                                    .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          : const SizedBox
                              .shrink(), // No mostrar el número si no hay productos seleccionados
                    ),
                  ],
                )
              : null,
          body: BlocBuilder<PackingConsolidateBloc, PackingConsolidateState>(
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
                                            .read<PackingConsolidateBloc>()
                                            .scannedValue5,
                                        context);
                                    return KeyEventResult.handled;
                                  } else {
                                    context.read<PackingConsolidateBloc>().add(
                                        UpdateScannedValuePackEvent(
                                            event.data.keyLabel, 'toDo'));
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Container()),

                      (context
                              .read<PackingConsolidateBloc>()
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
                                    .read<PackingConsolidateBloc>()
                                    .listOfProductosProgress
                                    .length,
                                itemBuilder: (context, index) {
                                  final product = context
                                      .read<PackingConsolidateBloc>()
                                      .listOfProductosProgress[index];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Card(
                                      // Cambia el color de la tarjeta si el producto está seleccionado
                                      color: context
                                              .read<PackingConsolidateBloc>()
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
                                                      .read<
                                                          PackingConsolidateBloc>()
                                                      .configurations
                                                      .result
                                                      ?.result
                                                      ?.scanProduct ==
                                                  true,
                                              child: Checkbox(
                                                value: context
                                                    .read<
                                                        PackingConsolidateBloc>()
                                                    .listOfProductsForPacking
                                                    .contains(product),
                                                onChanged: (bool? selected) {
                                                  if (selected == true) {
                                                    // Seleccionar producto
                                                    context
                                                        .read<
                                                            PackingConsolidateBloc>()
                                                        .add(
                                                            SelectProductPackingEvent(
                                                                product));
                                                  } else {
                                                    // Deseleccionar producto
                                                    context
                                                        .read<
                                                            PackingConsolidateBloc>()
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
                                                  final bloc = context.read<
                                                      PackingConsolidateBloc>();
                                                  print(
                                                      "Producto seleccionado: ${product.toMap()}");

                                                  // 1. VALIDACIÓN DEFENSIVA DE PRODUCTO PREPARADO
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
                                                    return;
                                                  }

                                                  // 2. DISPARAR EVENTO DE CARGA
                                                  bloc.add(FetchProductEvent(
                                                      product));

                                                  // Variable para almacenar el contexto del diálogo
                                                  BuildContext? dialogContext;

                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (ctx) {
                                                      // ✅ CAPTURA DEL CONTEXTO DEL DIÁLOGO
                                                      dialogContext = ctx;
                                                      return const DialogLoading(
                                                        message:
                                                            'Cargando información del producto...',
                                                      );
                                                    },
                                                  );

                                                  // 3. NAVEGACIÓN Y CIERRE ASÍNCRONO SEGURO (Usando un delay corto para el UX)
                                                  Future.delayed(
                                                      const Duration(
                                                          milliseconds: 500),
                                                      () {
                                                    if (mounted) {
                                                      // Chequeo de seguridad del widget principal

                                                      // 3.1. Cierre seguro del diálogo (Corrige el fallo del pop)
                                                      if (dialogContext !=
                                                          null) {
                                                        Navigator.of(
                                                                dialogContext!,
                                                                rootNavigator:
                                                                    true)
                                                            .pop();
                                                      }

                                                      // 3.2. Ahora navegar a la vista de destino
                                                      Navigator
                                                          .pushReplacementNamed(
                                                        context,
                                                        'scan-product-consolidate',
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
                                                    // Row(
                                                    //   children: [
                                                    //     Text(
                                                    //       "Pedido: ",
                                                    //       style: TextStyle(
                                                    //         fontSize: 12,
                                                    //         color:
                                                    //             primaryColorApp,
                                                    //       ),
                                                    //     ),
                                                    //     Text(
                                                    //         "${product.pedidoId}",
                                                    //         style:
                                                    //             const TextStyle(
                                                    //                 fontSize:
                                                    //                     12,
                                                    //                 color:
                                                    //                     black)),
                                                    //   ],
                                                    // ),
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
