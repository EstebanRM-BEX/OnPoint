import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';

class PrintLabelsProductsScreen extends StatefulWidget {
  const PrintLabelsProductsScreen({super.key});

  @override
  State<PrintLabelsProductsScreen> createState() =>
      _PrintLabelsProductsScreenState();
}

class _PrintLabelsProductsScreenState extends State<PrintLabelsProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocConsumer<PrintLabelsBloc, PrintLabelsState>(
      listener: (context, state) {},
      builder: (context, state) {
        final bloc = context.read<PrintLabelsBloc>();

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: white,
                child: Column(
                  children: [
                    _AppBarInfo(size: size),
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
                      child: bloc.productosFilters.isEmpty
                          ? const _NoProductsMessage()
                          : ListView.builder(
                              itemCount: bloc.productosFilters.length,
                              itemBuilder: (_, index) {
                                final product = bloc.productosFilters[index];
                                final alreadyAdded = bloc.productosSelected.any(
                                    (p) => p.productId == product.productId);
                                return ProductListTile(
                                  index: index,
                                  isAdded: alreadyAdded,
                                  onAddRemove: () {
                                    if (alreadyAdded) {
                                      bloc.add(RemoveSelectedProductEvent(
                                          product.productId!));
                                    } else {
                                      bloc.add(
                                          AddSelectedProductEvent(product));
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                    if (bloc.productosSelected.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            ModalPrintersList.show(context,
                                resIds: bloc.productosSelected
                                    .map((e) => e.productId!)
                                    .toList(),
                                companyId: 1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(size.width * 0.9, 40),
                          ),
                          child: const Text("Imprimir Etiqueta",
                              style: TextStyle(color: white)),
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
    required this.index,
    required this.isAdded,
    required this.onAddRemove,
  });

  final int index;
  final bool isAdded;
  final VoidCallback onAddRemove;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PrintLabelsBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onAddRemove,
        child: Card(
          elevation: 3,
          color: isAdded ? Colors.green[100] : white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductRow(
                          'Nombre', bloc.productosFilters[index].name,
                          isError: false),
                      _buildProductRow(
                          'Barcode', bloc.productosFilters[index].barcode,
                          isError: bloc.productosFilters[index].barcode ==
                                  null ||
                              bloc.productosFilters[index].barcode!.isEmpty),
                      _buildProductRow(
                          'Code', bloc.productosFilters[index].code,
                          isError: bloc.productosFilters[index].code == null ||
                              bloc.productosFilters[index].code!.isEmpty),
                    ],
                  ),
                ),
                Icon(
                  isAdded ? Icons.check_circle : Icons.add_circle_outline,
                  color: isAdded ? Colors.green : primaryColorApp,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(String label, String? value, {bool isError = false}) {
    final displayValue =
        (value == null || value.isEmpty) ? 'Sin ${label.toLowerCase()}' : value;
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
  const _AppBarInfo({super.key, required this.size});

  final Size size;

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
                        .read<PrintLabelsBloc>()
                        .searchControllerProducts
                        .clear();
                    Navigator.pushReplacementNamed(context, 'print-labels');
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(left: size.width * 0.22),
                  child: const Text('PRODUCTOS',
                      style: TextStyle(color: white, fontSize: 18)),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoProductsMessage extends StatelessWidget {
  const _NoProductsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('No hay productos', style: TextStyle(fontSize: 14, color: grey)),
        Text('No tiene productos en la base de datos',
            style: TextStyle(fontSize: 12, color: grey)),
        SizedBox(height: 60),
      ],
    );
  }
}
