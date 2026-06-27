// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/widgets/dialog_dispositivo_no_autorizado_widget.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ListProductsScreen extends StatefulWidget {
  const ListProductsScreen({super.key});

  @override
  State<ListProductsScreen> createState() => _ListProductsScreenState();
}

class _ListProductsScreenState extends State<ListProductsScreen> {
  int? selectedIndex;
  String? _selectedPropietario;

  List<String> _getPropietarios(InfoRapidaBloc bloc) {
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

  void _showPropietarioFilter(BuildContext context, InfoRapidaBloc bloc) {
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
                  setState(() {
                    _selectedPropietario = null;
                    selectedIndex = null;
                  });
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
                      setState(() {
                        _selectedPropietario = p;
                        selectedIndex = null;
                      });
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

    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        debugPrint("state es $state");

        if (state is DeviceNotAuthorized) {
          Navigator.pop(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DialogUnauthorizedDevice(),
          );
        } else if (state is NeedUpdateVersionState) {
          Get.snackbar(
            '360 Software Informa',
            'Hay una nueva versión disponible. Actualiza desde la configuración de la app, pulsando el nombre de usuario en el Home',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.amber),
            showProgressIndicator: true,
            duration: Duration(seconds: 5),
          );
        } else if (state is InfoRapidaError) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'No se encontró producto, lote, paquete ni ubicación con ese código de barras',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        } else if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            builder: (_) =>
                const DialogLoading(message: "Buscando informacion..."),
          );
        } else if (state is InfoRapidaLoaded) {
          Navigator.pop(context); // Cierra el loader

          // ✅ CORRECCIÓN 1: Evitar Crash si el resultado es nulo
          if (state.infoRapidaResult == null) {
            Get.snackbar(
              'Aviso',
              'La búsqueda no arrojó datos válidos.',
              backgroundColor: white,
              colorText: Colors.orange,
              icon: const Icon(Icons.warning, color: Colors.orange),
            );
            return;
          }

          Get.snackbar(
            '360 Software Informa',
            'Información encontrada',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );

          // ✅ CORRECCIÓN 2: Bloque Try-Catch para "Bad state: No element"
          // Si infoRapidaResult intenta acceder a lista.first y está vacía, capturamos el error.
          try {
            final route = state.infoRapidaResult.type == 'product'
                ? 'product-info'
                : 'location-info';

            Navigator.pushReplacementNamed(
              context,
              route,
              arguments: route == 'location-info'
                  ? [state.infoRapidaResult]
                  : null,
            );
          } catch (e) {
            debugPrint("Error al procesar resultado: $e");
            Get.snackbar(
              'Error',
              'Error al procesar los datos encontrados.',
              backgroundColor: white,
              colorText: Colors.red,
              icon: const Icon(Icons.error, color: Colors.red),
            );
          }
        }
      },
      builder: (context, state) {
        final bloc = context.read<InfoRapidaBloc>();

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
                    //*barra de buscar
                    DynamicSearchBar(
                      controller: bloc.searchControllerProducts,
                      hintText: "Buscar producto",
                      onSearchChanged: (value) {
                        bloc.add(SearchProductEvent(value));
                      },
                      onSearchCleared: () {
                        bloc.searchControllerProducts.clear();
                        bloc.add(SearchProductEvent(''));

                        Future.microtask(() {
                          if (mounted) {
                            FocusScope.of(context).unfocus();
                          }
                        });
                      },
                      onTap: () {},
                    ),
                    Expanded(
                      child: Builder(builder: (context) {
                        final filtered = _selectedPropietario == null
                            ? bloc.productosFilters
                            : bloc.productosFilters
                                .where((p) =>
                                    p.propietario == _selectedPropietario)
                                .toList();

                        if (filtered.isEmpty) return const _NoProductsMessage();

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, index) {
                            return ProductListTile(
                              product: filtered[index],
                              isSelected: selectedIndex == index,
                              onSelect: () =>
                                  setState(() => selectedIndex = index),
                            );
                          },
                        );
                      }),
                    ),

                    if (selectedIndex != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            final filtered = _selectedPropietario == null
                                ? bloc.productosFilters
                                : bloc.productosFilters
                                    .where((p) =>
                                        p.propietario == _selectedPropietario)
                                    .toList();
                            final selectedProduct = filtered[selectedIndex!];

                            debugPrint(
                              'product seleccionado: ${selectedProduct.toMap()}',
                            );

                            FocusScope.of(context).unfocus();
                            bloc.add(
                              GetInfoRapida(
                                selectedProduct.productId.toString(),
                                true,
                                true,
                                false,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(size.width * 0.9, 40),
                          ),
                          child: const Text(
                            "Seleccionar",
                            style: TextStyle(color: white),
                          ),
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
  }
}

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onSelect,
  });

  final Product product;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final barcode = product.barcode?.toString() ?? '';
    final code = product.code?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onSelect,
        child: Card(
          elevation: 3,
          color: isSelected ? Colors.green[100] : white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductRow('Nombre', product.name, isError: false),
                if (product.manejoPropietario == 1)
                  _buildProductRow(
                    'Propietario',
                    product.propietario?.toString(),
                    isError: false,
                  ),
                _buildProductRow(
                  'Barcode',
                  barcode,
                  isError: barcode.isEmpty,
                ),
                _buildProductRow(
                  'Code',
                  code,
                  isError: code.isEmpty,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(String label, String? value, {bool isError = false}) {
    final displayValue = (value == null || value.isEmpty)
        ? 'Sin ${label.toLowerCase()}'
        : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: black, fontSize: 12)),
          Expanded(
            child: Text(
              displayValue,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isError ? red : primaryColorApp,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: primaryColorApp,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      width: double.infinity,
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
        builder: (context, status) => Column(
          children: [
            const WarningWidgetCubit(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: white),
                  onPressed: () {
                    context
                        .read<InfoRapidaBloc>()
                        .searchControllerProducts
                        .clear();
                    Navigator.pushReplacementNamed(context, 'info-rapida');
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
        ),
      ),
    );
  }
}

class _NoProductsMessage extends StatelessWidget {
  const _NoProductsMessage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('No hay productos', style: TextStyle(fontSize: 14, color: grey)),
        Text(
          'No tiene productos en la base de datos',
          style: TextStyle(fontSize: 12, color: grey),
        ),
        SizedBox(height: 60),
      ],
    );
  }
}
