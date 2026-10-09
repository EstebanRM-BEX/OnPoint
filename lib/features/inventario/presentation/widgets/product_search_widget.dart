// lib/features/inventario/presentation/widgets/product_search_widget.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class SearchProductScreen extends StatefulWidget {
  const SearchProductScreen({super.key});

  @override
  State<SearchProductScreen> createState() => _SearchProductScreenState();
}

class _SearchProductScreenState extends State<SearchProductScreen> {
  ProductoInventario? _seleccionado;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Primera página (respeta lo que ya estuviera escrito en el buscador).
    final bloc = context.read<InventarioBloc>();
    bloc.add(SearchProductEvent(bloc.searchControllerProducts.text));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _buscar(InventarioBloc bloc, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) bloc.add(SearchProductEvent(value));
    });
  }

  /// Una fila por producto × lote × ubicación (índice único de la tabla).
  static bool _mismaFila(ProductoInventario a, ProductoInventario b) =>
      a.productId == b.productId &&
      a.lotId == b.lotId &&
      a.locationId == b.locationId;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bloc = context.read<InventarioBloc>();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: primaryColorApp,
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _AppBarInfo(size: size),
                DynamicSearchBar(
                  controller: bloc.searchControllerProducts,
                  hintText: "Buscar producto",
                  // watchdog: reabre el teclado si el IME del PDA
                  // (Zebra/Urovo/Chainway) lo cierra solo.
                  persistentKeyboard: true,
                  onSearchChanged: (value) => _buscar(bloc, value),
                  onSearchCleared: () {
                    _debounce?.cancel();
                    final searchBloc = bloc;
                    searchBloc.searchControllerProducts.clear();
                    searchBloc.add(SearchProductEvent(''));
                    Future.microtask(() {
                      if (mounted) {
                        FocusScope.of(context).unfocus();
                      }
                    });
                  },
                ),
                Expanded(
                  // Solo los estados que cambian la lista; el resto de
                  // eventos del bloc no reconstruye la pantalla.
                  child: BlocBuilder<InventarioBloc, InventarioState>(
                    buildWhen: (_, curr) =>
                        curr is SearchProductSuccess || curr is SearchFailure,
                    builder: (context, _) => _buildProductList(bloc),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSelectButton(bloc, size),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(InventarioBloc bloc) {
    // Página(s) traídas de SQLite, ya ordenadas: ubicación actual →
    // ubicación 0 → resto.
    final productos = bloc.productosFilters;

    if (productos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No se encontraron productos',
              style: TextStyle(fontSize: 14, color: grey),
            ),
            Text(
              'Prueba con otro término de búsqueda',
              style: TextStyle(fontSize: 12, color: grey),
            ),
          ],
        ),
      );
    }

    final hayMas = bloc.hayMasProductos;
    return ListView.builder(
      itemCount: productos.length + (hayMas ? 1 : 0),
      itemBuilder: (context, index) {
        // Cerca del final se pide la siguiente página (el bloc descarta los
        // pedidos repetidos mientras una está en curso).
        if (hayMas && index >= productos.length - 10) {
          bloc.add(CargarMasProductosEvent());
        }
        if (index == productos.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildProductCard(bloc, productos[index]);
      },
    );
  }

  Widget _buildProductCard(InventarioBloc bloc, ProductoInventario product) {
    final seleccionado = _seleccionado;
    final isSelected =
        seleccionado != null && _mismaFila(seleccionado, product);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: GestureDetector(
        onTap: () {
          debugPrint("Selected product: ${product.name}");
          setState(() => _seleccionado = isSelected ? null : product);
        },
        child: Card(
          elevation: 3,
          color: isSelected
              ? Colors.green[100]
              : product.locationId == bloc.currentUbication?.id
              ? Colors.grey[300]
              : white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Nombre:", product.name, highlight: true),
                _buildInfoRow(
                  "Barcode:",
                  product.barcode,
                  emptyText: 'Sin barcode',
                ),
                _buildInfoRow(
                  "Code:",
                  product.code,
                  emptyText: 'Sin código de producto',
                ),
                _buildInfoRow("UND:", product.uom, emptyText: 'Sin unidad'),
                _buildInfoRow(
                  "Ubicación:",
                  product.locationName,
                  emptyText: 'Sin ubicación',
                ),
                _buildInfoRow("Lote:", product.lotName, emptyText: 'Sin lote'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    dynamic value, {
    String emptyText = '',
    bool highlight = false,
  }) {
    // Odoo puede mandar false en campos vacíos.
    final texto = value is String ? value : '';
    final isEmpty = texto.isEmpty;
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: black)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            isEmpty ? emptyText : texto,
            style: TextStyle(
              fontSize: 12,
              color: isEmpty ? red : (highlight ? primaryColorApp : black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectButton(InventarioBloc bloc, Size size) {
    return Visibility(
      visible: _seleccionado != null,
      child: ElevatedButton(
        onPressed: () {
          final selectedProduct = _seleccionado;
          if (selectedProduct == null) return;

          FocusScope.of(context).unfocus();

          bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
          bloc.add(ChangeProductIsOkEvent(selectedProduct, isManual: true));

          setState(() => _seleccionado = null);

          Navigator.pushReplacementNamed(
            context,
            'inventario',
            arguments: [context.read<InventarioBloc>()],
          );

          Get.snackbar(
            'Producto Seleccionado',
            'Has seleccionado el producto: ${selectedProduct.name}',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.check, color: Colors.green),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorApp,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: Size(size.width * 0.9, 40),
        ),
        child: const Text("Seleccionar", style: TextStyle(color: white)),
      ),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, connectionStatus) {
        return Container(
          decoration: BoxDecoration(
            color: primaryColorApp,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          width: double.infinity,
          child: Column(
            children: [
              const WarningWidgetCubit(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        'inventario',
                        arguments: [context.read<InventarioBloc>()],
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.22),
                    child: const Text(
                      'PRODUCTOS',
                      style: TextStyle(color: white, fontSize: 18),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
