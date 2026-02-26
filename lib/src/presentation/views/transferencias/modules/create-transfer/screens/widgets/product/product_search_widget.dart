import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class SearchProductCreateTransferScreen extends StatefulWidget {
  const SearchProductCreateTransferScreen({super.key});

  @override
  State<SearchProductCreateTransferScreen> createState() =>
      _SearchProductScreenState();
}

class _SearchProductScreenState
    extends State<SearchProductCreateTransferScreen> {
  String? selectedProductKey;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<CreateTransferBloc, CreateTransferState>(
      builder: (context, state) {
        final bloc = context.read<CreateTransferBloc>();

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: white,
            body: Column(
              children: [
                _AppBarInfo(size: size),
                _buildSearchBar(context, bloc, size),
                Expanded(child: _buildProductList(context, bloc)),
                const SizedBox(height: 20),
                _buildSelectButton(bloc, size),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(
      BuildContext context, CreateTransferBloc bloc, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 55,
        width: size.width,
        child: Card(
          color: Colors.white,
          elevation: 3,
          child: TextFormField(
            showCursor: true,
            textAlignVertical: TextAlignVertical.center,
            controller: bloc.searchControllerProducts,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: grey, size: 20),
              suffixIcon: IconButton(
                onPressed: () {
                  bloc.searchControllerProducts.clear();
                  bloc.add(SearchProductEvent(''));
                  FocusScope.of(context).unfocus();
                },
                icon: const Icon(Icons.close, color: grey, size: 20),
              ),
              hintText: "Buscar producto",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              bloc.add(SearchProductEvent(value));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, CreateTransferBloc bloc) {
    final productos = bloc.productosFilters;
    final ubicacionId = bloc.currentUbication?.id;

    final enUbicacionActual =
        productos.where((p) => p.locationId == ubicacionId).toList();

    final enUbicacionCero = productos.where((p) => p.locationId == 0).toList();

    final restantes = productos
        .where((p) => p.locationId != ubicacionId && p.locationId != 0)
        .toList();

    final List<Widget> items = [];

    // 🟢 Primero: productos en ubicación actual
    for (final product in enUbicacionActual) {
      items.add(_buildProductCard(
        context,
        bloc,
        product,
        product.productId,
        product.lotId,
      ));
    }

    // 🔵 Luego: productos en locationId == 0
    for (final product in enUbicacionCero) {
      items.add(_buildProductCard(
        context,
        bloc,
        product,
        product.productId,
        product.lotId,
      ));
    }

    // ⚪ Por último: productos restantes
    for (final product in restantes) {
      items.add(_buildProductCard(
        context,
        bloc,
        product,
        product.productId,
        product.lotId,
      ));
    }

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No se encontraron productos',
                style: TextStyle(fontSize: 14, color: grey)),
            Text('Prueba con otro término de búsqueda',
                style: TextStyle(fontSize: 12, color: grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildProductCard(BuildContext context, CreateTransferBloc bloc,
      dynamic product, dynamic productId, dynamic lotId) {
    final currentKey = '${productId}_$lotId';
    final isSelected = selectedProductKey == currentKey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: GestureDetector(
        onTap: () {
          print("Selected product: ${product.toMap()}");
          setState(() => selectedProductKey = isSelected ? null : currentKey);
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
                _buildInfoRow("Barcode:", product.barcode,
                    emptyText: 'Sin barcode'),
                _buildInfoRow("Code:", product.code,
                    emptyText: 'Sin código de producto'),
                _buildInfoRow("UND:", product.uom, emptyText: 'Sin unidad'),
                // _buildInfoRow("Ubicación:", product.locationName,
                //     emptyText: 'Sin ubicación'),
                _buildInfoRow("Lote:", product.lotName, emptyText: 'Sin lote'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value,
      {String emptyText = '', bool highlight = false}) {
    final isEmpty = value == null || value.isEmpty || value == false;
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: black)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            isEmpty ? emptyText : value!,
            style: TextStyle(
              fontSize: 12,
              color: isEmpty ? red : (highlight ? primaryColorApp : black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectButton(CreateTransferBloc bloc, Size size) {
    return Visibility(
      visible: selectedProductKey != null,
      child: ElevatedButton(
        onPressed: () {
          if (selectedProductKey == null) return;

          final parts = selectedProductKey!.split('_');
          final selectedProductId = int.parse(parts[0]);
          final selectedLotId = int.parse(parts[1]);

          final selectedProduct = bloc.productosFilters.firstWhere(
            (p) => p.productId == selectedProductId && p.lotId == selectedLotId,
          );

          FocusScope.of(context).unfocus();

          bloc.add(ValidateFieldsEvent(field: "product", isOk: true));
          bloc.add(ChangeProductIsOkEvent(selectedProduct, true));

          setState(() => selectedProductKey = null);

          Navigator.pushReplacementNamed(
            context,
            'create-transfer',
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: Size(size.width * 0.9, 40),
        ),
        child: const Text("Seleccionar", style: TextStyle(color: white)),
      ),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo({super.key, required this.size});
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
          child: BlocBuilder<CreateTransferBloc, CreateTransferState>(
            builder: (context, state) {
              return Column(
                children: [
                  const WarningWidgetCubit(),
                  Padding(
                    padding: EdgeInsets.only(
                      top: connectionStatus != ConnectionStatus.online ? 0 : 25,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: white),
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              'create-transfer',
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
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
