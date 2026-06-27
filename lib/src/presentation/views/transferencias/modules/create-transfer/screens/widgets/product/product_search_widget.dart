import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';

class SearchProductCreateTransferScreen extends StatefulWidget {
  const SearchProductCreateTransferScreen({super.key});

  @override
  State<SearchProductCreateTransferScreen> createState() =>
      _SearchProductScreenState();
}

class _SearchProductScreenState
    extends State<SearchProductCreateTransferScreen> {
  String? selectedProductKey;
  String? _selectedPropietario;

  List<String> _getPropietarios(CreateTransferBloc bloc) {
    return bloc.productos
        .where((p) =>
            p.manejoPropietario == 1 &&
            p.propietario != null &&
            p.propietario != false &&
            p.propietario.toString().isNotEmpty)
        .map((p) => p.propietario.toString())
        .toSet()
        .toList()
      ..sort();
  }

  void _showPropietarioFilter(BuildContext context, CreateTransferBloc bloc) {
    final propietarios = _getPropietarios(bloc);

    if (propietarios.isEmpty) {
      Get.snackbar(
        'Sin propietarios',
        'No hay productos con propietario para filtrar',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: const Icon(Icons.info_outline, color: primaryColorApp),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: primaryColorApp),
                    SizedBox(width: 8),
                    Text(
                      'Filtrar por propietario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColorApp,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  _selectedPropietario == null
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: primaryColorApp,
                ),
                title: const Text('Todos los propietarios'),
                onTap: () {
                  setState(() => _selectedPropietario = null);
                  Navigator.pop(context);
                },
              ),
              ...propietarios.map((p) => ListTile(
                    leading: Icon(
                      _selectedPropietario == p
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: primaryColorApp,
                    ),
                    title: Text(p),
                    onTap: () {
                      setState(() => _selectedPropietario = p);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<CreateTransferBloc, CreateTransferState>(
      builder: (context, state) {
        final bloc = context.read<CreateTransferBloc>();

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: white,
                child: Column(
                  children: [
                    _AppBarInfo(
                      size: size,
                      hasActiveFilter: _selectedPropietario != null,
                      onFilterTap: () =>
                          _showPropietarioFilter(context, bloc),
                    ),
                    _buildSearchBar(context, bloc, size),
                    Expanded(child: _buildProductList(context, bloc)),
                    const SizedBox(height: 20),
                    _buildSelectButton(bloc, size),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
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
    var productos = bloc.productosFilters;

    if (_selectedPropietario != null) {
      productos = productos
          .where((p) => p.propietario == _selectedPropietario)
          .toList();
    }

    final ubicacionId = bloc.currentUbication?.id;

    final enUbicacionActual =
        productos.where((p) => p.locationId == ubicacionId).toList();

    final enUbicacionCero = productos.where((p) => p.locationId == 0).toList();

    final restantes = productos
        .where((p) => p.locationId != ubicacionId && p.locationId != 0)
        .toList();

    final List<Widget> items = [];

    for (final product in enUbicacionActual) {
      items.add(_buildProductCard(
        context,
        bloc,
        product,
        product.productId,
        product.lotId,
      ));
    }

    for (final product in enUbicacionCero) {
      items.add(_buildProductCard(
        context,
        bloc,
        product,
        product.productId,
        product.lotId,
      ));
    }

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
          debugPrint("Selected product: ${product.toMap()}");
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
                Visibility(
                  visible: product.manejoPropietario == 1,
                  child: _buildInfoRow("Propietario:", product.propietario,
                      emptyText: 'Sin propietario'),
                ),
                _buildInfoRow("UND:", product.uom, emptyText: 'Sin unidad'),
                _buildInfoRow("Ubicación:", product.locationName,
                    emptyText: 'Sin ubicación'),
                _buildInfoRow("Lote:", product.lotName, emptyText: 'Sin lote'),
                Visibility(
                  visible: product.manejaSegundaUnidad == 1,
                  child: _buildInfoRow("2nd Unidad:", product.uomSegundaUnidad, emptyText: 'Sin undiad')),
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
            isEmpty ? emptyText : value,
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
  const _AppBarInfo({
    required this.size,
    required this.onFilterTap,
    required this.hasActiveFilter,
  });

  final Size size;
  final VoidCallback onFilterTap;
  final bool hasActiveFilter;

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
                  Row(
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
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_search_outlined,
                                color: white),
                            tooltip: 'Filtrar por propietario',
                            onPressed: onFilterTap,
                          ),
                          if (hasActiveFilter)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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
