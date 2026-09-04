import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously, prefer_is_empty

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class Tab2ScreenRecep extends StatefulWidget {
  const Tab2ScreenRecep({super.key, required this.ordenCompra});

  final ResultEntrada? ordenCompra;

  @override
  State<Tab2ScreenRecep> createState() => _Tab2ScreenRecepState();
}

class _Tab2ScreenRecepState extends State<Tab2ScreenRecep> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  FocusNode focusNodeBuscar = FocusNode(); //cantidad textformfield

  final TextEditingController _controllerToDo = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearchVisible = false;
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No robar foco si hay un diálogo o pantalla encima de este tab, ni
    // mientras el buscador manual está visible (mismo guard que
    // recepcion_multiusuario_detail_tab_por_hacer.dart).
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    if (_isSearchVisible) return;
    FocusScope.of(context).requestFocus(focusNodeBuscar);
  }

  @override
  void dispose() {
    focusNodeBuscar.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);
    if (!_isSearchVisible) {
      _searchController.clear();
      setState(() => _searchQuery = '');
      Future.microtask(() => focusNodeBuscar.requestFocus());
    }
  }

  List<LineasTransferencia> _filteredProducts(RecepcionBloc bloc) {
    final base = bloc.listProductsEntrada.where(
      (p) =>
          (p.isSeparate == 0 || p.isSeparate == null) &&
          (p.isDoneItem == 0 || p.isDoneItem == null),
    );
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return base.toList();
    return base.where((p) {
      final name = p.productName?.toLowerCase() ?? '';
      final code = p.productCode?.toLowerCase() ?? '';
      final barcode = p.productBarcode?.toLowerCase() ?? '';
      return name.contains(query) ||
          code.contains(query) ||
          barcode.contains(query);
    }).toList();
  }

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<RecepcionBloc>();

    // Normalizar el valor escaneado
    final scan = value.trim().toLowerCase();

    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode: $scan');

    // Filtrar productos válidos
    final listOfProducts = bloc.listProductsEntrada
        .where(
          (p) =>
              (p.isSeparate == 0 || p.isSeparate == null) &&
              (p.isDoneItem == 0 || p.isDoneItem == null),
        )
        .toList();

    /// Función auxiliar para procesar un producto encontrado
    void processProduct(LineasTransferencia product) {
      // Disparar eventos del BLoC (sin cambios)
      bloc
        ..add(ValidateFieldsOrderEvent(field: "product", isOk: true))
        ..add(
          ChangeQuantitySeparate(
            0,
            int.parse(product.productId),
            product.idRecepcion ?? 0,
            product.idMove ?? 0,
          ),
        )
        ..add(
          ChangeProductIsOkEvent(
            product.idRecepcion ?? 0,
            true,
            int.parse(product.productId),
            0,
            product.idMove ?? 0,
          ),
        )
        ..add(FetchPorductOrder(product));

      // Navegamos directo: la pantalla de scan se reconstruye via BlocBuilder
      // cuando FetchPorductOrder termina de cargar el producto.
      Navigator.pushReplacementNamed(
        context,
        'scan-product-order',
        arguments: [widget.ordenCompra, product],
      );

      debugPrint('✅ Producto procesado: ${product.toMap()}');
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
    Future.microtask(() => focusNodeBuscar.requestFocus());

    // 3️⃣ Si no se encuentra nada → mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código no encontrado en la lista')),
    );
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        if (_isSearchVisible)
                          Expanded(
                            child: DynamicSearchBar(
                              controller: _searchController,
                              hintText: 'Buscar producto',
                              persistentKeyboard: true,
                              onSearchChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              onSearchCleared: () =>
                                  setState(() => _searchQuery = ''),
                            ),
                          )
                        else
                          const Spacer(),
                        IconButton(
                          icon: Icon(
                            _isSearchVisible ? Icons.close : Icons.search,
                            color: primaryColorApp,
                          ),
                          onPressed: _toggleSearch,
                        ),
                      ],
                    ),
                  ),
                  //*espacio para escanear y buscar el producto
                  BarcodeScannerField(
                    controller: _controllerToDo,
                    focusNode: focusNodeBuscar,
                    onBarcodeScanned: (value, context) {
                      return validateBarcode(value, context);
                    },
                  ),

                  (_filteredProducts(recepcionBloc).isEmpty)
                      ? Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Text(
                                'No hay productos',
                                style: TextStyle(fontSize: 14, color: grey),
                              ),
                              const Text(
                                'Intente buscar otro producto',
                                style: TextStyle(fontSize: 12, color: grey),
                              ),
                              Visibility(
                                visible: context
                                    .read<UserBloc>()
                                    .fabricante
                                    .contains("Zebra"),
                                child: Container(height: 60),
                              ),
                            ],
                          ),
                        )
                      :
                        // :
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final filtered = _filteredProducts(
                                recepcionBloc,
                              );
                              return ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final product = filtered[index];

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
                                      onTap: () {
                                        context.read<RecepcionBloc>().add(
                                          FetchPorductOrder(product),
                                        );

                                        // Navegamos directo: la pantalla de scan
                                        // se reconstruye via BlocBuilder cuando
                                        // FetchPorductOrder termina de cargar.
                                        Navigator.pushReplacementNamed(
                                          context,
                                          'scan-product-order',
                                          arguments: [
                                            widget.ordenCompra,
                                            product,
                                          ],
                                        );
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
                                                fontSize: 12,
                                                color: black,
                                              ),
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
                                              Text(
                                                "${product.productCode}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: black,
                                                ),
                                              ),
                                              const Spacer(),
                                              //ponemos icono de imprimir
                                              GestureDetector(
                                                onTap: () {
                                                  ModalPrintersList.show(
                                                    context,
                                                    resIds: [product.idMove],
                                                    companyId:
                                                        widget
                                                            .ordenCompra
                                                            ?.warehouseId ??
                                                        1,
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.print,
                                                  color: primaryColorApp,
                                                  size: 25,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "Ubicación de origen: ",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text(
                                            "${product.locationName}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: black,
                                            ),
                                          ),
                                          Visibility(
                                            visible:
                                                recepcionBloc
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
                                                    color: black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible:
                                                product.manejaSegundaUnidad ==
                                                    1 ||
                                                product.manejaSegundaUnidad ==
                                                    true,
                                            child: Row(
                                              children: [
                                                Text(
                                                  "2nd Unidad: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                Text(
                                                  "${product.uomSegundaUnidad}",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black,
                                                  ),
                                                ),
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
